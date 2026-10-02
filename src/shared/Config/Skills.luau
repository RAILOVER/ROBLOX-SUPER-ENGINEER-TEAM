--!strict
-- Competences des 10 unites M1 (brief §7.2, spec M1-combat R-M1-12, R-M1-22 a R-M1-24). Module pur, sans require.
-- Puissances provisoires chiffrees par T-0010, a relire par le game designer (ticket T-0020).
-- `cost` = Combat.classes[class].skillCost (R-M1-17). `power` multiplie ATQ (ou MAG si params.magic = 1) dans la
-- formule R-M1-10 ; pour un soin, `power` multiplie MAG (R-M1-11).

export type SkillTarget = "enemy" | "enemyBackline" | "enemies" | "self" | "allyLowestHp" | "allies"
export type SkillDef = {
	skillId: string,
	cost: number,
	power: number,
	effectId: string,
	params: { [string]: number },
	target: SkillTarget,
}

local Skills: { [string]: SkillDef } = {
	["tim-cheese"] = {
		skillId = "Grignotage",
		cost = 80,
		power = 0.75,
		effectId = "MultiHit", -- R-M1-23 : 2 Attaques sur la meme cible, 1 action, 1 gain d'energie pour la cible
		params = { hits = 2 },
		target = "enemy",
	},
	["trippi-troppi"] = {
		skillId = "BondDeCrevette",
		cost = 80,
		power = 1.6,
		effectId = "StrikeBackline", -- ligne arriere la plus faible, sinon ligne avant
		params = {},
		target = "enemyBackline",
	},
	["ta-ta-ta-ta-sahur"] = {
		skillId = "TaTaTaTa",
		cost = 100,
		power = 1.0,
		effectId = "WakeAlliesSleepEnemy", -- R-M1-22 : reveille les allies, degats magiques puis 50 % Endormi
		params = { magic = 1, sleepChance = 0.50, sleepTurns = 1 },
		target = "enemy",
	},
	["banano"] = {
		skillId = "MusclesDeLaVilla",
		cost = 100,
		power = 0,
		effectId = "TauntShield", -- R-M1-24 : Provocation 1 tour + Bouclier 20 % HPmax
		params = { tauntTurns = 1, shieldPct = 0.20 },
		target = "self",
	},
	["bananella"] = {
		skillId = "LancerDePeau",
		cost = 100,
		power = 1.5,
		effectId = "DamageStunChance", -- degats puis 25 % Etourdi 1 tour
		params = { stunChance = 0.25, stunTurns = 1 },
		target = "enemy",
	},
	["pomito"] = {
		skillId = "CroquePomme",
		cost = 90,
		power = 1.8,
		effectId = "PowerStrike",
		params = {},
		target = "enemy",
	},
	["pomita"] = {
		skillId = "CompoteReconfortante",
		cost = 70,
		power = 2.5,
		effectId = "Heal", -- R-M1-11 et R-M1-29 : floor(2,5 x MAG x (1 + HealPct)) sur l'allie le plus blesse
		params = {},
		target = "allyLowestHp",
	},
	["myrtila"] = {
		skillId = "Smoothie",
		cost = 70,
		power = 1.2,
		effectId = "HealEnergy", -- petit soin + 20 energie a la cible
		params = { energy = 20 },
		target = "allyLowestHp",
	},
	["glorbo-fruttodrillo"] = {
		skillId = "MachoireJuteuse",
		cost = 100,
		power = 1.3,
		effectId = "DamageTauntLifesteal", -- R-M1-24 : Provocation 1 tour, soin floor(0,30 x degats)
		params = { tauntTurns = 1, lifestealPct = 0.30 },
		target = "enemy",
	},
	["boneca-ambalabu"] = {
		skillId = "RebondDePneu",
		cost = 100,
		power = 0.8,
		effectId = "MultiTargetTaunt", -- R-M1-24 : 3 ennemis distincts a 0,80 puis Provocation 1 tour
		params = { targets = 3, tauntTurns = 1 },
		target = "enemies",
	},
}

-- Les 32 autres unites L0 : Attaque renforcee x1,5 au cout de leur classe (le cout est injecte par CombatSim).
local DEFAULT = {
	skillId = "AttaqueRenforcee",
	power = 1.5,
	effectId = "PowerStrike",
	params = {},
	target = "enemy" :: SkillTarget,
}

local function defaultFor(skillCost: number): SkillDef
	return {
		skillId = DEFAULT.skillId,
		cost = skillCost,
		power = DEFAULT.power,
		effectId = DEFAULT.effectId,
		params = DEFAULT.params,
		target = DEFAULT.target,
	}
end

for _, def in Skills do
	table.freeze(def)
end

return table.freeze({
	bySlug = table.freeze(Skills),
	default = table.freeze(DEFAULT),
	defaultFor = defaultFor,
	m1Slugs = table.freeze({
		"tim-cheese",
		"trippi-troppi",
		"ta-ta-ta-ta-sahur",
		"banano",
		"bananella",
		"pomito",
		"pomita",
		"myrtila",
		"glorbo-fruttodrillo",
		"boneca-ambalabu",
	}),
})
