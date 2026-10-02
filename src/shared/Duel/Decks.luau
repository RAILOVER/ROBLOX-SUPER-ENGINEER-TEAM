--!strict
-- Deck fixe M1 et troupes PvE (spec M1-duel-minimal §3.1 D-M1-01, D-M1-06, §4). Module pur.

local Types = require(script.Parent.Parent.Types.Duel)

type UnitInstance = Types.UnitInstance

local Decks = {}

-- D-M1-01 : 8 Communes + 2 Rares, aucun Champion. Ordre = tableau §4 de la spec.
Decks.M1 = table.freeze({
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
})

-- D-M1-06 : troupes neutres des manches PvE. Ligne avant = row 1.
local PVE: { [number]: { UnitInstance } } = {
	[1] = {
		{ slug = "tim-cheese", row = 1, col = 1, stars = 1 },
		{ slug = "tim-cheese", row = 1, col = 2, stars = 1 },
		{ slug = "tim-cheese", row = 1, col = 3, stars = 1 },
	},
	[6] = {
		{ slug = "glorbo-fruttodrillo", row = 1, col = 2, stars = 1 },
		{ slug = "glorbo-fruttodrillo", row = 1, col = 3, stars = 1 },
		{ slug = "trippi-troppi", row = 2, col = 2, stars = 1 },
		{ slug = "trippi-troppi", row = 2, col = 3, stars = 1 },
	},
	[11] = {
		{ slug = "boneca-ambalabu", row = 1, col = 2, stars = 2 },
		{ slug = "boneca-ambalabu", row = 1, col = 3, stars = 2 },
		{ slug = "bananella", row = 2, col = 1, stars = 2 },
		{ slug = "bananella", row = 2, col = 4, stars = 2 },
		{ slug = "pomita", row = 2, col = 2, stars = 2 },
	},
}

-- Troupe PvE de la manche, nil si la manche est PvP. Au-dela de la manche 11, la derniere troupe est rejouee.
function Decks.pveTeam(pveRounds: { number }, round: number): { UnitInstance }?
	if table.find(pveRounds, round) == nil then
		return nil
	end
	local team = PVE[round]
	if team == nil then
		team = PVE[11]
	end
	local copy: { UnitInstance } = {}
	for _, unit in team do
		table.insert(copy, table.clone(unit))
	end
	return copy
end

return table.freeze(Decks)
