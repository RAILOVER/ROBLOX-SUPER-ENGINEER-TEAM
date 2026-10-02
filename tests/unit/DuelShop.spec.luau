--!strict
-- Boutique du duel (spec M1-duel-minimal D-M1-01, D-M1-02, D-M1-08, D-M1-10). Pur, Lune.

local Config = loadShared("Config")
local Decks = loadShared("Duel/Decks")
local Shop = loadShared("Duel/Shop")
local Seat = loadShared("Duel/Seat")
local Rng = loadShared("Combat/Rng")

-- Deck de test avec les 5 couts (2 cartes par rarete) pour mesurer les odds sans repli.
local function fullDeck(): { string }
	local byRarity: { [string]: { string } } = {}
	for slug, def in Config.Roster.units do
		byRarity[def.rarity] = byRarity[def.rarity] or {}
		table.insert(byRarity[def.rarity], slug)
	end
	local deck = {}
	for _, rarity in Config.Rarities.order do
		table.sort(byRarity[rarity])
		table.insert(deck, byRarity[rarity][1])
		table.insert(deck, byRarity[rarity][2])
	end
	return deck
end

local function newSeat(seed: number)
	return Seat.new(Config, 1, "human", 1, "test", Decks.M1, seed)
end

describe("Shop : pool (D-M1-01)", function()
	it("deck M1 = 8 Communes x 18 + 2 Rares x 15 = 174 exemplaires", function()
		local pool = Shop.newPool(Config, Decks.M1)
		expect(Shop.poolTotal(pool)).toBe(174)
		expect(pool["banano"]).toBe(18)
		expect(pool["glorbo-fruttodrillo"]).toBe(15)
	end)

	it("retire les copies au tirage, les remet a la relance, jamais negatif", function()
		local pool = Shop.newPool(Config, Decks.M1)
		local rng = Rng.new(3)
		local slots = Shop.roll(Config, rng, pool, 2)
		expect(#slots).toBe(5)
		expect(Shop.poolTotal(pool)).toBe(169)
		slots[1].sold = true
		Shop.returnUnsold(pool, slots)
		expect(Shop.poolTotal(pool)).toBe(173)
		for _ = 1, 200 do
			local more = Shop.roll(Config, rng, pool, 8)
			for _, slot in more do
				if slot.slug ~= Shop.EMPTY_SLUG then
					expect(pool[slot.slug] >= 0).toBe(true)
				end
			end
		end
		-- 1 000 cartes demandees pour 173 disponibles : le pool est vide, pas negatif
		expect(Shop.poolTotal(pool)).toBe(0)
		local empty = Shop.roll(Config, rng, pool, 8)
		expect(empty[1].slug).toBe(Shop.EMPTY_SLUG)
		expect(empty[1].sold).toBe(true)
	end)
end)

describe("Shop : odds par niveau (D-M1-08)", function()
	it("100 000 tirages par niveau : ecart < 1 point par cout", function()
		local deck = fullDeck()
		for level = 2, 8 do
			local pool = Shop.newPool(Config, deck)
			local rng = Rng.new(100 + level)
			local counts = { 0, 0, 0, 0, 0 }
			local draws = 0
			while draws < 100000 do
				local slots = Shop.roll(Config, rng, pool, level)
				for _, slot in slots do
					counts[slot.cost] += 1
					draws += 1
				end
				Shop.returnUnsold(pool, slots)
			end
			for cost = 1, 5 do
				local share = counts[cost] / draws
				local wanted = Config.Duel.shopOdds[level][cost]
				expect(math.abs(share - wanted) < 0.01).toBe(true)
			end
		end
	end)

	it(
		"niveau 8, deck M1 : part de cartes a 2 or = 0,85 (plus ou moins 0,02) par repli (D-M1-02)",
		function()
			local pool = Shop.newPool(Config, Decks.M1)
			local rng = Rng.new(8)
			local twos, draws = 0, 0
			while draws < 10000 do
				local slots = Shop.roll(Config, rng, pool, 8)
				for _, slot in slots do
					draws += 1
					if slot.cost == 2 then
						twos += 1
					end
					expect(slot.cost == 1 or slot.cost == 2).toBe(true)
				end
				Shop.returnUnsold(pool, slots)
			end
			expect(math.abs(twos / draws - 0.85) <= 0.02).toBe(true)
		end
	)

	it("repli : cout le plus proche en dessous, sinon au-dessus, nil si vide", function()
		expect(Shop.fallbackCost(4, { [1] = true, [2] = true })).toBe(2)
		expect(Shop.fallbackCost(2, { [2] = true })).toBe(2)
		expect(Shop.fallbackCost(1, { [3] = true })).toBe(3)
		expect(Shop.fallbackCost(3, {})).toBeNil()
	end)

	it("tirage deterministe a seed egale", function()
		local a = Shop.roll(Config, Rng.new(42), Shop.newPool(Config, Decks.M1), 5)
		local b = Shop.roll(Config, Rng.new(42), Shop.newPool(Config, Decks.M1), 5)
		for index, slot in a do
			expect(b[index].slug).toBe(slot.slug)
		end
	end)
end)

describe("Shop : fusion et vente (D-M1-10)", function()
	local function giveShop(seat, slugs: { string })
		seat.shop = {}
		for _, slug in slugs do
			table.insert(seat.shop, { slug = slug, cost = 1, sold = false })
		end
	end

	it("3 exemplaires 1 etoile = 1 exemplaire 2 etoiles, 3 x 2 etoiles = 3 etoiles", function()
		local seat = newSeat(1)
		seat.gold = 20
		giveShop(seat, { "banano", "banano", "banano", "banano", "banano" })
		for slot = 1, 3 do
			expect(Seat.buy(Config, seat, slot).ok).toBe(true)
		end
		expect(#seat.bench).toBe(1)
		expect(seat.bench[1].stars).toBe(2)
		expect(seat.gold).toBe(17)
		for _ = 1, 2 do
			giveShop(seat, { "banano", "banano", "banano" })
			for slot = 1, 3 do
				expect(Seat.buy(Config, seat, slot).ok).toBe(true)
			end
		end
		expect(#seat.bench).toBe(1)
		expect(seat.bench[1].stars).toBe(3)
	end)

	it(
		"fusion sur le plateau : la case de l'unite du plateau est gardee, le banc se libere (spec §6)",
		function()
			local seat = newSeat(2)
			seat.gold = 20
			seat.level = 3
			giveShop(seat, { "pomito", "pomito", "banano", "banano", "pomito" })
			for slot = 1, 4 do
				expect(Seat.buy(Config, seat, slot).ok).toBe(true)
			end
			expect(Seat.place(Config, seat, seat.bench[1].instanceId, 1, 2).ok).toBe(true)
			expect(Seat.buy(Config, seat, 5).ok).toBe(true)
			expect(#seat.board).toBe(1)
			expect(seat.board[1].slug).toBe("pomito")
			expect(seat.board[1].stars).toBe(2)
			expect(seat.board[1].row).toBe(1)
			expect(seat.board[1].col).toBe(2)
			expect(#seat.bench).toBe(2)
		end
	)

	it("banc plein : 7e achat refuse, or inchange, sauf si la carte complete une fusion", function()
		local seat = newSeat(3)
		seat.gold = 30
		giveShop(seat, { "banano", "banano", "pomito", "pomita", "myrtila" })
		for slot = 1, 5 do
			expect(Seat.buy(Config, seat, slot).ok).toBe(true)
		end
		giveShop(seat, { "tim-cheese", "trippi-troppi", "banano" })
		expect(Seat.buy(Config, seat, 1).ok).toBe(true)
		expect(#seat.bench).toBe(6)
		local gold = seat.gold
		local refused = Seat.buy(Config, seat, 2)
		expect(refused.ok).toBe(false)
		expect(refused.reason).toBe("bench_full")
		expect(seat.gold).toBe(gold)
		expect(Seat.buy(Config, seat, 3).ok).toBe(true)
		expect(#seat.bench).toBe(5)
	end)

	it("vente : or rendu selon les etoiles et copies rendues au pool", function()
		local seat = newSeat(4)
		seat.gold = 10
		local before = seat.pool["glorbo-fruttodrillo"]
		giveShop(seat, { "glorbo-fruttodrillo", "glorbo-fruttodrillo", "glorbo-fruttodrillo" })
		seat.pool["glorbo-fruttodrillo"] -= 3
		for slot = 1, 3 do
			seat.shop[slot].cost = 2
			expect(Seat.buy(Config, seat, slot).ok).toBe(true)
		end
		expect(seat.gold).toBe(4)
		expect(Seat.sell(Config, seat, seat.bench[1].instanceId).ok).toBe(true)
		expect(seat.gold).toBe(9)
		expect(#seat.bench).toBe(0)
		expect(seat.pool["glorbo-fruttodrillo"]).toBe(before)
	end)

	it("relance : 2 or, nouvelle boutique, refus sans or", function()
		local seat = newSeat(5)
		seat.gold = 3
		Seat.rollShop(Config, seat)
		expect(Seat.reroll(Config, seat).ok).toBe(true)
		expect(seat.gold).toBe(1)
		expect(Seat.reroll(Config, seat).ok).toBe(false)
		expect(seat.gold).toBe(1)
		expect(Shop.poolTotal(seat.pool)).toBe(169)
	end)
end)
