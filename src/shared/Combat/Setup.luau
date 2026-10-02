--!strict
-- Construction de l'etat initial : unites (R-M1-01), equipes, synergies (R-M1-02), timeline (R-M1-04).

local Types = require(script.Parent.Parent.Types.Combat)
local Effects = require(script.Parent.Effects)
local Formulas = require(script.Parent.Formulas)
local Rng = require(script.Parent.Rng)
local Timeline = require(script.Parent.Timeline)

type CombatConfig = Types.CombatConfig
type Options = Types.Options
type Side = Types.Side
type State = Types.State
type TeamState = Types.TeamState
type Unit = Types.Unit
type UnitInstance = Types.UnitInstance
type SkillDef = Types.SkillDef

local Setup = {}

local DEFAULT_TACTIC: Types.Tactic = "Equilibre"

function Setup.cellOf(config: CombatConfig, row: number, col: number): number
	return (row - 1) * config.Combat.boardColumns + (col - 1)
end

local function skillFor(config: CombatConfig, slug: string, skillCost: number): SkillDef
	local def = config.Skills.bySlug[slug]
	if def then
		return def
	end
	return config.Skills.defaultFor(skillCost)
end

function Setup.buildUnit(config: CombatConfig, instance: UnitInstance, side: Side, id: number): Unit
	local def = config.Roster.units[instance.slug]
	assert(def ~= nil, `unite inconnue : {instance.slug}`)
	assert(
		instance.row >= 1
			and instance.row <= config.Combat.boardRows
			and instance.col >= 1
			and instance.col <= config.Combat.boardColumns,
		`case invalide : {instance.slug} ({instance.row}, {instance.col})`
	)
	local template = config.Combat.classes[def.class]
	local stars = instance.stars or 1
	local stats = Formulas.buildStats(config, instance.slug, stars)
	return {
		id = id,
		slug = instance.slug,
		side = side,
		cell = Setup.cellOf(config, instance.row, instance.col),
		row = instance.row,
		col = instance.col,
		class = def.class,
		range = template.range,
		stars = stars,
		tactic = instance.tactic or DEFAULT_TACTIC,
		stats = stats,
		hpMax = stats.HP,
		hp = stats.HP,
		energy = config.Combat.energyStart,
		timeline = 0,
		skillCost = template.skillCost,
		critChance = template.critChance,
		critMultiplier = config.Combat.critMultiplier,
		statuses = {},
		guarding = false,
		alive = true,
		controlImmunity = 0,
		damageDealt = 0,
		healingDone = 0,
		skill = skillFor(config, instance.slug, template.skillCost),
		duoPartners = def.duoPartners,
		synergyMember = false,
		isBoss = false,
	}
end

-- Tri par case avant tout tirage : permuter teamA ne change pas le journal (R-M1-04).
local function sortedInstances(
	config: CombatConfig,
	instances: { UnitInstance },
	side: Side
): { UnitInstance }
	assert(
		#instances <= config.Combat.boardRows * config.Combat.boardColumns,
		`equipe {side} : plus de 8 unites`
	)
	local sorted = table.clone(instances)
	table.sort(sorted, function(a, b)
		return Setup.cellOf(config, a.row, a.col) < Setup.cellOf(config, b.row, b.col)
	end)
	for i = 2, #sorted do
		local prev, cur = sorted[i - 1], sorted[i]
		assert(
			Setup.cellOf(config, prev.row, prev.col) ~= Setup.cellOf(config, cur.row, cur.col),
			`equipe {side} : 2 unites sur la meme case ({cur.row}, {cur.col})`
		)
	end
	return sorted
end

local function newTeam(side: Side): TeamState
	return {
		side = side,
		units = {},
		mega = 0,
		megaUsed = {},
		activeSynergies = {},
		effects = {},
		focusCell = nil,
		focusTurnsLeft = 0,
		focusOrdersUsed = 0,
		damageFromEnemy = {},
		roundActed = {},
		rounds = 0,
	}
end

local function markUnimplementedCombos(state: State, team: TeamState)
	local present: { [string]: boolean } = {}
	for _, unit in team.units do
		present[unit.slug] = true
	end
	for id, combo in state.config.Combos.byId do
		if Effects.IMPLEMENTED[combo.effectId] then
			continue
		end
		local satisfied = true
		if combo.requires.all then
			for _, slug in combo.requires.all do
				satisfied = satisfied and present[slug] == true
			end
		elseif combo.requires.anyPair then
			satisfied = Effects.findPair(combo.requires.anyPair, present) ~= nil
		else
			satisfied = false
		end
		if satisfied then
			Effects.markUnimplemented(state, `{combo.effectId}({id})`)
		end
	end
end

function Setup.newState(
	seed: number,
	teamA: { UnitInstance },
	teamB: { UnitInstance },
	config: CombatConfig,
	options: Options?
): State
	local state: State = {
		seed = seed,
		config = config,
		options = options or {},
		rng = Rng.new(seed),
		teams = { A = newTeam("A"), B = newTeam("B") },
		units = {},
		actions = 0,
		ticks = 0,
		lastActedSide = nil,
		log = {},
		currentEntry = nil,
		hitThisAction = {},
		winner = nil,
		unimplemented = {},
	}
	local id = 0
	local function addTeam(side: Side, instances: { UnitInstance })
		local team = state.teams[side]
		for _, instance in sortedInstances(config, instances, side) do
			id += 1
			local unit = Setup.buildUnit(config, instance, side, id)
			table.insert(team.units, unit)
			table.insert(state.units, unit)
		end
	end
	addTeam("A", teamA)
	addTeam("B", teamB)
	for _, team in { state.teams.A, state.teams.B } do
		Effects.computeSynergies(state, team)
		Effects.applyStatEffects(state, team)
	end
	for _, team in { state.teams.A, state.teams.B } do
		Effects.applyStartEffects(state, team)
		markUnimplementedCombos(state, team)
	end
	Timeline.init(state)
	return state
end

return Setup
