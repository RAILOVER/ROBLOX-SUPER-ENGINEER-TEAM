--!strict
-- Formules du combat (R-M1-01, R-M1-02, R-M1-10 a R-M1-13, R-M1-57). Pseudo-code de la spec, memes arrondis.

local Types = require(script.Parent.Parent.Types.Combat)

type CombatConfig = Types.CombatConfig
type Rng = Types.Rng
type Stats = Types.Stats
type StatName = Types.StatName

local Formulas = {}

Formulas.STAT_NAMES = { "HP", "ATQ", "MAG", "DEF", "RES", "VIT" } :: { StatName }
local STAR_STATS = { HP = true, ATQ = true, MAG = true } :: { [string]: boolean }

-- R-M1-01 : gabarit de classe x statCoef x statOverrides (defaut 1) x etoiles (HP, ATQ, MAG), entier inferieur.
function Formulas.buildStats(config: CombatConfig, slug: string, stars: number): Stats
	local def = config.Roster.units[slug]
	assert(def ~= nil, `unite inconnue : {slug}`)
	local template = config.Combat.classes[def.class]
	assert(template ~= nil, `classe inconnue : {def.class}`)
	local rarity = config.Rarities.byName[def.rarity]
	assert(rarity ~= nil, `rarete inconnue : {def.rarity}`)
	local starMult = config.Progression.starMultipliers[stars]
	assert(starMult ~= nil, `etoiles invalides : {stars}`)
	local raw: { [string]: number } = {}
	for _, name in Formulas.STAT_NAMES do
		local base = template[name] :: number
		local override = def.statOverrides[name] or 1
		local value = base * rarity.statCoef * override
		if STAR_STATS[name] then
			value *= starMult
		end
		raw[name] = math.floor(value)
	end
	return { HP = raw.HP, ATQ = raw.ATQ, MAG = raw.MAG, DEF = raw.DEF, RES = raw.RES, VIT = raw.VIT }
end

-- R-M1-02 : les pourcentages s'additionnent avant la multiplication, puis les bonus plats, entier inferieur.
function Formulas.applyStatBonuses(
	stats: Stats,
	pct: { [string]: number },
	flat: { [string]: number }
): Stats
	local out: { [string]: number } = {}
	for _, name in Formulas.STAT_NAMES do
		local value = stats[name] * (1 + (pct[name] or 0)) + (flat[name] or 0)
		out[name] = math.floor(value)
	end
	return { HP = out.HP, ATQ = out.ATQ, MAG = out.MAG, DEF = out.DEF, RES = out.RES, VIT = out.VIT }
end

-- R-M1-10 : degats d'une attaque. Retourne la valeur entiere (minimumDamage au moins) et le drapeau critique.
function Formulas.damage(
	config: CombatConfig,
	power: number,
	attackStat: number,
	defenseStat: number,
	rng: Rng,
	critChance: number,
	critMultiplier: number,
	mods: { number }
): (number, boolean)
	local combat = config.Combat
	local base = power * attackStat * 100 / (100 + defenseStat)
	local variance = rng:NextNumber(combat.damageVariance[1], combat.damageVariance[2])
	local isCrit = rng:NextNumber() < critChance
	local crit = if isCrit then critMultiplier else 1
	local value = base * variance * crit
	for _, m in mods do
		value *= m
	end
	return math.max(combat.minimumDamage, math.floor(value + 0.5)), isCrit
end

-- R-M1-11 : soins.
function Formulas.heal(power: number, mag: number, healBonusPct: number): number
	return math.floor(power * mag * (1 + healBonusPct) + 0.5)
end

-- R-M1-57 : multiplicateur de mort subite pour l'action numero `actions` (1 avant le seuil).
function Formulas.suddenDeathMult(config: CombatConfig, actions: number): number
	local combat = config.Combat
	if actions <= combat.suddenDeathAfterActions then
		return 1
	end
	return (1 + combat.suddenDeathDamageRamp) ^ (actions - combat.suddenDeathAfterActions)
end

-- R-M1-05 : VIT effective, les malus VIT des statuts se multiplient, minimum 1.
function Formulas.effectiveVit(vit: number, vitMultipliers: { number }): number
	local value = vit
	for _, m in vitMultipliers do
		value *= m
	end
	return math.max(1, math.floor(value))
end

return Formulas
