--!strict
-- M-C-02 et M-C-03 : combats aleatoires (equipes de 1 a 8 unites du roster L0, seed fixe) sans erreur ni depassement
-- de drawAfterActions. 10 000 combats par defaut (10,9 s sous Lune, voir docs/architecture/combat.md) ;
-- COMBAT_SIM_COUNT=1000 pour un passage rapide en local.

local process = require("@lune/process")
local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")
local Rng = loadShared("Combat/Rng")

local COUNT = tonumber(process.env.COMBAT_SIM_COUNT) or 10000

local slugs: { string } = {}
for slug in Config.Roster.units do
	table.insert(slugs, slug)
end
table.sort(slugs)

local function randomTeam(rng)
	local size = rng:NextInteger(1, 8)
	local cells = {}
	for cell = 0, 7 do
		table.insert(cells, cell)
	end
	local team = {}
	for _ = 1, size do
		local index = rng:NextInteger(1, #cells)
		local cell = table.remove(cells, index) :: number
		table.insert(team, {
			slug = slugs[rng:NextInteger(1, #slugs)],
			row = cell // 4 + 1,
			col = cell % 4 + 1,
			stars = rng:NextInteger(1, 3),
		})
	end
	return team
end

describe("CombatSim robustesse (M-C-02, M-C-03)", function()
	it(
		`M-C-02 : {COUNT} combats aleatoires sans erreur, <= 60 actions, part de nuls et duree mesurees`,
		function()
			expect(#slugs).toBe(42)
			local rng = Rng.new(20261002)
			local draws, totalActions, maxActions = 0, 0, 0
			local started = os.clock()
			for i = 1, COUNT do
				local result = CombatSim.simulate(i, randomTeam(rng), randomTeam(rng), Config)
				expect(result.actions <= Config.Combat.drawAfterActions).toBe(true)
				expect(result.actions).toBe(#result.actionLog)
				expect(result.version).toBe(1)
				if result.winner == "draw" then
					draws += 1
				end
				totalActions += result.actions
				maxActions = math.max(maxActions, result.actions)
			end
			local seconds = os.clock() - started
			print(
				`  M-C-02 : {COUNT} combats en {string.format("%.2f", seconds)} s ; nuls {draws} ({string.format(
					"%.2f",
					100 * draws / COUNT
				)} %) ; actions moyennes {string.format("%.1f", totalActions / COUNT)} ; max {maxActions}`
			)
			expect(maxActions).toBeLessThanOrEqual(60)
		end
	)

	it("M-C-03 : les effectId non implementes sont journalises sans erreur", function()
		local result = CombatSim.simulate(5, {
			{ slug = "fraisio", row = 1, col = 1 },
			{ slug = "fraisita", row = 1, col = 2 },
			{ slug = "glorbo-fruttodrillo", row = 1, col = 3 },
		}, {
			{ slug = "boneca-ambalabu", row = 1, col = 1 },
			{ slug = "tim-cheese", row = 2, col = 1 },
		}, Config)
		expect(type(result.unimplemented)).toBe("table")
		expect(result.winner == "A" or result.winner == "B" or result.winner == "draw").toBe(true)
	end)
end)
