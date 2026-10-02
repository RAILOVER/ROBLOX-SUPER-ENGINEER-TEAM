--!strict
-- Oeufs (brief §13.2 a §13.4). Module pur, sans require. Les probabilites sont AFFICHEES avant tout achat (R8).
-- Contenu pour l'Arene 1; multiplie par (1 + 0.15 x (arene - 1)) puis arrondi. hatchSeconds = temps d'eclosion.

export type EggDef = {
	hatchSeconds: number,
	cards: number,
	gold: { number },
	guarantees: { [string]: number },
	source: { string },
}

local Eggs: { [string]: EggDef } = {
	Bois = {
		hatchSeconds = 5,
		cards = 3,
		gold = { 10, 10 },
		guarantees = {},
		source = { "tutoriel" },
	},
	Argent = {
		hatchSeconds = 3 * 3600,
		cards = 12,
		gold = { 40, 60 },
		guarantees = {},
		source = { "cycle" },
	},
	Or = {
		hatchSeconds = 8 * 3600,
		cards = 36,
		gold = { 130, 170 },
		guarantees = { Rare = 1 },
		source = { "cycle", "defi" },
	},
	Magique = {
		hatchSeconds = 12 * 3600,
		cards = 100,
		gold = { 400, 500 },
		guarantees = { Rare = 4, Epique = 2 },
		source = { "cycle", "histoire" },
	},
	Geant = {
		hatchSeconds = 12 * 3600,
		cards = 250,
		gold = { 900, 1100 },
		guarantees = { Rare = 25 },
		source = { "cycle" },
	},
	Epique = {
		hatchSeconds = 12 * 3600,
		cards = 15,
		gold = { 0, 0 },
		guarantees = { Epique = 15 },
		source = { "cycle", "boutique" },
	},
}

-- Cycle de 240 oeufs tire une fois par compte avec une graine (§13.3).
local CYCLE = { Argent = 180, Or = 52, Magique = 4, Geant = 2, Epique = 1, Legendaire = 1 }

-- Arene a partir de laquelle chaque rarete peut tomber d'un oeuf (§7.2 : Champions des l'Arene 6).
local RARITY_UNLOCK_ARENA = { Commune = 0, Rare = 1, Epique = 2, Legendaire = 4, Champion = 6 }

return table.freeze({
	byName = Eggs,
	cycle = CYCLE,
	cycleLength = 240,
	arenaContentMultiplier = 0.15,
	rarityUnlockArena = RARITY_UNLOCK_ARENA,
	speedUpGemPer10Minutes = 1,
})
