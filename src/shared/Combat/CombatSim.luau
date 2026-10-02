--!strict
-- Point d'entree du combat deterministe (T-0010). Module pur : aucun service Roblox, config injectee.
-- `simulate` rejoue le duel complet et retourne l'ActionLog (version 1) que le client anime.
-- Ordre d'un tour : Mega Combo en attente > debut de tour (regen, dots) > controle (Skip) > Charme > tactique
-- (Garde > Duo > Competence > Attaque) > timeline > fin de tour (durees, immunite) > tour d'equipe > fin de combat.

local Types = require(script.Parent.Parent.Types.Combat)
local ActionLog = require(script.Parent.ActionLog)
local Actions = require(script.Parent.Actions)
local Effects = require(script.Parent.Effects)
local Formulas = require(script.Parent.Formulas)
local Setup = require(script.Parent.Setup)
local SkillEffects = require(script.Parent.SkillEffects)
local Status = require(script.Parent.Status)
local Tactics = require(script.Parent.Tactics)
local Targeting = require(script.Parent.Targeting)
local Timeline = require(script.Parent.Timeline)

type ActionKind = Types.ActionKind
type CombatConfig = Types.CombatConfig
type CombatResult = Types.CombatResult
type Options = Types.Options
type PreviewEntry = Types.PreviewEntry
type Side = Types.Side
type State = Types.State
type TeamState = Types.TeamState
type Unit = Types.Unit
type UnitInstance = Types.UnitInstance

local CombatSim = {}

CombatSim.VERSION = ActionLog.VERSION
CombatSim.newState = Setup.newState

local OFFENSIVE = { Attack = true, Skill = true, Duo = true } :: { [string]: boolean }

local function aliveCount(team: TeamState): number
	local count = 0
	for _, unit in team.units do
		if unit.alive then
			count += 1
		end
	end
	return count
end

-- R-M1-58, R-M1-59 : fin de combat a la fin de l'action en cours.
local function checkEnd(state: State)
	local aliveA, aliveB = aliveCount(state.teams.A), aliveCount(state.teams.B)
	if aliveA == 0 or aliveB == 0 then
		state.winner = if aliveA == aliveB then "draw" elseif aliveA == 0 then "B" else "A"
	elseif state.actions >= state.config.Combat.drawAfterActions then
		state.winner = "draw"
	end
end

-- R-M1-55 : fin d'un tour d'equipe quand chaque allie vivant non HorsCombat a agi (Skip compris).
local function registerTeamAction(state: State, team: TeamState, actor: Unit)
	team.roundActed[actor.id] = true
	for _, unit in team.units do
		if Timeline.canAdvance(unit) and not team.roundActed[unit.id] then
			return
		end
	end
	team.rounds += 1
	team.roundActed = {}
	team.focusTurnsLeft = math.max(0, team.focusTurnsLeft - 1)
	Status.onTeamRound(state, team)
end

-- R-M1-21 : Charme => Attaque sur un allie au hasard, Skip si seule.
local function charmedAction(state: State, actor: Unit): ActionKind
	local ally = Targeting.randomAlly(state, actor)
	if ally and Actions.attack(state, actor, ally) then
		return "Attack"
	end
	return "Skip"
end

local function tacticalAction(state: State, actor: Unit): ActionKind
	local decision = Tactics.decide(state, actor)
	if decision.kind == "Guard" then
		Actions.guard(state, actor)
		return "Guard"
	elseif
		decision.kind == "Duo"
		and decision.partner
		and Actions.duo(state, actor, decision.partner)
	then
		return "Duo"
	elseif decision.kind == "Skill" and SkillEffects.run(state, actor) then
		return "Skill"
	end
	return if Actions.attack(state, actor) then "Attack" else "Skip"
end

-- Joue l'action de `actor` (entree deja ouverte). Retourne le type d'action retenu.
local function playTurn(state: State, actor: Unit): ActionKind
	Effects.onTurnStart(state, actor)
	Status.onTurnStart(state, actor, Formulas.suddenDeathMult(state.config, state.actions))
	if not actor.alive then
		return "Skip"
	end
	if Status.skipsTurn(actor) then
		return "Skip"
	end
	if Status.has(actor, "Charme") then
		return charmedAction(state, actor)
	end
	return tacticalAction(state, actor)
end

-- Une action complete (Mega Combo eventuel puis tour de l'unite). Retourne false si le combat est fini.
function CombatSim.step(state: State): boolean
	if state.winner ~= nil then
		return false
	end
	local actor = Timeline.nextActor(state)
	local team = Status.teamOf(state, actor)
	if state.options.autoMega ~= false then
		local combos = Effects.availableCombos(state, team)
		if #combos > 0 then
			Actions.mega(state, team, combos[1])
			checkEnd(state)
			if state.winner ~= nil or not actor.alive then
				return state.winner == nil
			end
		end
	end
	actor.guarding = false
	local entry = Actions.beginEntry(state, actor, "Skip")
	local kind: ActionKind = playTurn(state, actor)
	entry.action = kind
	if actor.alive then
		if kind ~= "Skip" and actor.synergyMember then
			team.mega = math.min(
				state.config.Combat.megaGaugeMax,
				team.mega + state.config.Combat.megaGainPerSynergyAction
			)
		end
		if OFFENSIVE[kind] and Status.has(actor, "Invisible") then
			Status.remove(state, actor, "Invisible")
		end
	end
	Timeline.afterAction(state, actor, kind == "Guard")
	if actor.alive then
		Status.onTurnEnd(state, actor)
	end
	Actions.finishEntry(state, actor)
	registerTeamAction(state, team, actor)
	checkEnd(state)
	return state.winner == nil
end

-- R-M1-09 : les n prochains acteurs, sans effet de bord.
function CombatSim.preview(state: State, n: number): { PreviewEntry }
	return Timeline.preview(state, n)
end

-- R-M1-55 : ordre de focus d'un joueur. Retourne false si l'ordre est ignore (il compte quand meme).
function CombatSim.orderFocus(state: State, side: Side, cell: number): boolean
	local team = state.teams[side]
	team.focusOrdersUsed += 1
	if team.focusOrdersUsed > state.config.Combat.focusOrdersPerCombat then
		return false
	end
	team.focusCell = cell
	team.focusTurnsLeft = state.config.Combat.focusTurns
	team.roundActed = {}
	return true
end

-- R-M1-60 : MVP = degats + soins max (ordre des cases a egalite).
function CombatSim.mvp(state: State): string?
	local best: Unit? = nil
	for _, unit in state.units do
		if
			best == nil
			or unit.damageDealt + unit.healingDone > best.damageDealt + best.healingDone
		then
			best = unit
		end
	end
	return if best then ActionLog.actorOf(best) else nil
end

function CombatSim.result(state: State): CombatResult
	return {
		winner = state.winner or "draw",
		turns = state.ticks,
		actions = state.actions,
		actionLog = state.log,
		version = ActionLog.VERSION,
		mvp = CombatSim.mvp(state),
		unimplemented = state.unimplemented,
	}
end

function CombatSim.simulate(
	seed: number,
	teamA: { UnitInstance },
	teamB: { UnitInstance },
	config: CombatConfig,
	options: Options?
): CombatResult
	local state = Setup.newState(seed, teamA, teamB, config, options)
	checkEnd(state)
	local running = true
	while running do
		running = CombatSim.step(state)
	end
	return CombatSim.result(state)
end

return CombatSim
