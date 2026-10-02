--!strict
-- M-C-01 : determinisme du CombatSim (100 seeds), invariance a la permutation de teamA (R-M1-04), prevision R-M1-09.

local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")
local ActionLog = loadShared("Combat/ActionLog")
local Rng = loadShared("Combat/Rng")

local function unit(slug: string, row: number, col: number)
	return { slug = slug, row = row, col = col }
end

local TEAM_A = {
	unit("banano", 1, 2),
	unit("bananella", 2, 2),
	unit("glorbo-fruttodrillo", 1, 3),
	unit("pomita", 2, 3),
	unit("tim-cheese", 2, 1),
}
local TEAM_B = {
	unit("pomito", 1, 2),
	unit("boneca-ambalabu", 1, 3),
	unit("trippi-troppi", 2, 1),
	unit("ta-ta-ta-ta-sahur", 2, 2),
	unit("myrtila", 2, 3),
}

describe("CombatSim determinisme (M-C-01)", function()
	it(
		"M-C-01 : 100 seeds, 2 simulations identiques donnent le meme ActionLog serialise",
		function()
			for seed = 1, 100 do
				local first = CombatSim.simulate(seed, TEAM_A, TEAM_B, Config)
				local second = CombatSim.simulate(seed, TEAM_A, TEAM_B, Config)
				expect(ActionLog.serialize(first.actionLog)).toBe(
					ActionLog.serialize(second.actionLog)
				)
				expect(first.winner).toBe(second.winner)
				expect(first.turns).toBe(second.turns)
			end
		end
	)

	it("2 seeds differentes donnent des journaux differents", function()
		local a = CombatSim.simulate(1, TEAM_A, TEAM_B, Config)
		local b = CombatSim.simulate(2, TEAM_A, TEAM_B, Config)
		expect(ActionLog.serialize(a.actionLog) == ActionLog.serialize(b.actionLog)).toBe(false)
	end)

	it(
		"permuter l'ordre des unites de teamA ne change pas le journal (tri par case, R-M1-04)",
		function()
			local permuted = { TEAM_A[5], TEAM_A[3], TEAM_A[1], TEAM_A[4], TEAM_A[2] }
			local a = CombatSim.simulate(7, TEAM_A, TEAM_B, Config)
			local b = CombatSim.simulate(7, permuted, TEAM_B, Config)
			expect(ActionLog.serialize(a.actionLog)).toBe(ActionLog.serialize(b.actionLog))
		end
	)

	it("la prevision 1 est toujours l'acteur reel de l'action suivante (R-M1-09)", function()
		local state = CombatSim.newState(11, TEAM_A, TEAM_B, Config)
		local checked = 0
		while state.winner == nil do
			local preview = CombatSim.preview(state, 10)
			expect(#preview).toBe(10)
			local before = #state.log
			CombatSim.step(state)
			local entry = state.log[before + 1]
			if entry.action == "Mega" then
				entry = state.log[before + 2]
			end
			if entry then
				expect(entry.actor).toBe(`{preview[1].slug}.{preview[1].side}{preview[1].cell}`)
				checked += 1
			end
		end
		expect(checked).toBeGreaterThan(10)
	end)

	it("Rng mulberry32 : seedable, borne, reproductible, sans Random.new", function()
		local a, b = Rng.new(123), Rng.new(123)
		for _ = 1, 50 do
			expect(a:NextNumber()).toBe(b:NextNumber())
		end
		local r = Rng.new(2 ^ 32 + 5)
		for _ = 1, 1000 do
			local n = r:NextInteger(3, 7)
			expect(n >= 3 and n <= 7).toBe(true)
			local f = r:NextNumber(0.95, 1.05)
			expect(f >= 0.95 and f < 1.05).toBe(true)
			local u = r:NextNumber()
			expect(u >= 0 and u < 1).toBe(true)
		end
		local seen: { [number]: boolean } = {}
		for _ = 1, 200 do
			seen[Rng.new(99):Clone():NextInteger(0, 9)] = true
		end
		expect(Rng.new(99):NextInteger(0, 9)).toBe(Rng.new(99):NextInteger(0, 9))
	end)
end)
