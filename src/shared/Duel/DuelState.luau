--!strict
-- Etat complet d'un duel et transitions pures (spec M1-duel-minimal D-M1-03 a D-M1-20).
-- Lobby -> Preparation -> Combat -> Resultat -> Preparation ... -> Fin. Le serveur (DuelService) ne fait que
-- decrementer `timerSeconds` et appeler la transition suivante ; tout est rejouable sous Lune.

local Types = require(script.Parent.Parent.Types.Combat)
local DuelTypes = require(script.Parent.Parent.Types.Duel)
local CombatSim = require(script.Parent.Parent.Combat.CombatSim)
local Decks = require(script.Parent.Decks)
local Economy = require(script.Parent.Economy)
local Seat = require(script.Parent.Seat)

type Config = Types.CombatConfig
type CombatResult = Types.CombatResult
type ActionResult = DuelTypes.ActionResult
type ClientView = DuelTypes.ClientView
type CombatRecord = DuelTypes.CombatRecord
type OwnedUnit = DuelTypes.OwnedUnit
type RoundOutcome = DuelTypes.RoundOutcome
type SeatDef = { kind: DuelTypes.SeatKind, userId: number, displayName: string }
type State = DuelTypes.State
type UnitInstance = DuelTypes.UnitInstance

local DuelState = {}

-- Durees hors Config.Duel (spec §2 budget temps : resultat 4 s + transition 3 s). A deplacer dans Config.Duel par
-- le game designer (ticket ouvert par T-0011).
DuelState.RESULT_SECONDS = 4
DuelState.TRANSITION_SECONDS = 3
DuelState.MIN_COMBAT_SECONDS = 2

function DuelState.new(config: Config, seed: number, seatDefs: { SeatDef }): State
	assert(#seatDefs == 2, "un duel a exactement 2 sieges")
	local seats = {}
	for index, def in seatDefs do
		table.insert(
			seats,
			Seat.new(
				config,
				index,
				def.kind,
				def.userId,
				def.displayName,
				Decks.M1,
				seed * 2 + index
			)
		)
	end
	return {
		seed = seed,
		phase = "Lobby",
		round = 0,
		timerSeconds = 0,
		seats = seats,
		deck = Decks.M1,
		combats = {},
		hpBeforeRound = { config.Duel.playerHp, config.Duel.playerHp },
		winnerSeat = nil,
		endReason = nil,
		combatSeed = seed,
	}
end

function DuelState.isPve(config: Config, state: State): boolean
	return table.find(config.Duel.pveRounds, state.round) ~= nil
end

function DuelState.bothReady(state: State): boolean
	return state.seats[1].ready and state.seats[2].ready
end

-- Lobby ou Resultat -> Preparation (D-M1-05, D-M1-07, D-M1-09).
function DuelState.beginPreparation(config: Config, state: State): ()
	assert(
		state.phase == "Lobby" or state.phase == "Resultat",
		`transition interdite depuis {state.phase}`
	)
	state.round += 1
	state.phase = "Preparation"
	state.combats = {}
	for index, seat in state.seats do
		state.hpBeforeRound[index] = seat.hp
		Seat.beginRound(config, seat, state.round)
	end
	state.timerSeconds = Economy.prepSeconds(config, state.round, false)
end

-- Decremente le minuteur ; retourne true quand la phase courante est terminee.
function DuelState.tick(state: State, dt: number): boolean
	state.timerSeconds -= dt
	if state.timerSeconds <= 1e-6 then
		state.timerSeconds = 0
	end
	return state.timerSeconds <= 0
end

local function survivingStars(
	result: CombatResult,
	team: { UnitInstance },
	side: Types.Side
): number
	local stars = 0
	local lastHp: { [string]: number } = {}
	for _, entry in result.actionLog do
		for cell, hp in entry.hp do
			lastHp[cell] = hp
		end
	end
	for _, unit in team do
		local cell = `{side}{(unit.row - 1) * 4 + (unit.col - 1)}`
		local hp = lastHp[cell]
		if hp == nil or hp > 0 then
			stars += unit.stars or 1
		end
	end
	return stars
end

local function outcomeFor(result: CombatResult, side: Types.Side): RoundOutcome
	if result.winner == "draw" then
		return "draw"
	end
	return if result.winner == side then "win" else "loss"
end

local function pvpRecord(
	config: Config,
	state: State,
	seatIndex: number,
	teams: { A: { UnitInstance }, B: { UnitInstance } },
	result: CombatResult
): CombatRecord
	local side: Types.Side = if seatIndex == 1 then "A" else "B"
	local damage = { 0, 0 }
	if result.winner == "draw" then
		damage[1] = Economy.drawDamage(config, state.round, survivingStars(result, teams.B, "B"))
		damage[2] = Economy.drawDamage(config, state.round, survivingStars(result, teams.A, "A"))
	elseif result.winner == "A" then
		damage[2] = Economy.playerDamage(config, state.round, survivingStars(result, teams.A, "A"))
	else
		damage[1] = Economy.playerDamage(config, state.round, survivingStars(result, teams.B, "B"))
	end
	return {
		seatIndex = seatIndex,
		side = side,
		teams = teams,
		result = result,
		damage = damage,
		outcome = outcomeFor(result, side),
	}
end

-- Preparation -> Combat (D-M1-06, D-M1-12, D-M1-17, D-M1-18). Les degats sont calcules ici, appliques en Resultat.
function DuelState.beginCombat(config: Config, state: State): ()
	assert(state.phase == "Preparation", `transition interdite depuis {state.phase}`)
	state.phase = "Combat"
	state.combatSeed += 1
	local seconds = 0
	local pveTeam = Decks.pveTeam(config.Duel.pveRounds, state.round)
	if pveTeam then
		for index, seat in state.seats do
			local teams = { A = Seat.toTeam(seat), B = pveTeam }
			local result =
				CombatSim.simulate(state.combatSeed * 2 + index, teams.A, teams.B, config)
			table.insert(state.combats, {
				seatIndex = index,
				side = "A" :: Types.Side,
				teams = teams,
				result = result,
				damage = { 0, 0 },
				outcome = outcomeFor(result, "A"),
			})
			seconds = math.max(seconds, result.actions * config.Combat.pvpActionAnimationMaxSeconds)
		end
	else
		local teams = { A = Seat.toTeam(state.seats[1]), B = Seat.toTeam(state.seats[2]) }
		local result = CombatSim.simulate(state.combatSeed, teams.A, teams.B, config)
		table.insert(state.combats, pvpRecord(config, state, 1, teams, result))
		table.insert(state.combats, pvpRecord(config, state, 2, teams, result))
		seconds = result.actions * config.Combat.pvpActionAnimationMaxSeconds
	end
	state.timerSeconds = math.max(DuelState.MIN_COMBAT_SECONDS, seconds)
end

-- Combat -> Resultat : PV, series, recompenses PvE (D-M1-06, D-M1-17 a D-M1-19).
function DuelState.beginResult(config: Config, state: State): ()
	assert(state.phase == "Combat", `transition interdite depuis {state.phase}`)
	state.phase = "Resultat"
	local pve = DuelState.isPve(config, state)
	for _, record in state.combats do
		local seat = state.seats[record.seatIndex]
		seat.hp -= record.damage[record.seatIndex]
		seat.streak = Economy.nextStreak(seat.streak, seat.lastOutcome, record.outcome)
		seat.lastOutcome = record.outcome
		if record.outcome == "win" then
			seat.roundsWon += 1
			if pve then
				seat.gold += config.Duel.pveRewardGold
				Seat.grantFreeCard(config, seat, state.deck[seat.rng:NextInteger(1, #state.deck)])
			end
		end
	end
	state.timerSeconds = DuelState.RESULT_SECONDS + DuelState.TRANSITION_SECONDS
end

-- D-M1-19 : fin si un siege est a 0 PV ; les 2 a 0 => le plus de PV avant la manche gagne, egalite => nul.
function DuelState.checkEnd(state: State): boolean
	local dead = {}
	for index, seat in state.seats do
		if seat.hp <= 0 then
			table.insert(dead, index)
		end
	end
	if #dead == 0 then
		return false
	end
	state.phase = "Fin"
	state.timerSeconds = 0
	if #dead == 1 then
		state.winnerSeat = 3 - dead[1]
		state.endReason = "hp"
	elseif state.hpBeforeRound[1] ~= state.hpBeforeRound[2] then
		state.winnerSeat = if state.hpBeforeRound[1] > state.hpBeforeRound[2] then 1 else 2
		state.endReason = "hp"
	else
		state.winnerSeat = nil
		state.endReason = "draw"
	end
	return true
end

-- Resultat -> Fin ou Preparation.
function DuelState.endResult(config: Config, state: State): ()
	assert(state.phase == "Resultat", `transition interdite depuis {state.phase}`)
	if not DuelState.checkEnd(state) then
		DuelState.beginPreparation(config, state)
	end
end

-- D-M1-20 : abandon = defaite ; le siege devient un fantome qui rejoue son dernier plateau.
function DuelState.forfeit(state: State, seatIndex: number): ()
	local seat = state.seats[seatIndex]
	seat.kind = "ghost"
	seat.ready = true
	if state.phase == "Lobby" or state.phase == "Preparation" and state.round <= 1 then
		seat.hp = 0
		state.phase = "Fin"
		state.winnerSeat = 3 - seatIndex
		state.endReason = "forfeit"
		state.timerSeconds = 0
	end
end

-- Intention d'un siege (client ou bot). Toute intention hors phase est refusee : le serveur compte le refus.
function DuelState.apply(
	config: Config,
	state: State,
	seatIndex: number,
	action: string,
	args: { any }
): ActionResult
	local seat = state.seats[seatIndex]
	if seat == nil then
		return { ok = false, reason = "no_seat" }
	end
	if action == "OrderFocus" then
		-- M1 : le combat est simule d'un bloc (D-M1-12) ; l'ordre est accepte et ignore, le mode pas a pas est M2.
		return if state.phase == "Combat"
			then { ok = true }
			else { ok = false, reason = "wrong_phase" }
	end
	if state.phase ~= "Preparation" then
		return { ok = false, reason = "wrong_phase" }
	end
	if action == "BuyShopSlot" then
		return Seat.buy(config, seat, args[1])
	elseif action == "Reroll" then
		return Seat.reroll(config, seat)
	elseif action == "BuyXp" then
		return Seat.buyXp(config, seat)
	elseif action == "PlaceUnit" then
		return Seat.place(config, seat, args[1], args[2], args[3])
	elseif action == "BenchUnit" then
		return Seat.bench(config, seat, args[1])
	elseif action == "SellUnit" then
		return Seat.sell(config, seat, args[1])
	elseif action == "SetTactic" then
		return Seat.setTactic(seat, args[1], args[2])
	elseif action == "Ready" then
		seat.ready = true
		if DuelState.bothReady(state) then
			state.timerSeconds =
				math.min(state.timerSeconds, Economy.prepSeconds(config, state.round, true))
		end
		return { ok = true }
	end
	return { ok = false, reason = "unknown_action" }
end

local function cloneUnits(units: { OwnedUnit }): { OwnedUnit }
	local copy = {}
	for _, unit in units do
		table.insert(copy, table.clone(unit))
	end
	return copy
end

-- Vue d'un siege : jamais la boutique, le banc, l'or ni le pool de l'adversaire ; son plateau seulement a partir de
-- Combat (D-M1-11).
function DuelState.toClientView(config: Config, state: State, seatIndex: number): ClientView
	local me = state.seats[seatIndex]
	local other = state.seats[3 - seatIndex]
	local boardVisible = state.phase == "Combat"
		or state.phase == "Resultat"
		or state.phase == "Fin"
	return {
		phase = state.phase,
		round = state.round,
		isPve = DuelState.isPve(config, state),
		timerSeconds = state.timerSeconds,
		seatIndex = seatIndex,
		me = {
			seatIndex = me.seatIndex,
			kind = me.kind,
			displayName = me.displayName,
			hp = me.hp,
			level = me.level,
			streak = me.streak,
			ready = me.ready,
			boardCount = #me.board,
			gold = me.gold,
			xp = me.xp,
			xpToNext = Economy.xpToNext(config, me.level),
			nextIncome = Economy.income(config, me.gold, me.streak, me.lastOutcome == "win").total,
			bench = cloneUnits(me.bench),
			board = cloneUnits(me.board),
			shop = cloneUnits(me.shop :: any) :: any,
		},
		opponent = {
			seatIndex = other.seatIndex,
			kind = other.kind,
			displayName = other.displayName,
			hp = other.hp,
			level = other.level,
			streak = other.streak,
			ready = other.ready,
			boardCount = #other.board,
			board = if boardVisible then cloneUnits(other.board) else {},
		},
		lastOutcome = me.lastOutcome,
	}
end

return table.freeze(DuelState)
