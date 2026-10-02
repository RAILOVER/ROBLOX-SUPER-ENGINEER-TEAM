--!strict
-- Un duel en cours cote serveur : fait avancer DuelState (pur) avec task.wait, fait jouer DuelBot, et pousse les
-- payloads aux sieges via les callbacks fournis par DuelService. Aucune regle de jeu ici (tout est dans
-- src/shared/Duel/, teste sous Lune) ; ce fichier n'est pas testable sous Lune (task.wait).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DuelState = require(ReplicatedStorage.Shared.Duel.DuelState)
local Types = require(ReplicatedStorage.Shared.Types.Duel)
local DuelBot = require(script.Parent.DuelBot)

type Config = typeof(require(ReplicatedStorage.Shared.Config))
type State = Types.State
type ActionResult = Types.ActionResult

export type SeatDef = { kind: Types.SeatKind, userId: number, displayName: string }
export type Callbacks = {
	send: (seatIndex: number, remoteName: string, payload: any) -> (),
	onEnded: (match: Match) -> (),
}
export type Match = {
	config: Config,
	state: State,
	bots: { [number]: DuelBot.Bot },
	callbacks: Callbacks,
	running: boolean,
	ghostSince: { [number]: number },
	version: number,
}

local DuelMatch = {}

DuelMatch.TICK_SECONDS = 0.25

function DuelMatch.new(
	config: Config,
	seed: number,
	seatDefs: { SeatDef },
	callbacks: Callbacks
): Match
	local bots: { [number]: DuelBot.Bot } = {}
	for index, def in seatDefs do
		if def.kind == "bot" then
			bots[index] = DuelBot.new(seed * 97 + index)
		end
	end
	return {
		config = config,
		state = DuelState.new(config, seed, seatDefs),
		bots = bots,
		callbacks = callbacks,
		running = false,
		ghostSince = {},
		version = 0,
	}
end

function DuelMatch.broadcast(match: Match): ()
	match.version += 1
	for index, seat in match.state.seats do
		if seat.kind == "human" then
			match.callbacks.send(
				index,
				"DuelState",
				DuelState.toClientView(match.config, match.state, index)
			)
		end
	end
end

-- Intention d'un siege humain : DuelState refuse tout ce qui est hors phase ou invalide.
function DuelMatch.handle(
	match: Match,
	seatIndex: number,
	action: string,
	args: { any }
): ActionResult
	local result = DuelState.apply(match.config, match.state, seatIndex, action, args)
	if result.ok then
		DuelMatch.broadcast(match)
	else
		match.state.seats[seatIndex].invalidRequests += 1
	end
	return result
end

-- D-M1-20 : siege abandonne, le fantome rejoue son dernier plateau sans achat.
function DuelMatch.forfeit(match: Match, seatIndex: number): ()
	if match.state.phase == "Fin" then
		return
	end
	DuelState.forfeit(match.state, seatIndex)
	DuelMatch.broadcast(match)
end

local function sendCombatLogs(match: Match): ()
	local state = match.state
	local isPve = DuelState.isPve(match.config, state)
	for _, record in state.combats do
		local payload: Types.CombatLogPayload = {
			round = state.round,
			isPve = isPve,
			side = record.side,
			teams = record.teams,
			result = record.result,
			playerDamage = record.damage,
		}
		match.callbacks.send(record.seatIndex, "CombatLog", payload)
	end
end

local function sendEnded(match: Match): ()
	local state = match.state
	for index, seat in state.seats do
		if seat.kind == "human" then
			local payload: Types.DuelEndedPayload = {
				rounds = state.round,
				winnerSeat = state.winnerSeat,
				youWon = state.winnerSeat == index,
				hp = { state.seats[1].hp, state.seats[2].hp },
				reason = state.endReason or "draw",
			}
			match.callbacks.send(index, "DuelEnded", payload)
		end
	end
end

-- Attend la fin du minuteur de la phase courante ; les bots jouent pendant Preparation.
local function waitPhase(match: Match): ()
	local state = match.state
	local phase = state.phase
	local elapsed = 0
	local lastShown = math.ceil(state.timerSeconds)
	while match.running and state.phase == phase do
		local dt = task.wait(DuelMatch.TICK_SECONDS)
		elapsed += dt
		if phase == "Preparation" then
			for index, bot in match.bots do
				if DuelBot.update(match.config, state, index, bot, elapsed) then
					DuelMatch.broadcast(match)
				end
			end
		end
		if DuelState.tick(state, dt) then
			return
		end
		local shown = math.ceil(state.timerSeconds)
		if shown ~= lastShown then
			lastShown = shown
			DuelMatch.broadcast(match)
		end
	end
end

-- Boucle complete : a lancer dans son propre thread (task.spawn) par DuelService.
function DuelMatch.run(match: Match): ()
	local config, state = match.config, match.state
	match.running = true
	DuelState.beginPreparation(config, state)
	while match.running and state.phase ~= "Fin" do
		if state.phase == "Preparation" then
			for index, seat in state.seats do
				if seat.kind == "ghost" then
					DuelState.apply(config, state, index, "Ready", {})
				end
			end
			DuelMatch.broadcast(match)
			waitPhase(match)
			if state.phase == "Preparation" then
				DuelState.beginCombat(config, state)
				sendCombatLogs(match)
				DuelMatch.broadcast(match)
			end
		elseif state.phase == "Combat" then
			waitPhase(match)
			if state.phase == "Combat" then
				DuelState.beginResult(config, state)
				DuelMatch.broadcast(match)
			end
		elseif state.phase == "Resultat" then
			waitPhase(match)
			if state.phase == "Resultat" then
				DuelState.endResult(config, state)
			end
		end
	end
	match.running = false
	DuelMatch.broadcast(match)
	sendEnded(match)
	match.callbacks.onEnded(match)
end

function DuelMatch.stop(match: Match): ()
	match.running = false
end

return DuelMatch
