--!strict
-- Synergies (brief §8). Module pur, sans require. Les membres sont des slugs du Roster; l'integrite
-- (slug existant, famille/classe coherente avec Roster) est verifiee par tests/unit/Config.spec.luau.
-- Les effets sont decrits par des cles d'effet lues par CombatSim; les textes affiches sont dans la localisation.

export type Tier = { count: number, effectId: string, params: { [string]: number } }
export type SynergyDef = {
	kind: "family" | "class" | "subrole",
	members: { string },
	tiers: { Tier },
}

local Synergies: { [string]: SynergyDef } = {
	Mare = {
		kind = "family",
		members = {
			"tralalero-tralala",
			"trippi-troppi",
			"glorbo-fruttodrillo",
			"bananita-dolfinita",
			"boneca-ambalabu",
			"chef-crabracadabra",
			"burbaloni-luliloli",
		},
		tiers = {
			{ count = 2, effectId = "RegenPerTurn", params = { hpMaxPct = 0.03 } },
			{ count = 4, effectId = "RegenPerTurnBurnImmune", params = { hpMaxPct = 0.06 } },
			{ count = 6, effectId = "RazDeMaree", params = { hpMaxPct = 0.12, slowTurns = 1 } },
		},
	},
	Cielo = {
		kind = "family",
		members = { "bombardiro-crocodilo", "bombombini-gusini", "bombardiere-lucertola" },
		tiers = {
			{ count = 2, effectId = "Volants", params = {} },
			{ count = 3, effectId = "Escadrille", params = { everyActions = 6, atqAvgPct = 0.60 } },
		},
	},
	Caffe = {
		kind = "family",
		members = { "ballerina-cappuccina", "cappuccino-assassino", "espressona-signora" },
		tiers = {
			{ count = 2, effectId = "FlatVIT", params = { VIT = 15 } },
			{ count = 3, effectId = "DoubleShot", params = { perTurn = 1 } },
		},
	},
	Giungla = {
		kind = "family",
		members = {
			"brr-brr-patapim",
			"lirili-larila",
			"cocofanto-elefanto",
			"chimpanzini-bananini",
			"orangutini-ananasini",
			"bobrito-bandito",
			"tim-cheese",
		},
		tiers = {
			{ count = 2, effectId = "StartShield", params = { hpMaxPct = 0.10 } },
			{ count = 4, effectId = "StartShield", params = { hpMaxPct = 0.20 } },
			{
				count = 6,
				effectId = "StartShieldRepousse",
				params = { hpMaxPct = 0.35, reviveHpPct = 0.30 },
			},
		},
	},
	Frutta = {
		kind = "family",
		members = {
			"girafa-celestre",
			"cocofanto-elefanto",
			"chimpanzini-bananini",
			"orangutini-ananasini",
			"tigrrullini-watermellini",
			"glorbo-fruttodrillo",
			"bananita-dolfinita",
			"burbaloni-luliloli",
		},
		tiers = {
			{ count = 2, effectId = "PctATQMAG", params = { pct = 0.10 } },
			{
				count = 4,
				effectId = "PctATQMAGHealTaken",
				params = { pct = 0.20, healTakenPct = 0.15 },
			},
			{
				count = 6,
				effectId = "Macedoine",
				params = { pct = 0.35, healTakenPct = 0.15, splashPct = 0.30 },
			},
		},
	},
	Macchina = {
		kind = "family",
		members = {
			"bombardiro-crocodilo",
			"frigo-camelo",
			"svinino-bombondino",
			"talpa-di-ferro",
			"bombardiere-lucertola",
			"boneca-ambalabu",
		},
		tiers = {
			{ count = 2, effectId = "FlatDEFRES", params = { amount = 20 } },
			{
				count = 4,
				effectId = "FlatDEFRESSurchauffe",
				params = { amount = 40, explodeHpMaxPct = 0.10 },
			},
		},
	},
	Cosmo = {
		kind = "family",
		members = { "la-vacca-saturno-saturnita", "girafa-celestre", "lirili-larila" },
		tiers = {
			{ count = 2, effectId = "PushFastestEnemy", params = { timelinePct = 0.20 } },
			{
				count = 3,
				effectId = "PushAllEnemiesFlatMAG",
				params = { timelinePct = 0.20, MAG = 20 },
			},
		},
	},
	Sahur = {
		kind = "family",
		members = { "tung-tung-tung-sahur", "ta-ta-ta-ta-sahur" },
		tiers = {
			{ count = 2, effectId = "ReveilALAube", params = { sleepTargets = 2, turns = 1 } },
		},
	},
	Tentafruit = {
		kind = "family",
		members = {
			"poirita",
			"fraisio",
			"fraisita",
			"banano",
			"bananella",
			"pomito",
			"pomita",
			"myrtilo",
			"myrtila",
			"cerisa",
			"litchita",
			"kiwina",
			"pasteco",
			"citronello",
		},
		tiers = {
			{ count = 2, effectId = "EnergyGainPct", params = { pct = 0.15 } },
			{
				count = 4,
				effectId = "Ceremonie",
				params = { everyActions = 6, statPct = 0.20, turns = 2 },
			},
			{ count = 6, effectId = "PrimeTime", params = { megaGainMult = 1.5 } },
		},
	},
	Couple = {
		kind = "subrole",
		members = {
			"fraisio",
			"fraisita",
			"banano",
			"bananella",
			"pomito",
			"pomita",
			"myrtilo",
			"myrtila",
		},
		tiers = {
			{ count = 1, effectId = "LienDAmour", params = { energyOnPartnerHit = 10 } },
			{ count = 2, effectId = "CouplePctHP", params = { pct = 0.15 } },
			{ count = 3, effectId = "CoupleDeLAnnee", params = {} },
		},
	},
	Tentation = {
		kind = "subrole",
		members = { "cerisa", "litchita", "kiwina", "pasteco", "citronello" },
		tiers = {
			{ count = 1, effectId = "CharmeChance", params = { chance = 0.15 } },
			{ count = 2, effectId = "CharmeChance", params = { chance = 0.25 } },
			{
				count = 3,
				effectId = "CharmeChanceExpose",
				params = { chance = 0.35, damagePct = 0.20 },
			},
		},
	},
	Colosse = {
		kind = "class",
		members = {
			"brr-brr-patapim",
			"la-vacca-saturno-saturnita",
			"cocofanto-elefanto",
			"frigo-camelo",
			"glorbo-fruttodrillo",
			"boneca-ambalabu",
			"banano",
			"pasteco",
		},
		tiers = {
			{ count = 2, effectId = "ColossePctHP", params = { pct = 0.20 } },
			{ count = 4, effectId = "ColossePctHPTeam", params = { pct = 0.40, teamPct = 0.10 } },
			{
				count = 6,
				effectId = "ColossePctHPTeamTaunt",
				params = { pct = 0.60, teamPct = 0.10, extraTauntTurns = 1 },
			},
		},
	},
	Guerrier = {
		kind = "class",
		members = {
			"tung-tung-tung-sahur",
			"chimpanzini-bananini",
			"orangutini-ananasini",
			"tigrrullini-watermellini",
			"fraisio",
			"pomito",
		},
		tiers = {
			{ count = 2, effectId = "Lifesteal", params = { pct = 0.10 } },
			{ count = 4, effectId = "LifestealATQ", params = { pct = 0.20, atqPct = 0.15 } },
		},
	},
	Assassin = {
		kind = "class",
		members = { "cappuccino-assassino", "talpa-di-ferro", "cerisa", "trippi-troppi" },
		tiers = {
			{ count = 2, effectId = "CritBonus", params = { chance = 0.15, mult = 1.75 } },
			{ count = 3, effectId = "CritBonusFirstHit", params = { chance = 0.30, mult = 1.75 } },
		},
	},
	Artilleur = {
		kind = "class",
		members = {
			"bombardiro-crocodilo",
			"girafa-celestre",
			"svinino-bombondino",
			"bombardiere-lucertola",
			"bobrito-bandito",
			"bananella",
			"myrtilo",
		},
		tiers = {
			{ count = 2, effectId = "AoePct", params = { pct = 0.15 } },
			{ count = 4, effectId = "AoePctSplash", params = { pct = 0.30, splashPct = 0.40 } },
		},
	},
	Soigneur = {
		kind = "class",
		members = {
			"espressona-signora",
			"bananita-dolfinita",
			"burbaloni-luliloli",
			"pomita",
			"myrtila",
		},
		tiers = {
			{ count = 2, effectId = "HealPct", params = { pct = 0.20 } },
			{ count = 3, effectId = "HealPctOverheal", params = { pct = 0.40 } },
		},
	},
	Mage = {
		kind = "class",
		members = {
			"ballerina-cappuccina",
			"poirita",
			"lirili-larila",
			"chef-crabracadabra",
			"citronello",
			"litchita",
			"fraisita",
			"ta-ta-ta-ta-sahur",
		},
		tiers = {
			{ count = 2, effectId = "FlatMAG", params = { MAG = 20 } },
			{
				count = 4,
				effectId = "FlatMAGCheapSkills",
				params = { MAG = 40, skillCostPct = -0.15 },
			},
		},
	},
	Sprinteur = {
		kind = "class",
		members = { "tralalero-tralala", "bombombini-gusini", "tim-cheese", "kiwina" },
		tiers = {
			{ count = 2, effectId = "FlatVIT", params = { VIT = 20 } },
			{ count = 3, effectId = "FlatVITReplay", params = { VIT = 35, replayChance = 0.15 } },
		},
	},
}

local FAMILY_ORDER =
	{ "Mare", "Cielo", "Caffe", "Giungla", "Frutta", "Macchina", "Cosmo", "Sahur", "Tentafruit" }
local CLASS_ORDER =
	{ "Colosse", "Guerrier", "Assassin", "Artilleur", "Soigneur", "Mage", "Sprinteur" }

return table.freeze({
	byName = Synergies,
	familyOrder = FAMILY_ORDER,
	classOrder = CLASS_ORDER,
	tierColors = { "bronze", "argent", "or", "prisme" },
})
