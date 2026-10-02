--!strict
-- Economie du duel (spec M1-duel-minimal D-M1-03, D-M1-05, D-M1-07, D-M1-09, D-M1-10, D-M1-16 a D-M1-18). Pur, Lune.

local Config = loadShared("Config")
local Economy = loadShared("Duel/Economy")
local Rng = loadShared("Combat/Rng")

describe("Economy : revenu (D-M1-07)", function()
	it("23 or et serie de 4 victoires = 5 + 2 + 2 + 1 = 10 or", function()
		local income = Economy.income(Config, 23, 4, true)
		expect(income.base).toBe(5)
		expect(income.interest).toBe(2)
		expect(income.streak).toBe(2)
		expect(income.winBonus).toBe(1)
		expect(income.total).toBe(10)
	end)

	it("plafonne les interets a interestMax = 5", function()
		expect(Economy.interest(Config, 49)).toBe(4)
		expect(Economy.interest(Config, 50)).toBe(5)
		expect(Economy.interest(Config, 999)).toBe(5)
		expect(Economy.interest(Config, -7)).toBe(0)
	end)

	it("plafonne le bonus de serie a streak[5] = 3", function()
		expect(Economy.streakBonus(Config, 0)).toBe(0)
		expect(Economy.streakBonus(Config, 1)).toBe(0)
		expect(Economy.streakBonus(Config, 2)).toBe(1)
		expect(Economy.streakBonus(Config, 4)).toBe(2)
		expect(Economy.streakBonus(Config, 5)).toBe(3)
		expect(Economy.streakBonus(Config, 12)).toBe(3)
	end)

	it("compte la serie : meme sens +1, sens oppose 1, nul inchange", function()
		expect(Economy.nextStreak(0, nil, "win")).toBe(1)
		expect(Economy.nextStreak(1, "win", "win")).toBe(2)
		expect(Economy.nextStreak(3, "win", "loss")).toBe(1)
		expect(Economy.nextStreak(3, "loss", "loss")).toBe(4)
		expect(Economy.nextStreak(3, "loss", "draw")).toBe(3)
		expect(Economy.nextStreak(3, "draw", "win")).toBe(1)
	end)
end)

describe("Economy : 1 000 manches simulees", function()
	it("or jamais negatif, interets <= 5, serie coherente, revenu borne", function()
		local rng = Rng.new(1011)
		local gold, streak, last = Config.Duel.economy.startGold, 0, nil
		local maxInterest, maxIncome = 0, 0
		for round = 2, 1001 do
			local roll = rng:NextNumber()
			local outcome = if roll < 0.45 then "win" elseif roll < 0.9 then "loss" else "draw"
			streak = Economy.nextStreak(streak, last, outcome)
			last = outcome
			local income = Economy.income(Config, gold, streak, outcome == "win")
			maxInterest = math.max(maxInterest, income.interest)
			maxIncome = math.max(maxIncome, income.total)
			gold += income.total
			-- depenses aleatoires : relances et XP tant que l'or le permet, achats de 1 a 2 or
			for _ = 1, rng:NextInteger(0, 6) do
				local cost = ({ Economy.rerollCost(Config), Economy.xpCost(Config), 1, 2 })[rng:NextInteger(
					1,
					4
				)]
				if gold >= cost then
					gold -= cost
				end
			end
			expect(gold >= 0).toBe(true)
			expect(streak >= 1 or outcome == "draw").toBe(true)
			expect(income.interest <= Config.Duel.economy.interestMax).toBe(true)
			expect(round > 0).toBe(true)
		end
		expect(maxInterest).toBe(5)
		-- max = 5 base + 5 interets + 3 serie + 1 victoire
		expect(maxIncome <= 14).toBe(true)
	end)

	it(
		"sans aucune action, l'or grimpe avec interets et les 2 XP tombent (cas limite spec §6)",
		function()
			local gold, level, xp = 3, Config.Duel.startLevel, 0
			for round = 2, 4 do
				gold += Economy.income(Config, gold, round - 1, false).total
				level, xp = Economy.addXp(Config, level, xp, Config.Duel.xpPerRound)
			end
			-- 3 -> 8 (5) -> 14 (5 + serie 1) -> 21 (5 + interet 1 + serie 1) : serie de defaites, interets
			expect(gold).toBe(21)
			expect(level).toBe(3)
			expect(xp).toBe(2)
		end
	)
end)

describe("Economy : XP, vente, preparation", function()
	it("monte de niveau selon xpToNext et plafonne a 8 (D-M1-09)", function()
		local level, xp = Economy.addXp(Config, 2, 0, 4)
		expect(level).toBe(3)
		expect(xp).toBe(0)
		level, xp = Economy.addXp(Config, 3, 5, 4)
		expect(level).toBe(4)
		expect(xp).toBe(3)
		level, xp = Economy.addXp(Config, 7, 0, 1000)
		expect(level).toBe(8)
		expect(xp).toBe(0)
		expect(Economy.xpToNext(Config, 8)).toBe(0)
		expect(Economy.xpCost(Config)).toBe(4)
		expect(Economy.rerollCost(Config)).toBe(2)
	end)

	it("prix de vente : 1 etoile = cout, 2 = 3 x cout - 1, 3 = 9 x cout - 1 (D-M1-10)", function()
		expect(Economy.cardCost(Config, "banano")).toBe(1)
		expect(Economy.cardCost(Config, "glorbo-fruttodrillo")).toBe(2)
		expect(Economy.sellValue(Config, "banano", 1)).toBe(1)
		expect(Economy.sellValue(Config, "banano", 2)).toBe(2)
		expect(Economy.sellValue(Config, "banano", 3)).toBe(8)
		expect(Economy.sellValue(Config, "glorbo-fruttodrillo", 2)).toBe(5)
		expect(Economy.sellValue(Config, "glorbo-fruttodrillo", 3)).toBe(17)
	end)

	it(
		"duree de Preparation : 20 s manches 1 a 3, 30 s ensuite, 3 s si les 2 prets (D-M1-05)",
		function()
			expect(Economy.prepSeconds(Config, 1, false)).toBe(20)
			expect(Economy.prepSeconds(Config, 3, false)).toBe(20)
			expect(Economy.prepSeconds(Config, 4, false)).toBe(30)
			expect(Economy.prepSeconds(Config, 9, true)).toBe(3)
		end
	)
end)

describe("Economy : degats au joueur (D-M1-16 a D-M1-18)", function()
	it("palier = min(ceil(manche / 3), 5)", function()
		expect(Economy.tier(Config, 1)).toBe(1)
		expect(Economy.tier(Config, 3)).toBe(1)
		expect(Economy.tier(Config, 4)).toBe(2)
		expect(Economy.tier(Config, 5)).toBe(2)
		expect(Economy.tier(Config, 15)).toBe(5)
		expect(Economy.tier(Config, 40)).toBe(5)
	end)

	it("manche 5, 3 survivantes 1 etoile = 6 + 8 + 6 = 20 PV", function()
		expect(Economy.playerDamage(Config, 5, 3)).toBe(20)
		expect(Economy.playerDamage(Config, 1, 0)).toBe(10)
		expect(Economy.playerDamage(Config, 2, 8)).toBe(26)
		expect(Economy.playerDamage(Config, 30, 16)).toBe(58)
	end)

	it("manche nulle : floor(degats / 2)", function()
		expect(Economy.drawDamage(Config, 5, 3)).toBe(10)
		expect(Economy.drawDamage(Config, 1, 1)).toBe(6)
		expect(Economy.drawDamage(Config, 1, 0)).toBe(5)
	end)
end)
