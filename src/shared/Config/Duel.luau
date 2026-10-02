--!strict
-- Boucle de duel TFT (brief §10). Module pur, sans require.

local Duel = {
	deckSize = 10,
	maxChampionsPerDeck = 1,
	savedDecks = 3,
	playerHp = 100,
	pveRounds = { 1, 6, 11 },
	pveRewardGold = 3,
	prepSecondsEarly = 20, -- manches 1 a prepSecondsEarlyRounds
	prepSecondsEarlyRounds = 3,
	prepReadySkipSeconds = 3, -- les 2 joueurs prets : le combat demarre apres 3 s
	prepSecondsLate = 30,
	economy = {
		startGold = 3,
		baseIncome = 5,
		interestPer = 10,
		interestMax = 5,
		streak = { [2] = 1, [3] = 1, [4] = 2, [5] = 3 }, -- 5 et plus : +3
		winBonus = 1,
		rerollCost = 2,
		xpCost = 4,
		xpPerPurchase = 4,
	},
	startLevel = 2,
	xpPerRound = 2,
	xpToNext = { [2] = 4, [3] = 6, [4] = 10, [5] = 20, [6] = 32, [7] = 48 },
	maxLevel = 8,
	benchSize = 6,
	shopSlots = 5,
	-- probabilites par cout (1 a 5 or) selon le niveau du joueur (§10.5)
	shopOdds = {
		[2] = { 1.00, 0, 0, 0, 0 },
		[3] = { 0.75, 0.25, 0, 0, 0 },
		[4] = { 0.55, 0.30, 0.15, 0, 0 },
		[5] = { 0.45, 0.33, 0.20, 0.02, 0 },
		[6] = { 0.30, 0.40, 0.25, 0.05, 0 },
		[7] = { 0.19, 0.30, 0.35, 0.15, 0.01 },
		[8] = { 0.15, 0.20, 0.35, 0.25, 0.05 },
	},
	-- degats au joueur (§10.7) : base + tierMult * palier + starMult * somme des etoiles survivantes,
	-- palier = ceil(manche / 3) plafonne a tierCap; manche nulle : chaque joueur subit floor(degats / 2).
	-- Valeurs calibrees pour targetRounds par tools/sim_duel_length.py (mediane 10 manches).
	playerDamageBase = 6,
	playerDamageTierMult = 4,
	playerDamageStarMult = 2,
	playerDamageTierCap = 5,
	targetRounds = { 8, 11 },
	ghostAfterSeconds = 15,
	emoteCooldownSeconds = 5,
	-- trophees (§12.3)
	trophies = {
		base = 30,
		divisor = 12,
		min = 20,
		max = 40,
		matchRange = 100,
		widenPer5s = 50,
		leagueThreshold = 3000,
	},
	arenaThresholds = { 0, 300, 600, 1000, 1400, 1800, 2300, 3000 },
	arenaFloors = { true, true, true, true, true, false, false, false },
}

return table.freeze(Duel)
