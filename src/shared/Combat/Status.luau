--!strict
-- Les 13 statuts de Config.Combat.statuses (R-M1-35 a R-M1-49), le K.O. (R-M1-03) et les compteurs de tour.
-- Les durees se decrementent a la fin du tour du porteur, sauf HorsCombat (tours d'equipe, R-M1-38).

local Types = require(script.Parent.Parent.Types.Combat)
local ActionLog = require(script.Parent.ActionLog)

type State = Types.State
type Unit = Types.Unit
type TeamState = Types.TeamState
type StatusDef = Types.StatusDef
type StatusInstance = Types.StatusInstance
type CombatConfig = Types.CombatConfig

local Status = {}

Status.CONTROL =
	{ Etourdi = true, Endormi = true, Charme = true, HorsCombat = true } :: { [string]: boolean }
Status.SKIP_CONTROL = { Etourdi = true, Endormi = true, HorsCombat = true } :: { [string]: boolean }

export type ApplyOptions = { turns: number?, shield: number?, thornsPct: number? }

function Status.defs(config: CombatConfig): { [string]: StatusDef }
	return (config.Combat.statuses :: any) :: { [string]: StatusDef }
end

function Status.get(unit: Unit, name: string): StatusInstance?
	for _, status in unit.statuses do
		if status.name == name then
			return status
		end
	end
	return nil
end

function Status.has(unit: Unit, name: string): boolean
	return Status.get(unit, name) ~= nil
end

local function logStatus(state: State, unit: Unit, name: string, removed: boolean)
	local entry = state.currentEntry
	if entry then
		local list = if removed then entry.statuses.removed else entry.statuses.applied
		table.insert(list, `{name}@{ActionLog.caseOf(unit)}`)
	end
end

function Status.teamOf(state: State, unit: Unit): TeamState
	return state.teams[unit.side]
end

function Status.enemyTeamOf(state: State, unit: Unit): TeamState
	return if unit.side == "A" then state.teams.B else state.teams.A
end

-- Retire un statut ; la chute d'un statut control donne l'immunite R-M1-48.
function Status.remove(state: State, unit: Unit, name: string): boolean
	for index, status in unit.statuses do
		if status.name == name then
			table.remove(unit.statuses, index)
			logStatus(state, unit, name, true)
			if Status.CONTROL[name] then
				unit.controlImmunity = state.config.Combat.controlImmunityTurnsAfterControl
			end
			return true
		end
	end
	return false
end

-- Pose (ou repose) un statut. Retourne false si le statut est refuse (immunite, boss, cible K.O.).
function Status.apply(state: State, unit: Unit, name: string, options: ApplyOptions?): boolean
	local def = Status.defs(state.config)[name]
	assert(def ~= nil, `statut inconnu : {name}`)
	local opts: ApplyOptions = options or {}
	if not unit.alive then
		return false
	end
	if Status.CONTROL[name] then
		if unit.controlImmunity > 0 then
			return false
		end
		if unit.isBoss then
			if def.bossImmune then
				return false
			end
			if state.rng:NextNumber() < state.config.Combat.bossControlResistance then
				return false
			end
		end
	end
	if name == "Provocation" then
		for _, ally in Status.teamOf(state, unit).units do
			if ally ~= unit and Status.has(ally, "Provocation") then
				Status.remove(state, ally, "Provocation")
			end
		end
	end
	local turns = opts.turns or def.turns
	local existing = Status.get(unit, name)
	if existing then
		if def.maxStacks then
			existing.stacks = math.min(existing.stacks + 1, def.maxStacks)
		end
		existing.shield = math.max(existing.shield, opts.shield or 0)
		existing.thornsPct = math.max(existing.thornsPct, opts.thornsPct or 0)
		existing.turns = turns
		existing.appliedAt = state.actions
	else
		table.insert(unit.statuses, {
			name = name,
			kind = def.kind,
			turns = turns,
			stacks = 1,
			shield = opts.shield or 0,
			thornsPct = opts.thornsPct or 0,
			appliedAt = state.actions,
		})
	end
	logStatus(state, unit, name, false)
	return true
end

-- R-M1-08 : Etourdi, Endormi ou HorsCombat => l'action est Skip.
function Status.skipsTurn(unit: Unit): boolean
	for _, status in unit.statuses do
		if Status.SKIP_CONTROL[status.name] then
			return true
		end
	end
	return false
end

function Status.hasControl(unit: Unit): boolean
	for _, status in unit.statuses do
		if Status.CONTROL[status.name] then
			return true
		end
	end
	return false
end

-- R-M1-05 : multiplicateurs de VIT (Ralenti, Enracine), un par statut.
function Status.vitMultipliers(config: CombatConfig, unit: Unit): { number }
	local defs = Status.defs(config)
	local mults: { number } = {}
	for _, status in unit.statuses do
		local def = defs[status.name]
		if def and def.VIT then
			table.insert(mults, 1 + def.VIT)
		end
	end
	return mults
end

-- R-M1-43 : Expose => degats subis x (1 + damageTaken).
function Status.damageTakenMult(config: CombatConfig, unit: Unit): number
	local defs = Status.defs(config)
	local mult = 1
	for _, status in unit.statuses do
		local def = defs[status.name]
		if def and def.damageTaken then
			mult *= 1 + def.damageTaken
		end
	end
	return mult
end

-- R-M1-03 : K.O. : plus d'action, plus ciblable, statuts effaces. L'equipe adverse gagne megaGainPerKO (R-M1-31).
function Status.knockOut(state: State, unit: Unit)
	if not unit.alive then
		return
	end
	unit.hp = 0
	unit.alive = false
	unit.statuses = {}
	unit.guarding = false
	local enemy = Status.enemyTeamOf(state, unit)
	enemy.mega =
		math.min(state.config.Combat.megaGaugeMax, enemy.mega + state.config.Combat.megaGainPerKO)
	local entry = state.currentEntry
	if entry then
		table.insert(entry.kos, ActionLog.caseOf(unit))
		entry.hp[ActionLog.caseOf(unit)] = 0
	end
end

-- R-M1-36 : Endormi tombe au premier degat > 0.
function Status.onDamaged(state: State, unit: Unit, value: number)
	if value <= 0 then
		return
	end
	local defs = Status.defs(state.config)
	for _, status in table.clone(unit.statuses) do
		local def = defs[status.name]
		if def and def.breaksOnDamage then
			Status.remove(state, unit, status.name)
		end
	end
end

-- R-M1-41, R-M1-42 : dots au debut du tour du porteur, ignorent Bouclier et Garde, pas d'energie, peuvent K.O.
-- `multiplier` est le multiplicateur de mort subite (R-M1-57). Retourne le total inflige.
function Status.onTurnStart(state: State, unit: Unit, multiplier: number): number
	local defs = Status.defs(state.config)
	local total = 0
	for _, status in table.clone(unit.statuses) do
		local def = defs[status.name]
		if def and def.kind == "dot" and def.hpMaxPerTurn then
			local value = math.floor(def.hpMaxPerTurn * status.stacks * unit.hpMax * multiplier)
			unit.hp -= value
			total += value
			local entry = state.currentEntry
			if entry then
				table.insert(entry.ticks, `{status.name}:-{value}`)
			end
		end
	end
	if unit.hp <= 0 then
		Status.knockOut(state, unit)
	end
	return total
end

-- Fin du tour du porteur : immunite puis durees. Un statut pose pendant ce tour n'est pas decremente.
function Status.onTurnEnd(state: State, unit: Unit)
	if unit.controlImmunity > 0 then
		unit.controlImmunity -= 1
	end
	for _, status in table.clone(unit.statuses) do
		if status.name == "HorsCombat" or status.appliedAt == state.actions then
			continue
		end
		if status.name == "Bouclier" and status.shield <= 0 then
			Status.remove(state, unit, status.name)
		elseif status.turns ~= nil then
			status.turns -= 1
			if status.turns <= 0 then
				Status.remove(state, unit, status.name)
			end
		end
	end
end

-- R-M1-38 : HorsCombat decremente a chaque tour d'equipe de sa propre equipe.
function Status.onTeamRound(state: State, team: TeamState)
	for _, unit in team.units do
		local status = Status.get(unit, "HorsCombat")
		if status and status.turns then
			status.turns -= 1
			if status.turns <= 0 then
				Status.remove(state, unit, "HorsCombat")
			end
		end
	end
end

return Status
