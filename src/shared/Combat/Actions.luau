--!strict
-- Les actions d'unite et d'equipe : Attaque, Garde, Duo, Mega Combo (R-M1-14 a R-M1-21, R-M1-34), plus les
-- primitives dealDamage / healUnit / gainEnergy utilisees par SkillEffects. Chaque action ecrit dans l'entree
-- courante du journal (state.currentEntry).

local Types = require(script.Parent.Parent.Types.Combat)
local ActionLog = require(script.Parent.ActionLog)
local Effects = require(script.Parent.Effects)
local Formulas = require(script.Parent.Formulas)
local Status = require(script.Parent.Status)
local Targeting = require(script.Parent.Targeting)

type State = Types.State
type Unit = Types.Unit
type TeamState = Types.TeamState
type ActionEntry = Types.ActionEntry
type ActionKind = Types.ActionKind

local Actions = {}

export type DamageOptions = {
	skillBonus: number?,
	multi: boolean?,
	magic: boolean?,
	lifestealPct: number?,
}

local function entryOf(state: State): ActionEntry
	local entry = state.currentEntry
	assert(entry ~= nil, "aucune entree de journal ouverte")
	return entry
end

-- R-M1-56 : ouvre une entree et compte 1 action.
function Actions.beginEntry(state: State, actor: Unit, kind: ActionKind): ActionEntry
	state.actions += 1
	state.hitThisAction = {}
	local entry = ActionLog.newEntry(state.actions, actor, kind)
	state.currentEntry = entry
	table.insert(state.log, entry)
	return entry
end

function Actions.finishEntry(state: State, actor: Unit)
	local entry = entryOf(state)
	entry.gauges = { energy = actor.energy, mega = Status.teamOf(state, actor).mega }
	entry.hp[ActionLog.caseOf(actor)] = math.max(0, actor.hp)
	state.currentEntry = nil
end

function Actions.isMagicAttacker(state: State, unit: Unit): boolean
	return table.find(state.config.Combat.magicBasicAttackClasses, unit.class) ~= nil
end

-- R-M1-15 : gain d'energie borne, multiplie par EnergyGainPct (arrondi inferieur).
function Actions.gainEnergy(state: State, unit: Unit, amount: number)
	if not unit.alive then
		return
	end
	local gained = math.floor(amount * Effects.energyGainMult(state, unit))
	unit.energy = math.min(state.config.Combat.energyMax, unit.energy + gained)
end

local function logTarget(state: State, target: Unit, value: number, crit: boolean)
	local entry = entryOf(state)
	table.insert(entry.targets, ActionLog.caseOf(target))
	table.insert(entry.values, value)
	table.insert(entry.crits, crit)
	entry.hp[ActionLog.caseOf(target)] = math.max(0, target.hp)
end

-- R-M1-11 : soin par formule, journalise en valeur negative. `rawValue` court-circuite la formule (Mega, R-M1-34).
function Actions.healUnit(
	state: State,
	caster: Unit,
	target: Unit,
	power: number,
	rawValue: number?
): number
	if not target.alive then
		return 0
	end
	local value = rawValue
		or Formulas.heal(power, caster.stats.MAG, Effects.healBonusPct(state, caster))
	local applied = math.min(value, target.hpMax - target.hp)
	target.hp += applied
	caster.healingDone += applied
	logTarget(state, target, -applied, false)
	return applied
end

-- R-M1-10, R-M1-13, R-M1-14 : degats puis application dans l'ordre fixe de la spec.
function Actions.dealDamage(
	state: State,
	attacker: Unit,
	target: Unit,
	power: number,
	options: DamageOptions?
): number
	if not target.alive or not attacker.alive then
		return 0
	end
	local opts: DamageOptions = options or {}
	local combat = state.config.Combat
	local magic = opts.magic == true
	local attackStat = if magic then attacker.stats.MAG else attacker.stats.ATQ
	local defenseStat = if magic then target.stats.RES else target.stats.DEF
	local mods =
		Effects.buildMods(state, attacker, target, opts.skillBonus or 0, opts.multi == true)
	local value, crit = Formulas.damage(
		state.config,
		power,
		attackStat,
		defenseStat,
		state.rng,
		attacker.critChance,
		attacker.critMultiplier,
		mods
	)
	local remaining = value
	local shield = Status.get(target, "Bouclier")
	if shield and shield.shield > 0 then
		local absorbed = math.min(shield.shield, remaining)
		shield.shield -= absorbed
		remaining -= absorbed
		if shield.shield <= 0 then
			Status.remove(state, target, "Bouclier")
		end
	end
	target.hp -= remaining
	attacker.damageDealt += value
	local targetTeam = Status.teamOf(state, target)
	targetTeam.damageFromEnemy[attacker.id] = (targetTeam.damageFromEnemy[attacker.id] or 0) + value
	logTarget(state, target, value, crit)
	local thorns = Status.get(target, "Epines")
	if
		thorns
		and thorns.thornsPct > 0
		and (attacker.range == "Melee" or attacker.range == "MeleeBackline")
	then
		local back = math.floor(value * thorns.thornsPct)
		attacker.hp -= back
		table.insert(entryOf(state).ticks, `Epines:-{back}@{ActionLog.caseOf(attacker)}`)
		entryOf(state).hp[ActionLog.caseOf(attacker)] = math.max(0, attacker.hp)
	end
	if target.hp > 0 then
		Status.onDamaged(state, target, value)
		if not state.hitThisAction[target.id] then
			state.hitThisAction[target.id] = true
			Actions.gainEnergy(state, target, combat.energyPerHitTaken)
			local lien = Effects.paramsFor(targetTeam, target, "LienDAmour")
			if lien then
				for _, ally in targetTeam.units do
					if ally.alive and table.find(target.duoPartners, ally.slug) then
						Actions.gainEnergy(state, ally, lien.energyOnPartnerHit)
					end
				end
			end
		end
	end
	local lifesteal = opts.lifestealPct or Effects.lifestealPct(state, attacker)
	if lifesteal > 0 and attacker.hp > 0 then
		local healed = math.min(math.floor(value * lifesteal), attacker.hpMax - attacker.hp)
		attacker.hp += healed
		attacker.healingDone += healed
		entryOf(state).hp[ActionLog.caseOf(attacker)] = attacker.hp
	end
	if target.hp <= 0 then
		Status.knockOut(state, target)
	end
	if attacker.hp <= 0 then
		Status.knockOut(state, attacker)
	end
	return value
end

-- R-M1-16 : Attaque de base. Retourne false s'il n'y a aucune cible (l'appelant journalise un Skip).
function Actions.attack(state: State, unit: Unit, forcedTarget: Unit?): boolean
	local target = forcedTarget or Targeting.single(state, unit)
	if target == nil then
		return false
	end
	local combat = state.config.Combat
	local magic = Actions.isMagicAttacker(state, unit)
	local power = if magic then combat.basicAttackMagicPower else combat.basicAttackPower
	Actions.dealDamage(state, unit, target, power, { magic = magic })
	Actions.gainEnergy(state, unit, combat.energyPerBasicAttack)
	return true
end

-- R-M1-18 : Garde.
function Actions.guard(state: State, unit: Unit)
	unit.guarding = true
	Actions.gainEnergy(state, unit, state.config.Combat.guardEnergyGain)
end

-- R-M1-19 : Duo (D-05 : 2 Attaques separees a x1,20 sur la meme cible, ciblage du lanceur).
function Actions.duo(state: State, unit: Unit, partner: Unit): boolean
	local target = Targeting.single(state, unit)
	if target == nil then
		return false
	end
	local combat = state.config.Combat
	unit.energy -= combat.duoEnergyCost
	partner.energy -= combat.duoEnergyCost
	entryOf(state).partner = ActionLog.actorOf(partner)
	local power = combat.basicAttackPower * combat.duoPowerMultiplier
	Actions.dealDamage(state, unit, target, power, { magic = Actions.isMagicAttacker(state, unit) })
	Actions.dealDamage(
		state,
		partner,
		target,
		power,
		{ magic = Actions.isMagicAttacker(state, partner) }
	)
	return true
end

local function fasterFirst(a: Unit, b: Unit): (Unit, Unit)
	if b.stats.VIT > a.stats.VIT or (b.stats.VIT == a.stats.VIT and b.cell < a.cell) then
		return b, a
	end
	return a, b
end

local function findUnit(team: TeamState, slug: string): Unit?
	for _, unit in team.units do
		if unit.slug == slug and unit.alive then
			return unit
		end
	end
	return nil
end

-- R-M1-20, R-M1-32, R-M1-34 : Mega Combo C05 "CoupleStrike". Compte 1 action, remet la jauge a 0.
function Actions.mega(state: State, team: TeamState, comboId: string): boolean
	local combo = state.config.Combos.byId[comboId]
	assert(combo ~= nil and combo.effectId == "CoupleStrike", `combo non implemente : {comboId}`)
	local present: { [string]: boolean } = {}
	for _, unit in team.units do
		if unit.alive and not Status.has(unit, "HorsCombat") then
			present[unit.slug] = true
		end
	end
	local pair = Effects.findPair(combo.requires.anyPair or {}, present)
	if pair == nil then
		return false
	end
	local first, second = findUnit(team, pair[1]), findUnit(team, pair[2])
	if first == nil or second == nil then
		return false
	end
	local faster, other = fasterFirst(first, second)
	local entry = Actions.beginEntry(state, faster, "Mega")
	entry.combo = comboId
	entry.partner = ActionLog.actorOf(other)
	for _, partner in { faster, other } do
		Status.apply(
			state,
			partner,
			"Bouclier",
			{ shield = math.floor(combo.params.shieldPct * partner.hpMax) }
		)
		Actions.healUnit(
			state,
			partner,
			partner,
			0,
			math.floor(combo.params.healPct * partner.hpMax)
		)
	end
	local target = Targeting.single(state, faster)
	if target then
		Actions.dealDamage(
			state,
			faster,
			target,
			combo.params.atqPct,
			{ magic = Actions.isMagicAttacker(state, faster) }
		)
		Actions.dealDamage(
			state,
			other,
			target,
			combo.params.atqPct,
			{ magic = Actions.isMagicAttacker(state, other) }
		)
	end
	team.mega = 0
	team.megaUsed[comboId] = (team.megaUsed[comboId] or 0) + 1
	Actions.finishEntry(state, faster)
	return true
end

return Actions
