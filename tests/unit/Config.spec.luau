--!strict
-- Integrite des tables de configuration BATTLEROT (brief §7, §8, §9, §10, §13). Pur, tourne sous Lune.

local Roster = loadShared("Config").Roster
local Rarities = loadShared("Config").Rarities
local Synergies = loadShared("Config").Synergies
local Combos = loadShared("Config").Combos
local Combat = loadShared("Config").Combat
local Progression = loadShared("Config").Progression
local Duel = loadShared("Config").Duel
local Eggs = loadShared("Config").Eggs

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function contains(list: { string }, value: string): boolean
	return table.find(list, value) ~= nil
end

describe("Roster L0", function()
	it("a 42 personnages : 28 brainrot_it + 14 tentafruit", function()
		local brainrot, fruits = 0, 0
		for _, unit in Roster.units do
			if unit.category == "brainrot_it" then
				brainrot += 1
			elseif unit.category == "tentafruit" then
				fruits += 1
			end
		end
		expect(count(Roster.units)).toBe(42)
		expect(brainrot).toBe(28)
		expect(fruits).toBe(14)
	end)

	it("repartit les raretes 5 / 7 / 9 / 10 / 11", function()
		local byRarity: { [string]: number } = {}
		for _, unit in Roster.units do
			byRarity[unit.rarity] = (byRarity[unit.rarity] or 0) + 1
		end
		expect(byRarity.Champion).toBe(5)
		expect(byRarity.Legendaire).toBe(7)
		expect(byRarity.Epique).toBe(9)
		expect(byRarity.Rare).toBe(10)
		expect(byRarity.Commune).toBe(11)
	end)

	it("n'utilise que des raretes, classes et familles declarees", function()
		for slug, unit in Roster.units do
			expect(Rarities.byName[unit.rarity]).toBeTruthy()
			expect(Combat.classes[unit.class]).toBeTruthy()
			for _, family in unit.families do
				expect(contains(Synergies.familyOrder, family)).toBe(true)
			end
			expect(unit.arena >= 0 and unit.arena <= 8).toBe(true)
			expect(unit.lot).toBe("L0")
			expect(string.match(slug, "^[a-z0-9%-]+$")).toBeTruthy()
		end
	end)

	it("a des couples symetriques", function()
		for slug, unit in Roster.units do
			for _, partner in unit.duoPartners do
				expect(contains(Roster.units[partner].duoPartners, slug)).toBe(true)
			end
		end
	end)
end)

describe("Synergies", function()
	it("ne referencent que des slugs existants et coherents", function()
		for name, synergy in Synergies.byName do
			for _, slug in synergy.members do
				local unit = Roster.units[slug]
				expect(unit).toBeTruthy()
				if synergy.kind == "family" then
					expect(contains(unit.families, name)).toBe(true)
				elseif synergy.kind == "class" then
					expect(unit.class).toBe(name)
				else
					expect(unit.subRole).toBe(name)
				end
			end
		end
	end)

	it("couvrent chaque famille et classe de chaque unite", function()
		for slug, unit in Roster.units do
			for _, family in unit.families do
				expect(contains(Synergies.byName[family].members, slug)).toBe(true)
			end
			expect(contains(Synergies.byName[unit.class].members, slug)).toBe(true)
		end
	end)

	it("ont des paliers strictement croissants", function()
		for _, synergy in Synergies.byName do
			local last = 0
			for _, tier in synergy.tiers do
				expect(tier.count).toBeGreaterThan(last)
				last = tier.count
			end
		end
	end)
end)

describe("Combos", function()
	it("sont 13 et ne citent que des slugs ou familles connus", function()
		expect(count(Combos.byId)).toBe(13)
		for _, combo in Combos.byId do
			for _, slug in combo.requires.all or {} do
				expect(Roster.units[slug]).toBeTruthy()
			end
			for _, pair in combo.requires.anyPair or {} do
				expect(#pair).toBe(2)
				expect(contains(Roster.units[pair[1]].duoPartners, pair[2])).toBe(true)
			end
			for name in combo.requires.counts or {} do
				expect(Synergies.byName[name]).toBeTruthy()
			end
		end
	end)

	it("ont au moins 5 combos MVP", function()
		local mvp = 0
		for _, combo in Combos.byId do
			if combo.mvp then
				mvp += 1
			end
		end
		expect(mvp).toBeGreaterThanOrEqual(5)
	end)
end)

describe("Progression", function()
	it("applique Stat_ref x 1.10^(niv - 11)", function()
		expect(Progression.statAtLevel(1000, 11)).toBeCloseTo(1000, 6)
		expect(Progression.statAtLevel(1000, 12)).toBeCloseTo(1100, 6)
		expect(Progression.statAtLevel(1000, 1)).toBeCloseTo(1000 / 1.1 ^ 10, 6)
	end)

	it("a un bareme d'exemplaires qui demarre au niveau de depart + 1", function()
		for rarity, def in Rarities.byName do
			local copies = Progression.copiesToReach[rarity]
			expect(copies[def.startLevel + 1]).toBeTruthy()
			expect(copies[def.startLevel]).toBeNil()
			expect(copies[Progression.maxLevel]).toBeTruthy()
		end
	end)
end)

describe("Duel", function()
	it("a des probabilites de boutique qui somment a 1 pour chaque niveau", function()
		for level = 2, Duel.maxLevel do
			local sum = 0
			for _, p in Duel.shopOdds[level] do
				sum += p
			end
			expect(sum).toBeCloseTo(1, 6)
		end
	end)
end)

describe("Eggs", function()
	it("a un cycle de 240 oeufs", function()
		local total = 0
		for _, n in Eggs.cycle do
			total += n
		end
		expect(total).toBe(Eggs.cycleLength)
	end)
end)
