--!strict
-- Effets des competences (Config.Skills). Chaque handler recoit l'unite et sa fiche et retourne true si la
-- competence a ete jouee (sinon la tactique retombe sur une Attaque). Un effectId inconnu est journalise
-- `unimplemented` et joue comme PowerStrike.

local Types = require(script.Parent.Parent.Types.Combat)
local Actions = require(script.Parent.Actions)
local Effects = require(script.Parent.Effects)
local Status = require(script.Parent.Status)
local Targeting = require(script.Parent.Targeting)

type State = Types.State
type Unit = Types.Unit
type SkillDef = Types.SkillDef

type Handler = (state: State, unit: Unit, skill: SkillDef) -> boolean

local SkillEffects = {}

local function isMagic(skill: SkillDef): boolean
	return skill.params.magic == 1
end

local function strike(
	state: State,
	unit: Unit,
	skill: SkillDef,
	target: Unit?,
	lifestealPct: number?
): boolean
	if target == nil then
		return false
	end
	Actions.dealDamage(
		state,
		unit,
		target,
		skill.power,
		{ magic = isMagic(skill), lifestealPct = lifestealPct }
	)
	return true
end

local function backlineTarget(state: State, unit: Unit): Unit?
	local pool = Targeting.candidates(state, unit, "MeleeBackline")
	local back: { Unit } = {}
	for _, enemy in pool do
		if enemy.row == 2 then
			table.insert(back, enemy)
		end
	end
	return Targeting.pickSingle(state, unit, if #back > 0 then back else pool)
end

local HANDLERS: { [string]: Handler } = {}

HANDLERS.PowerStrike = function(state, unit, skill)
	return strike(state, unit, skill, Targeting.single(state, unit))
end

-- R-M1-23 : `hits` Attaques sur la meme cible, 1 seul gain energyPerHitTaken (state.hitThisAction).
HANDLERS.MultiHit = function(state, unit, skill)
	local target = Targeting.single(state, unit)
	if target == nil then
		return false
	end
	for _ = 1, skill.params.hits do
		if not target.alive then
			break
		end
		Actions.dealDamage(state, unit, target, skill.power, { magic = isMagic(skill) })
	end
	return true
end

HANDLERS.StrikeBackline = function(state, unit, skill)
	return strike(state, unit, skill, backlineTarget(state, unit))
end

-- R-M1-22 : reveille les allies, frappe 1 ennemi, puis 50 % de chance d'Endormi (R-M1-48 s'applique).
HANDLERS.WakeAlliesSleepEnemy = function(state, unit, skill)
	for _, ally in Targeting.aliveAllies(state, unit, true) do
		if Status.has(ally, "Endormi") then
			Status.remove(state, ally, "Endormi")
		end
	end
	local enemies = Targeting.aliveEnemies(state, unit)
	if #enemies == 0 then
		return false
	end
	local target = enemies[state.rng:NextInteger(1, #enemies)]
	if skill.power > 0 then
		Actions.dealDamage(state, unit, target, skill.power, { magic = isMagic(skill) })
	end
	if target.alive and state.rng:NextNumber() < skill.params.sleepChance then
		Status.apply(state, target, "Endormi", { turns = skill.params.sleepTurns })
	end
	return true
end

-- R-M1-24 : Provocation sur la source + Bouclier.
HANDLERS.TauntShield = function(state, unit, skill)
	Status.apply(state, unit, "Provocation", { turns = skill.params.tauntTurns })
	Status.apply(
		state,
		unit,
		"Bouclier",
		{ shield = math.floor(skill.params.shieldPct * unit.hpMax) }
	)
	local entry = state.currentEntry
	if entry then
		table.insert(entry.targets, `{unit.side}{unit.cell}`)
		table.insert(entry.values, 0)
		table.insert(entry.crits, false)
	end
	return true
end

HANDLERS.DamageStunChance = function(state, unit, skill)
	local target = Targeting.single(state, unit)
	if target == nil then
		return false
	end
	Actions.dealDamage(state, unit, target, skill.power, { magic = isMagic(skill) })
	if target.alive and state.rng:NextNumber() < skill.params.stunChance then
		Status.apply(state, target, "Etourdi", { turns = skill.params.stunTurns })
	end
	return true
end

-- R-M1-29 : soin sur l'allie le plus blesse.
HANDLERS.Heal = function(state, unit, skill)
	Actions.healUnit(state, unit, Targeting.healTarget(state, unit), skill.power)
	return true
end

HANDLERS.HealEnergy = function(state, unit, skill)
	local target = Targeting.healTarget(state, unit)
	Actions.healUnit(state, unit, target, skill.power)
	Actions.gainEnergy(state, target, skill.params.energy)
	return true
end

-- R-M1-24 : Machoire juteuse : degats, soin de la source floor(lifestealPct x degats), Provocation.
HANDLERS.DamageTauntLifesteal = function(state, unit, skill)
	local target = Targeting.single(state, unit)
	if target == nil then
		return false
	end
	Actions.dealDamage(
		state,
		unit,
		target,
		skill.power,
		{ magic = isMagic(skill), lifestealPct = skill.params.lifestealPct }
	)
	if unit.alive then
		Status.apply(state, unit, "Provocation", { turns = skill.params.tauntTurns })
	end
	return true
end

-- R-M1-24 : Rebond de pneu : `targets` ennemis distincts puis Provocation.
HANDLERS.MultiTargetTaunt = function(state, unit, skill)
	local targets = Targeting.multiple(state, unit, skill.params.targets)
	if #targets == 0 then
		return false
	end
	for _, target in targets do
		Actions.dealDamage(
			state,
			unit,
			target,
			skill.power,
			{ magic = isMagic(skill), multi = true }
		)
	end
	if unit.alive then
		Status.apply(state, unit, "Provocation", { turns = skill.params.tauntTurns })
	end
	return true
end

SkillEffects.HANDLERS = HANDLERS

-- R-M1-17 : joue la competence de l'unite si elle a une cible ; debite l'energie seulement en cas de succes.
function SkillEffects.run(state: State, unit: Unit): boolean
	local skill = unit.skill
	local handler = HANDLERS[skill.effectId]
	if handler == nil then
		Effects.markUnimplemented(state, skill.effectId)
		handler = HANDLERS.PowerStrike
	end
	local entry = state.currentEntry
	if entry then
		entry.skillId = skill.skillId
	end
	local played = handler(state, unit, skill)
	if played then
		unit.energy = math.max(0, unit.energy - unit.skillCost)
	elseif entry then
		entry.skillId = nil
	end
	return played
end

return SkillEffects
