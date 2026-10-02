--!strict
-- T-0015 : cas limites de CombatSim releves par la revue docs/reviews/T-0010.md. Chaque test fixe le comportement
-- observe (y compris les comportements a arbitrer, marques "observe") pour qu'un changement soit visible.

local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")
local ActionLog = loadShared("Combat/ActionLog")

local MAX_SEED = 2 ^ 31 - 1
local LIMIT = Config.Combat.drawAfterActions

local function u(slug: string, row: number, col: number, stars: number?, tactic: string?)
	return { slug = slug, row = row, col = col, stars = stars or 1, tactic = tactic or "Equilibre" }
end

local function eight()
	local team = {}
	for i, slug in Config.Skills.m1Slugs do
		if i <= 8 then
			table.insert(team, u(slug, (i - 1) // 4 + 1, (i - 1) % 4 + 1))
		end
	end
	return team
end

local function serialize(seed: number, teamA, teamB): string
	return ActionLog.serialize(CombatSim.simulate(seed, teamA, teamB, Config).actionLog)
end

describe("CombatSim cas limites (T-0015)", function()
	it(
		"1 unite contre 8 : le combat se termine dans les 2 sens, le camp de 8 gagne, log complet",
		function()
			local solo = { u("banano", 1, 1) }
			local r1 = CombatSim.simulate(1, solo, eight(), Config)
			local r2 = CombatSim.simulate(1, eight(), solo, Config)
			expect(r1.winner).toBe("B")
			expect(r2.winner).toBe("A")
			expect(r1.actions <= LIMIT).toBe(true)
			expect(#r1.actionLog).toBe(r1.actions)
			for _, entry in r1.actionLog do
				expect(string.match(entry.actor, "^[%w%-]+%.[AB]%d$") ~= nil).toBe(true)
			end
		end
	)

	it(
		"2 unites identiques dans la meme equipe : acteurs distincts par case, combat miroir termine",
		function()
			local pair = { u("tim-cheese", 1, 1), u("tim-cheese", 1, 2) }
			local result = CombatSim.simulate(3, pair, pair, Config)
			local actors: { [string]: boolean } = {}
			for _, entry in result.actionLog do
				actors[entry.actor] = true
			end
			expect(actors["tim-cheese.A0"]).toBe(true)
			expect(actors["tim-cheese.A1"]).toBe(true)
			expect(actors["tim-cheese.B0"]).toBe(true)
			expect(result.actions <= LIMIT).toBe(true)
		end
	)

	it(
		"unite 3 etoiles : stats x 3,24 (Config.Progression), bat la meme unite a 1 etoile sur 20 seeds",
		function()
			local state = CombatSim.newState(
				1,
				{ u("banano", 1, 1, 3) },
				{ u("banano", 1, 1, 1) },
				Config
			)
			local three, one = state.units[1], state.units[2]
			if three.side ~= "A" then
				three, one = one, three
			end
			expect(three.hpMax).toBe(math.floor(one.hpMax * Config.Progression.starMultipliers[3]))
			local wins = 0
			for seed = 1, 20 do
				if
					CombatSim.simulate(
						seed,
						{ u("banano", 1, 1, 3) },
						{ u("banano", 1, 1, 1) },
						Config
					).winner == "A"
				then
					wins += 1
				end
			end
			expect(wins).toBe(20)
		end
	)

	it("etoiles hors de 1 a 3 : erreur explicite (pas de combat silencieux)", function()
		expect(function()
			CombatSim.simulate(1, { u("banano", 1, 1, 0) }, eight(), Config)
		end).toThrow()
		expect(function()
			CombatSim.simulate(1, { u("banano", 1, 1, 4) }, eight(), Config)
		end).toThrow()
	end)

	it(
		"60 actions : nul avec exactement drawAfterActions entrees et des survivants des 2 cotes",
		function()
			local found = false
			for seed = 1, 200 do
				local state = CombatSim.newState(seed, eight(), eight(), Config)
				while CombatSim.step(state) do
				end
				local result = CombatSim.result(state)
				if result.winner == "draw" then
					found = true
					expect(result.actions).toBe(LIMIT)
					expect(#result.actionLog).toBe(LIMIT)
					expect(result.actionLog[LIMIT].t).toBe(LIMIT)
					local aliveA, aliveB = 0, 0
					for _, unit in state.units do
						if unit.alive then
							if unit.side == "A" then
								aliveA += 1
							else
								aliveB += 1
							end
						end
					end
					expect(aliveA > 0 and aliveB > 0).toBe(true)
					expect(CombatSim.step(state)).toBe(false)
					break
				end
			end
			expect(found).toBe(true)
		end
	)

	it(
		"orderFocus hors phase : apres la fin, step reste false et le log ne bouge pas ; avant le 1er step, accepte 1 fois",
		function()
			local state = CombatSim.newState(1, { u("banano", 1, 1) }, eight(), Config)
			while CombatSim.step(state) do
			end
			local actions = state.actions
			CombatSim.orderFocus(state, "A", 0)
			expect(CombatSim.step(state)).toBe(false)
			expect(state.actions).toBe(actions)
			expect(#state.log).toBe(actions)

			local fresh = CombatSim.newState(1, eight(), eight(), Config)
			expect(CombatSim.orderFocus(fresh, "A", 3)).toBe(true)
			expect(CombatSim.orderFocus(fresh, "A", 3)).toBe(false)
			expect(fresh.teams.A.focusCell).toBe(3)
			expect(fresh.teams.A.focusTurnsLeft).toBe(Config.Combat.focusTurns)
			expect(CombatSim.step(fresh)).toBe(true)
		end
	)

	it(
		"orderFocus sur une case hors grille : accepte (observe, validation attendue cote DuelService), combat sain",
		function()
			local state = CombatSim.newState(1, eight(), eight(), Config)
			expect(CombatSim.orderFocus(state, "A", -5)).toBe(true)
			expect(CombatSim.orderFocus(state, "B", 99)).toBe(true)
			for _ = 1, 10 do
				expect(CombatSim.step(state)).toBe(true)
			end
			expect(state.actions).toBe(10)
		end
	)

	it(
		"seed 0 et seed 2^31 - 1 : combats termines, deterministes, logs differents entre eux",
		function()
			for _, seed in { 0, MAX_SEED } do
				local result = CombatSim.simulate(seed, eight(), eight(), Config)
				expect(result.actions <= LIMIT).toBe(true)
				expect(result.actions > 0).toBe(true)
				expect(serialize(seed, eight(), eight())).toBe(serialize(seed, eight(), eight()))
			end
			expect(serialize(0, eight(), eight()) == serialize(MAX_SEED, eight(), eight())).toBe(
				false
			)
			expect(serialize(0, eight(), eight()) == serialize(1, eight(), eight())).toBe(false)
		end
	)

	it("ordre d'entree des unites indifferent (tri par case) dans les 2 equipes", function()
		local a = { u("banano", 1, 2), u("tim-cheese", 1, 1), u("pomita", 2, 2) }
		local b = { u("trippi-troppi", 2, 1), u("boneca-ambalabu", 1, 3) }
		local shuffledA = { a[3], a[1], a[2] }
		local shuffledB = { b[2], b[1] }
		expect(serialize(9, a, b)).toBe(serialize(9, shuffledA, shuffledB))
	end)

	it(
		"equipe vide : fin immediate sans action (observe : B gagne, nul si les 2 sont vides)",
		function()
			local r1 = CombatSim.simulate(1, {}, eight(), Config)
			expect(r1.winner).toBe("B")
			expect(r1.actions).toBe(0)
			expect(#r1.actionLog).toBe(0)
			expect(r1.mvp ~= nil).toBe(true)
			local r2 = CombatSim.simulate(1, {}, {}, Config)
			expect(r2.winner).toBe("draw")
			expect(r2.mvp).toBeNil()
		end
	)

	it(
		"entrees invalides : slug inconnu, case hors grille, case doublee, 9 unites : erreur explicite",
		function()
			expect(function()
				CombatSim.simulate(1, { u("inconnu", 1, 1) }, eight(), Config)
			end).toThrow()
			expect(function()
				CombatSim.simulate(1, { u("banano", 3, 1) }, eight(), Config)
			end).toThrow()
			expect(function()
				CombatSim.simulate(1, { u("banano", 1, 1), u("pomito", 1, 1) }, eight(), Config)
			end).toThrow()
			expect(function()
				local nine = eight()
				table.insert(nine, u("banano", 1, 1))
				CombatSim.simulate(1, nine, eight(), Config)
			end).toThrow()
		end
	)

	it(
		"mvp : identifiant slug.sideCell present dans le log quand il y a eu au moins 1 action",
		function()
			local result = CombatSim.simulate(7, eight(), eight(), Config)
			local seen = false
			for _, entry in result.actionLog do
				if entry.actor == result.mvp then
					seen = true
				end
				for _, target in entry.targets do
					if target == string.match(result.mvp :: string, "%.([AB]%d)$") then
						seen = true
					end
				end
			end
			expect(seen).toBe(true)
		end
	)
end)
