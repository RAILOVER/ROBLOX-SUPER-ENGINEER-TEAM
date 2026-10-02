--!strict
-- Limites et rythme (brief §13.5). Module pur, sans require. Toutes les fenetres sont calculees cote serveur en UTC.

local Limits = {
	dailyResetUtcHour = 0,
	pvp = { rewardedWinsPerRollingHour = 5, rewardedWinsPerDay = 20, rollingWindowSeconds = 3600 },
	energy = { max = 10, regenMinutes = 12, storyLevelCost = 1, bossCost = 2, gemRefillsPerDay = 2 },
	crownEgg = { crownsRequired = 10, eggsPerDay = 1, crownsPerWin = 1 },
	dailyChallenge = { perDay = 1 },
	eggSlots = { base = 4, withPass = 5, simultaneousHatching = 1 },
	quickDuel = { goldShareOfRanked = 0.5 },
	friendlyDuel = { normalizedLevel = 11 },
}

return table.freeze(Limits)
