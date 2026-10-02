--!strict
-- Synergies et combos : lecture de `effectId` + `params` (Config.Synergies, Config.Combos). Les effets listes dans
-- IMPLEMENTED sont interpretes ; tout autre effectId est journalise dans `state.unimplemented` sans planter.
-- Ordre des mods de degats (R-M1-13) : (1) competence, (2) synergie offensive, (3) Expose, (4) Garde, (5) mort subite.

local Types = require(script.Parent.Parent.Types.Combat)
local Formulas = require(script.Parent.Formulas)
local Status = require(script.Parent.Status)

type State = Types.State
type Unit = Types.Unit
type TeamState = Types.TeamState
type EffectRef = Types.EffectRef

local Effects = {}

Effects.IMPLEMENTED = {
	RegenPerTurn = true,
	ColossePctHP = true,
	LienDAmour = true,
	HealPct = true,
	EnergyGainPct = true,
	FlatMAG = true,
	FlatVIT = true,
	FlatDEFRES = true,
	PctATQMAG = true,
	Lifesteal = true,
	StartShield = true,
	CritBonus = true,
	AoePct = true,
	CoupleStrike = true,
} :: { [string]: boolean }

function Effects.markUnimplemented(state: State, effectId: string)
	if not table.find(state.unimplemented, effectId) then
		table.insert(state.unimplemented, effectId)
	end
end

local function sortedSynergyNames(state: State): { string }
	local names: { string } = {}
	for name in state.config.Synergies.byName do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- D-M1-13 : 1 fois par slug distinct (familles, classes) ; Couple compte les couples complets.
local function countMembers(
	state: State,
	team: TeamState,
	name: string
): (number, { [number]: boolean })
	local def = state.config.Synergies.byName[name]
	local memberSet: { [string]: boolean } = {}
	for _, slug in def.members do
		memberSet[slug] = true
	end
	local present: { [string]: Unit } = {}
	local members: { [number]: boolean } = {}
	for _, unit in team.units do
		if memberSet[unit.slug] and unit.alive and not Status.has(unit, "HorsCombat") then
			present[unit.slug] = unit
			members[unit.id] = true
		end
	end
	local count = 0
	if def.kind == "subrole" and name == "Couple" then
		local counted: { [string]: boolean } = {}
		for slug, unit in present do
			if counted[slug] then
				continue
			end
			for _, partner in unit.duoPartners do
				if present[partner] then
					count += 1
					counted[slug] = true
					counted[partner] = true
					break
				end
			end
		end
	else
		for _ in present do
			count += 1
		end
	end
	return count, members
end

-- R-M1-02, D-M1-14 : palier actif = plus grand `count` atteint. Remplit team.activeSynergies et team.effects.
function Effects.computeSynergies(state: State, team: TeamState)
	team.activeSynergies = {}
	team.effects = {}
	for _, name in sortedSynergyNames(state) do
		local def = state.config.Synergies.byName[name]
		local count, members = countMembers(state, team, name)
		local activeTier = 0
		for index, tier in def.tiers do
			if count >= tier.count then
				activeTier = index
			end
		end
		if activeTier == 0 then
			continue
		end
		local tier = def.tiers[activeTier]
		team.activeSynergies[name] = activeTier
		if name == "Tentafruit" and state.options.tentafruitEnabled == false then
			continue
		end
		local ref: EffectRef =
			{ source = name, effectId = tier.effectId, params = tier.params, members = members }
		table.insert(team.effects, ref)
		if not Effects.IMPLEMENTED[tier.effectId] then
			Effects.markUnimplemented(state, tier.effectId)
		end
		for _, unit in team.units do
			if members[unit.id] then
				unit.synergyMember = true
			end
		end
	end
end

-- Params de l'effet `effectId` si `unit` en est membre, sinon nil.
function Effects.paramsFor(team: TeamState, unit: Unit, effectId: string): { [string]: number }?
	for _, effect in team.effects do
		if effect.effectId == effectId and effect.members[unit.id] then
			return effect.params
		end
	end
	return nil
end

function Effects.hasEffect(team: TeamState, effectId: string): boolean
	for _, effect in team.effects do
		if effect.effectId == effectId then
			return true
		end
	end
	return false
end

-- R-M1-02 : bonus de stats avant le premier tick (pourcentages additionnes, puis plats, puis floor).
function Effects.applyStatEffects(_state: State, team: TeamState)
	for _, unit in team.units do
		local pct: { [string]: number } = {}
		local flat: { [string]: number } = {}
		for _, effect in team.effects do
			if not effect.members[unit.id] then
				continue
			end
			local p = effect.params
			if effect.effectId == "ColossePctHP" then
				pct.HP = (pct.HP or 0) + p.pct
			elseif effect.effectId == "PctATQMAG" then
				pct.ATQ = (pct.ATQ or 0) + p.pct
				pct.MAG = (pct.MAG or 0) + p.pct
			elseif effect.effectId == "FlatMAG" then
				flat.MAG = (flat.MAG or 0) + p.MAG
			elseif effect.effectId == "FlatVIT" then
				flat.VIT = (flat.VIT or 0) + p.VIT
			elseif effect.effectId == "FlatDEFRES" then
				flat.DEF = (flat.DEF or 0) + p.amount
				flat.RES = (flat.RES or 0) + p.amount
			elseif effect.effectId == "CritBonus" then
				unit.critChance += p.chance
				unit.critMultiplier = p.mult
			end
		end
		unit.stats = Formulas.applyStatBonuses(unit.stats, pct, flat)
		unit.hpMax = unit.stats.HP
		unit.hp = unit.hpMax
	end
end

-- Effets de debut de combat (StartShield, Giungla).
function Effects.applyStartEffects(state: State, team: TeamState)
	for _, unit in team.units do
		local params = Effects.paramsFor(team, unit, "StartShield")
		if params then
			Status.apply(
				state,
				unit,
				"Bouclier",
				{ shield = math.floor(params.hpMaxPct * unit.hpMax) }
			)
		end
	end
end

-- RegenPerTurn (Mare 2) au debut du tour du membre. Retourne les PV rendus.
function Effects.onTurnStart(state: State, unit: Unit): number
	local params = Effects.paramsFor(Status.teamOf(state, unit), unit, "RegenPerTurn")
	if params == nil or not unit.alive then
		return 0
	end
	local value = math.min(math.floor(params.hpMaxPct * unit.hpMax), unit.hpMax - unit.hp)
	unit.hp += value
	local entry = state.currentEntry
	if entry and value > 0 then
		table.insert(entry.ticks, `RegenPerTurn:+{value}`)
	end
	return value
end

-- R-M1-15 : multiplicateur des gains d'energie (EnergyGainPct, Tentafruit 2, drapeau D-07).
function Effects.energyGainMult(state: State, unit: Unit): number
	local params = Effects.paramsFor(Status.teamOf(state, unit), unit, "EnergyGainPct")
	return if params then 1 + params.pct else 1
end

function Effects.healBonusPct(state: State, caster: Unit): number
	local params = Effects.paramsFor(Status.teamOf(state, caster), caster, "HealPct")
	return if params then params.pct else 0
end

function Effects.lifestealPct(state: State, attacker: Unit): number
	local params = Effects.paramsFor(Status.teamOf(state, attacker), attacker, "Lifesteal")
	return if params then params.pct else 0
end

-- R-M1-13 : mods dans l'ordre fixe. PctATQMAG est deja dans les stats (R-M1-02), il n'est pas repete ici.
function Effects.buildMods(
	state: State,
	attacker: Unit,
	target: Unit,
	skillBonus: number,
	multiTarget: boolean
): { number }
	local mods: { number } = {}
	if skillBonus ~= 0 then
		table.insert(mods, 1 + skillBonus)
	end
	if multiTarget then
		local aoe = Effects.paramsFor(Status.teamOf(state, attacker), attacker, "AoePct")
		if aoe then
			table.insert(mods, 1 + aoe.pct)
		end
	end
	local expose = Status.damageTakenMult(state.config, target)
	if expose ~= 1 then
		table.insert(mods, expose)
	end
	if target.guarding then
		table.insert(mods, state.config.Combat.guardDamageReduction)
	end
	local sudden = Formulas.suddenDeathMult(state.config, state.actions)
	if sudden ~= 1 then
		table.insert(mods, sudden)
	end
	return mods
end

-- R-M1-32 : combos disponibles pour l'equipe, tries par id, implementes seulement.
function Effects.availableCombos(state: State, team: TeamState): { string }
	local combat = state.config.Combat
	local out: { string } = {}
	if team.mega < combat.megaGaugeMax then
		return out
	end
	local present: { [string]: boolean } = {}
	local familyCount: { [string]: number } = {}
	for _, unit in team.units do
		if unit.alive and not Status.has(unit, "HorsCombat") then
			present[unit.slug] = true
			for _, family in state.config.Roster.units[unit.slug].families do
				familyCount[family] = (familyCount[family] or 0) + 1
			end
		end
	end
	local ids: { string } = {}
	for id in state.config.Combos.byId do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		local combo = state.config.Combos.byId[id]
		if (team.megaUsed[id] or 0) >= combat.megaUsesPerComboPerCombat then
			continue
		end
		if not Effects.IMPLEMENTED[combo.effectId] then
			continue
		end
		local ok = true
		if combo.requires.all then
			for _, slug in combo.requires.all do
				ok = ok and present[slug] == true
			end
		end
		if combo.requires.anyPair then
			ok = ok and Effects.findPair(combo.requires.anyPair, present) ~= nil
		end
		if combo.requires.counts then
			for family, needed in combo.requires.counts do
				ok = ok and (familyCount[family] or 0) >= needed
			end
		end
		if ok then
			table.insert(out, id)
		end
	end
	return out
end

function Effects.findPair(pairs: { { string } }, present: { [string]: boolean }): { string }?
	for _, pair in pairs do
		if present[pair[1]] and present[pair[2]] then
			return pair
		end
	end
	return nil
end

return Effects
