--!strict
-- Mesure T-0023 : taux de victoire par unite M1 sur des combats aleatoires entre equipes de 3 a 5 unites M1
-- distinctes de meme taille (tactique Equilibre, 1 etoile). Inactif par defaut (0 test). Usage :
--   COMBAT_SIM_M1=2000 lune run tests/run.luau sim/UnitWinRates

local process = require("@lune/process")
local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")
local Rng = loadShared("Combat/Rng")

local COUNT = tonumber(process.env.COMBAT_SIM_M1)

type Member = { slug: string, row: number, col: number, stars: number, tactic: string }

local function randomTeam(rng, size: number): { Member }
	local pool = table.clone(Config.Skills.m1Slugs) :: { string }
	local cells = {}
	for cell = 0, 7 do
		table.insert(cells, cell)
	end
	local team: { Member } = {}
	for _ = 1, size do
		local slug = table.remove(pool, rng:NextInteger(1, #pool)) :: string
		local cell = table.remove(cells, rng:NextInteger(1, #cells)) :: number
		table.insert(team, {
			slug = slug,
			row = cell // 4 + 1,
			col = cell % 4 + 1,
			stars = 1,
			tactic = "Equilibre",
		})
	end
	return team
end

if COUNT then
	describe("T-0023 : taux de victoire par unite M1", function()
		it(`{COUNT} combats aleatoires M1`, function()
			local rng = Rng.new(20261002)
			local played: { [string]: number } = {}
			local won: { [string]: number } = {}
			local skillUses: { [string]: number } = {}
			local draws = 0
			for seed = 1, COUNT do
				local size = rng:NextInteger(3, 5)
				local teamA, teamB = randomTeam(rng, size), randomTeam(rng, size)
				local result = CombatSim.simulate(seed, teamA, teamB, Config)
				if result.winner == "draw" then
					draws += 1
				end
				for _, entry in result.actionLog do
					if entry.action == "Skill" then
						local slug = string.match(entry.actor, "^(.-)%.[AB]%d+$") or entry.actor
						skillUses[slug] = (skillUses[slug] or 0) + 1
					end
				end
				for side, team in { A = teamA, B = teamB } do
					for _, member in team do
						played[member.slug] = (played[member.slug] or 0) + 1
						if result.winner == side then
							won[member.slug] = (won[member.slug] or 0) + 1
						end
					end
				end
			end
			print(
				`  {COUNT} combats, nuls {draws} ({string.format("%.1f", 100 * draws / COUNT)} %)`
			)
			for _, slug in Config.Skills.m1Slugs do
				local n = played[slug] or 0
				print(
					`  {slug} : {n} combats, victoires {string.format(
						"%.1f",
						100 * (won[slug] or 0) / n
					)} %, competences {string.format("%.2f", (skillUses[slug] or 0) / n)} / combat`
				)
			end
			expect(draws <= COUNT).toBe(true)
		end)
	end)
end
