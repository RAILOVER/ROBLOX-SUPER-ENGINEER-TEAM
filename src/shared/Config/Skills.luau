--!strict
-- Competences des 10 unites M1 (brief §7.2, spec M1-combat R-M1-12, R-M1-22 a R-M1-24). Module pur, sans require.
-- Valeurs relues par le game designer (T-0023, spec M1-duel-minimal section 4) : une competence a `cost` 100 vaut
-- 2 a 3 Attaques de base (100 energie = 4 Attaques d'accumulation), 80 => 1,6 a 2,4 ; 70 => 1,4 a 2,1.
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
		power = 0.75, -- T-0023 : 2 x 0,75 = 1,5, sous la fourchette du cout 80 mais VIT 140 => 1,9 lancers par combat
		effectId = "MultiHit", -- R-M1-23 : 2 Attaques sur la meme cible, 1 action, 1 gain d'energie pour la cible
		params = { hits = 2 },
		target = "enemy",
	},
	["trippi-troppi"] = {
		skillId = "BondDeCrevette",
		cost = 80,
		power = 1.6, -- T-0023 : confirme, ATQ 140 et DEF arriere 20 a 30 => 1,6 vaut 2 Attaques sur la ligne avant
		effectId = "StrikeBackline", -- ligne arriere la plus faible, sinon ligne avant
		params = {},
		target = "enemyBackline",
	},
	["ta-ta-ta-ta-sahur"] = {
		skillId = "TaTaTaTa",
		cost = 100,
		power = 1.6, -- T-0023 : 1,0 valait 1,25 Attaque magique (0,8 MAG) pour 100 energie ; 1,6 = 2 Attaques
		effectId = "WakeAlliesSleepEnemy", -- R-M1-22 : reveille les allies, degats magiques puis 50 % Endormi
		params = { magic = 1, sleepChance = 0.50, sleepTurns = 1 },
		target = "enemy",
	},
	["banano"] = {
		skillId = "MusclesDeLaVilla",
		cost = 100,
		power = 0,
		effectId = "TauntShield", -- R-M1-24 : Provocation 1 tour + Bouclier 20 % HPmax
		params = { tauntTurns = 1, shieldPct = 0.25 }, -- T-0023 : 0,20 => 45 % de victoires contre 55 % des 2 autres Colosses
		target = "self",
	},
	["bananella"] = {
		skillId = "LancerDePeau",
		cost = 100,
		power = 1.8, -- T-0023 : 1,5 + 25 % d'Etourdi valait 1,75 Attaque pour 100 energie ; 1,8 + 0,25 = 2,05
		effectId = "DamageStunChance", -- degats puis 25 % Etourdi 1 tour
		params = { stunChance = 0.25, stunTurns = 1 },
		target = "enemy",
	},
	["pomito"] = {
		skillId = "CroquePomme",
		cost = 90,
		power = 1.5, -- T-0023 : fiche L0 "se soigne de 50 % des degats" ; 1,5 + soin 0,75 = 2,25 pour 90 energie
		effectId = "PowerStrike",
		params = { lifestealPct = 0.50 },
		target = "enemy",
	},
	["pomita"] = {
		skillId = "CompoteReconfortante",
		cost = 70,
		power = 2.5, -- T-0023 : confirme, 2,5 x MAG 110 = 275 PV = 25 % des PV d'un Guerrier (fiche "soin de 25 %")
		effectId = "Heal", -- R-M1-11 et R-M1-29 : floor(2,5 x MAG x (1 + HealPct)) sur l'allie le plus blesse
		params = {},
		target = "allyLowestHp",
	},
	["myrtila"] = {
		skillId = "Smoothie",
		cost = 70,
		power = 1.6, -- T-0023 : 1,2 (132 PV) donnait 41 % de victoires ; 1,6 = 176 PV, toujours sous Compote (275)
		effectId = "HealEnergy", -- petit soin + 20 energie a la cible
		params = { energy = 20 },
		target = "allyLowestHp",
	},
	["glorbo-fruttodrillo"] = {
		skillId = "MachoireJuteuse",
		cost = 100,
		power = 1.3, -- T-0023 : confirme, 1,3 + soin 0,39 + Provocation ; 55 % de victoires avec les stats Colosse
		effectId = "DamageTauntLifesteal", -- R-M1-24 : Provocation 1 tour, soin floor(0,30 x degats)
		params = { tauntTurns = 1, lifestealPct = 0.30 },
		target = "enemy",
	},
	["boneca-ambalabu"] = {
		skillId = "RebondDePneu",
		cost = 100,
		power = 0.8, -- T-0023 : confirme, 3 x 0,8 = 2,4 Attaques pour 100 energie, dans la fourchette
		effectId = "MultiTargetTaunt", -- R-M1-24 : 3 ennemis distincts a 0,80 puis Provocation 1 tour
		params = { targets = 3, tauntTurns = 1 },
		target = "enemies",
	},
}

-- Les 32 autres unites L0 : Attaque renforcee x2,0 au cout de leur classe (le cout est injecte par CombatSim).
-- T-0023 : 1,5 valait moins de 2 Attaques pour les classes a cout 100 ; 2,0 est le plancher du cout 100.
local DEFAULT = {
	skillId = "AttaqueRenforcee",
	power = 2.0,
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
