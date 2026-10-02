--!strict
-- Progression des cartes (brief §7.1) : Stat(niv) = Stat_ref x 1.10^(niv - 11). Module pur, sans require.

local Progression = {
	maxLevel = 16,
	referenceLevel = 11,
	statGrowthPerLevel = 1.10,
	copyDivisor = 1, -- seul levier autorise sur le bareme d'exemplaires
	goldToReach = {
		[2] = 5,
		[3] = 20,
		[4] = 50,
		[5] = 150,
		[6] = 400,
		[7] = 1000,
		[8] = 2000,
		[9] = 4000,
		[10] = 8000,
		[11] = 20000,
		[12] = 25000,
		[13] = 40000,
		[14] = 60000,
		[15] = 90000,
		[16] = 120000,
	},
	copiesToReach = {
		Commune = {
			[2] = 2,
			[3] = 4,
			[4] = 10,
			[5] = 20,
			[6] = 50,
			[7] = 100,
			[8] = 200,
			[9] = 400,
			[10] = 800,
			[11] = 1000,
			[12] = 1500,
			[13] = 2500,
			[14] = 3500,
			[15] = 5500,
			[16] = 7500,
		},
		Rare = {
			[4] = 2,
			[5] = 4,
			[6] = 10,
			[7] = 20,
			[8] = 50,
			[9] = 100,
			[10] = 200,
			[11] = 300,
			[12] = 400,
			[13] = 550,
			[14] = 750,
			[15] = 1000,
			[16] = 1400,
		},
		Epique = {
			[7] = 2,
			[8] = 4,
			[9] = 10,
			[10] = 20,
			[11] = 30,
			[12] = 50,
			[13] = 70,
			[14] = 100,
			[15] = 130,
			[16] = 180,
		},
		Legendaire = { [10] = 2, [11] = 4, [12] = 6, [13] = 9, [14] = 12, [15] = 14, [16] = 20 },
		Champion = { [12] = 2, [13] = 5, [14] = 8, [15] = 11, [16] = 15 },
	},
	surplusToGold = { Commune = 5, Rare = 50, Epique = 500, Legendaire = 10000, Champion = 20000 },
	-- Etoiles du duel (§10.4) : 3 exemplaires 1★ -> 2★ (x1.8 PV/ATQ/MAG), 3 x 2★ -> 3★ (x3.24).
	starMultipliers = { [1] = 1.0, [2] = 1.8, [3] = 3.24 },
}

function Progression.statAtLevel(statRef: number, level: number): number
	return statRef * Progression.statGrowthPerLevel ^ (level - Progression.referenceLevel)
end

return table.freeze(Progression)
