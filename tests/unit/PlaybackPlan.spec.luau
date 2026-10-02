--!strict
-- T-0012 : le plan de lecture suit le journal (1 etape par entree, memes PV finaux) et sa duree totale vise
-- 20 a 35 s en moyenne (M-C-04). 100 combats CombatSim.simulate par passe : equipes aleatoires de meme taille
-- (2 a 8, 42 slugs L0, comme le harnais T-0015) puis 10 unites M1 (placements D-M1-29). Les chiffres sont
-- imprimes : si la moyenne sort de la cible, le test echoue et le chiffre est rapporte tel quel.

local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")
local Rng = loadShared("Combat/Rng")
local PlaybackPlan = loadShared("Duel/PlaybackPlan")

local COUNT = 100

local slugs: { string } = {}
for slug in Config.Roster.units do
	table.insert(slugs, slug)
end
table.sort(slugs)

local function randomTeam(rng, size: number, pool: { string})
	local cells = {}
	for cell = 0, 7 do
		table.insert(cells, cell)
	end
	local team = {}
	for _ = 1, size do
		local index = rng:NextInteger(1, #cells)
		local cell = table.remove(cells, index) :: number
		table.insert(team, {
			slug = pool[rng:NextInteger(1, #pool)],
			row = cell // 4 + 1,
			col = cell % 4 + 1,
			stars = rng:NextInteger(1, 3),
		})
	end
	return team
end

local function lastHpOfLog(log): { [string]: number }
	local hp: { [string]: number } = {}
	for _, entry in log do
		for cell, value in entry.hp do
			hp[cell] = value
		end
	end
	return hp
end

local function measure(label: string, pool: { string }, seedBase: number): number
	local rng = Rng.new(seedBase)
	local total, totalActions, minSeconds, maxSeconds = 0, 0, math.huge, 0
	for i = 1, COUNT do
		local size = rng:NextInteger(2, 8)
		local teamA = randomTeam(rng, size, pool)
		local teamB = randomTeam(rng, size, pool)
		local result = CombatSim.simulate(seedBase + i, teamA, teamB, Config)
		local payload = {
			round = 1,
			isPve = false,
			side = "A",
			teams = { A = teamA, B = teamB },
			result = result,
			playerDamage = { 0, 0 },
		}
		local plan = PlaybackPlan.build(Config, payload)
		expect(#plan).toBe(#result.actionLog)
		local expected = lastHpOfLog(result.actionLog)
		local got = PlaybackPlan.finalHp(plan)
		for cell, value in expected do
			expect(got[cell]).toBe(value)
		end
		for cell in got do
			expect(expected[cell] ~= nil).toBe(true)
		end
		for index, step in plan do
			expect(step.t).toBe(result.actionLog[index].t)
			if step.kind == "Mega" then
				expect(step.durationSeconds).toBe(PlaybackPlan.MEGA_SECONDS)
			else
				expect(step.durationSeconds <= Config.Combat.pvpActionAnimationMaxSeconds).toBe(true)
			end
			expect(step.durationSeconds >= PlaybackPlan.MIN_SECONDS).toBe(true)
		end
		local seconds = PlaybackPlan.totalSeconds(plan)
		expect(seconds).toBeCloseTo(plan[#plan].startSeconds + plan[#plan].durationSeconds, 6)
		total += seconds
		totalActions += result.actions
		minSeconds = math.min(minSeconds, seconds)
		maxSeconds = math.max(maxSeconds, seconds)
	end
	local average = total / COUNT
	print(
		`  M-C-04 {label} : {COUNT} combats, {string.format("%.1f", totalActions / COUNT)} actions en moyenne, duree du plan {string.format(
			"%.1f",
			average
		)} s en moyenne (min {string.format("%.1f", minSeconds)}, max {string.format("%.1f", maxSeconds)}) ; a 0,8 s fixe : {string.format(
			"%.1f",
			totalActions / COUNT * Config.Combat.pvpActionAnimationMaxSeconds
		)} s`
	)
	return average
end

describe("PlaybackPlan (T-0012)", function()
	it("decoupe un acteur du journal", function()
		local slug, cell = PlaybackPlan.splitActor("tung-tung-tung-sahur.B7")
		expect(slug).toBe("tung-tung-tung-sahur")
		expect(cell).toBe("B7")
	end)

	it("borne chaque etape et date les etapes bout a bout", function()
		local log = {
			{
				t = 1,
				actor = "banano.A0",
				action = "Attack",
				targets = { "B0" },
				values = { 100 },
				crits = { false },
				statuses = { applied = {}, removed = {} },
				ticks = {},
				gauges = { energy = 40, mega = 0 },
				hp = { B0 = 900 },
				kos = {},
			},
			{
				t = 2,
				actor = "banano.A0",
				action = "Attack",
				targets = { "B0" },
				values = { 100 },
				crits = { false },
				statuses = { applied = {}, removed = {} },
				ticks = {},
				gauges = { energy = 60, mega = 0 },
				hp = { B0 = 800 },
				kos = {},
			},
			{
				t = 3,
				actor = "banano.A0",
				action = "Mega",
				combo = "C05",
				partner = "bananella.A4",
				targets = { "B0" },
				values = { 500 },
				crits = { true },
				statuses = { applied = {}, removed = {} },
				ticks = {},
				gauges = { energy = 60, mega = 0 },
				hp = { B0 = 300 },
				kos = {},
			},
		}
		local plan = PlaybackPlan.fromLog(Config, log)
		expect(#plan).toBe(3)
		expect(plan[1].durationSeconds).toBe(0.6)
		expect(plan[2].durationSeconds).toBeCloseTo(0.42, 6)
		expect(plan[3].durationSeconds).toBe(2.5)
		expect(plan[2].startSeconds).toBe(0.6)
		expect(PlaybackPlan.totalSeconds(plan)).toBeCloseTo(3.52, 6)
		expect(PlaybackPlan.indexAt(plan, 0.7)).toBe(2)
		expect(PlaybackPlan.indexAt(plan, 10)).toBe(4)
		expect(#PlaybackPlan.upcoming(plan, 2, 10)).toBe(2)
		expect(PlaybackPlan.finalHp(plan).B0).toBe(300)
	end)

	it(`{COUNT} combats L0 (tailles egales 2 a 8) : 1 etape par entree, PV finaux identiques, 20 a 35 s`, function()
		local average = measure("L0", slugs, 20261012)
		expect(average).toBeGreaterThanOrEqual(20)
		expect(average).toBeLessThanOrEqual(35)
	end)

	it(`{COUNT} combats M1 (10 unites, tailles egales 2 a 8) : 1 etape par entree, PV finaux identiques, 20 a 35 s`, function()
		local average = measure("M1", Config.Skills.m1Slugs, 20261013)
		expect(average).toBeGreaterThanOrEqual(20)
		expect(average).toBeLessThanOrEqual(35)
	end)
end)
