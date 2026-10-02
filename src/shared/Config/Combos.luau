--!strict
-- Mega Combos (brief §9). Module pur, sans require. `requires` : all = tous vivants et en jeu; anyPair = un couple
-- complet; count = N unites d'une famille. mvp = obligatoire au jalon M3; C05 et C01 servent de placeholder au M1.

export type ComboDef = {
	name: string,
	requires: { all: { string }?, anyPair: { { string } }?, counts: { [string]: number }? },
	effectId: string,
	params: { [string]: number },
	cinematic: { long: string, short: string, variantByPair: boolean? },
	mvp: boolean,
}

local Combos: { [string]: ComboDef } = {
	C01 = {
		name = "Trio Originale",
		requires = { all = { "tralalero-tralala", "tung-tung-tung-sahur", "bombardiro-crocodilo" } },
		effectId = "DamageAllStun",
		params = { atqAvgPct = 2.5, stunTurns = 1 },
		cinematic = { long = "C01_long", short = "C01_short" },
		mvp = true,
	},
	C02 = {
		name = "Escadrille Bombardini",
		requires = { all = { "bombardiro-crocodilo", "bombombini-gusini" } },
		effectId = "DamageBacklineBurn",
		params = { atqPct = 1.8, bonusWithLucertola = 1.3 },
		cinematic = { long = "C02_long", short = "C02_short" },
		mvp = true,
	},
	C03 = {
		name = "Coppia Caffe",
		requires = { all = { "ballerina-cappuccina", "cappuccino-assassino" } },
		effectId = "StrongestTargetReplay",
		params = { atqPct = 3.0, hits = 6 },
		cinematic = { long = "C03_long", short = "C03_short" },
		mvp = false,
	},
	C04 = {
		name = "Sorelle Caffe",
		requires = { all = { "ballerina-cappuccina", "espressona-signora" } },
		effectId = "TeamHealSpeed",
		params = { healPct = 0.40, VIT = 20, turns = 3 },
		cinematic = { long = "C04_long", short = "C04_short" },
		mvp = false,
	},
	C05 = {
		name = "Declaration d'amour",
		requires = {
			anyPair = {
				{ "fraisio", "fraisita" },
				{ "banano", "bananella" },
				{ "pomito", "pomita" },
				{ "myrtilo", "myrtila" },
			},
		},
		effectId = "CoupleStrike",
		params = { shieldPct = 0.30, healPct = 0.25, atqPct = 2.0 },
		cinematic = { long = "C05_long", short = "C05_short", variantByPair = true },
		mvp = true,
	},
	C06 = {
		name = "Ceremonie de la villa",
		requires = { all = { "poirita" }, counts = { Tentation = 2 } },
		effectId = "BanishStrongestCharm",
		params = { banishTurns = 3, charmTargets = 2, charmTurns = 1 },
		cinematic = { long = "C06_long", short = "C06_short" },
		mvp = false,
	},
	C07 = {
		name = "Il Tempo si Ferma",
		requires = { all = { "lirili-larila", "la-vacca-saturno-saturnita", "girafa-celestre" } },
		effectId = "TimeStop",
		params = { allyTurns = 2 },
		cinematic = { long = "C07_long", short = "C07_short" },
		mvp = true,
	},
	C08 = {
		name = "Macedonia",
		requires = { counts = { Frutta = 3, Tentafruit = 2 } },
		effectId = "TeamHealAoeMag",
		params = { healPct = 0.30, magPct = 1.5 },
		cinematic = { long = "C08_long", short = "C08_short" },
		mvp = false,
	},
	C09 = {
		name = "Giungla Indistruttibile",
		requires = { all = { "chimpanzini-bananini", "brr-brr-patapim", "cocofanto-elefanto" } },
		effectId = "FrontlineDamageTeamShield",
		params = { atqPct = 2.2, shieldPct = 0.20 },
		cinematic = { long = "C09_long", short = "C09_short" },
		mvp = false,
	},
	C10 = {
		name = "Sahur all'alba",
		requires = { all = { "tung-tung-tung-sahur", "ta-ta-ta-ta-sahur" } },
		effectId = "SleepAllEnergy",
		params = { sleepTurns = 1, energy = 40 },
		cinematic = { long = "C10_long", short = "C10_short" },
		mvp = true,
	},
	C11 = {
		name = "Officina Kaboom",
		requires = { all = { "svinino-bombondino", "talpa-di-ferro", "frigo-camelo" } },
		effectId = "DamageAllSlow",
		params = { atqPct = 2.0, slowTurns = 2 },
		cinematic = { long = "C11_long", short = "C11_short" },
		mvp = false,
	},
	C12 = {
		name = "Festa al Mare",
		requires = { all = { "tralalero-tralala", "trippi-troppi", "bananita-dolfinita" } },
		effectId = "DamageAllHealFamily",
		params = { atqPct = 1.6, healPct = 0.20 },
		cinematic = { long = "C12_long", short = "C12_short" },
		mvp = false,
	},
	C13 = {
		name = "Triangle de la Tentafruit",
		requires = { all = { "fraisio", "fraisita", "cerisa" } },
		effectId = "SingleTargetSelfStun",
		params = { atqPct = 2.5, selfStunTurns = 1 },
		cinematic = { long = "C13_long", short = "C13_short" },
		mvp = false,
	},
}

return table.freeze({
	byId = Combos,
	cinematicLongSeconds = { 4, 6 },
	cinematicShortMaxSeconds = 2.5,
	autoTriggerAfterSecondsPvp = 8,
})
