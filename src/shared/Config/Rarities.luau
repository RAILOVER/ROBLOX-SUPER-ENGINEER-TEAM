--!strict
-- Raretes (brief §7.1). Module pur, sans require : charge par Roblox et par Lune.
-- startLevel = niveau d'une carte neuve, duelCost = cout en or dans la boutique du duel,
-- poolCopies = exemplaires dans le pool du duel, statCoef = coefficient de puissance (§7.3), deckLimit = max par deck.

export type RarityDef = {
	startLevel: number,
	duelCost: number,
	poolCopies: number,
	color: string,
	icon: string,
	deckLimit: number?,
	statCoef: number,
}

local Rarities: { [string]: RarityDef } = {
	Commune = {
		startLevel = 1,
		duelCost = 1,
		poolCopies = 18,
		color = "#8FA6C1",
		icon = "circle",
		statCoef = 1.00,
	},
	Rare = {
		startLevel = 3,
		duelCost = 2,
		poolCopies = 15,
		color = "#F28C28",
		icon = "diamond",
		statCoef = 1.10,
	},
	Epique = {
		startLevel = 6,
		duelCost = 3,
		poolCopies = 12,
		color = "#A44CF2",
		icon = "star",
		statCoef = 1.22,
	},
	Legendaire = {
		startLevel = 9,
		duelCost = 4,
		poolCopies = 10,
		color = "RAINBOW",
		icon = "hexagon",
		statCoef = 1.36,
	},
	Champion = {
		startLevel = 11,
		duelCost = 5,
		poolCopies = 9,
		color = "#FFC93C",
		icon = "crown",
		deckLimit = 1,
		statCoef = 1.50,
	},
}

local ORDER = { "Commune", "Rare", "Epique", "Legendaire", "Champion" }

for _, def in Rarities do
	table.freeze(def)
end

return table.freeze({
	byName = table.freeze(Rarities),
	order = table.freeze(ORDER),
})
