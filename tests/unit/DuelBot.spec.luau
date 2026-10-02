--!strict
-- Bot adversaire M1 (spec M1-duel-minimal §5, D-M1-25 a D-M1-32). Pur, Lune.

local Config = loadShared("Config")
local DuelState = loadShared("Duel/DuelState")
local BotPolicy = loadShared("Duel/BotPolicy")

local SEATS = {
	{ kind = "human", userId = 1, displayName = "Joueur" },
	{ kind = "bot", userId = 0, displayName = "Bot" },
}

local function snapshot(seat): string
	local parts = {}
	for _, unit in seat.board do
		table.insert(parts, `{unit.slug}:{unit.stars}@{unit.row},{unit.col}:{unit.tactic}`)
	end
	table.sort(parts)
	local bench = {}
	for _, unit in seat.bench do
		table.insert(bench, `{unit.slug}:{unit.stars}`)
	end
	table.sort(bench)
	return `{seat.gold}|{seat.level}|{table.concat(parts, ",")}|{table.concat(bench, ",")}`
end

-- Le joueur (siege 1) achete et place sans strategie, de facon deterministe (seed du duel).
local function playHuman(state)
	local seat = state.seats[1]
	for slot = 1, 5 do
		DuelState.apply(Config, state, 1, "BuyShopSlot", { slot })
	end
	for _, unit in table.clone(seat.bench) do
		local index = #seat.board
		DuelState.apply(
			Config,
			state,
			1,
			"PlaceUnit",
			{ unit.instanceId, index // 4 + 1, index % 4 + 1 }
		)
	end
	DuelState.apply(Config, state, 1, "Ready", {})
end

local function runDuel(seed: number, botSeed: number, onPrep: ((any) -> ())?): (any, { string })
	local state = DuelState.new(Config, seed, SEATS)
	local brain = BotPolicy.newBrain(botSeed)
	local trace = {}
	DuelState.beginPreparation(Config, state)
	while state.phase ~= "Fin" and state.round < 30 do
		playHuman(state)
		if onPrep then
			onPrep(state)
		end
		BotPolicy.play(Config, state, 2, brain)
		table.insert(trace, snapshot(state.seats[2]))
		DuelState.beginCombat(Config, state)
		DuelState.beginResult(Config, state)
		DuelState.endResult(Config, state)
	end
	return state, trace
end

describe("DuelBot : plans (D-M1-25)", function()
	it("3 plans avec des cibles du deck M1, poids 50 / 30 / 20", function()
		local couple = BotPolicy.planTargets(Config, "Couple")
		expect(couple[1]).toBe("banano")
		expect(couple[4]).toBe("pomita")
		expect(table.find(couple, "myrtila") ~= nil).toBe(true)
		local mare = BotPolicy.planTargets(Config, "Mare")
		expect(table.find(mare, "trippi-troppi") ~= nil).toBe(true)
		expect(table.find(mare, "glorbo-fruttodrillo") ~= nil).toBe(true)
		expect(table.find(mare, "boneca-ambalabu") ~= nil).toBe(true)
		local tank = BotPolicy.planTargets(Config, "Tank")
		expect(table.find(tank, "banano") ~= nil).toBe(true)
		expect(table.find(tank, "pomita") ~= nil).toBe(true)
		local total = 0
		for _, entry in BotPolicy.PLAN_WEIGHTS do
			total += entry.weight
		end
		expect(total).toBeCloseTo(1, 6)
	end)

	it(
		"choisit son plan a la manche 1 et le garde ; repartition sur 300 seeds proche de 50 / 30 / 20",
		function()
			local counts = { Couple = 0, Mare = 0, Tank = 0 }
			for seed = 1, 300 do
				local state = DuelState.new(Config, seed, SEATS)
				local brain = BotPolicy.newBrain(seed)
				DuelState.beginPreparation(Config, state)
				BotPolicy.play(Config, state, 2, brain)
				local plan = brain.plan
				counts[plan] += 1
				DuelState.beginCombat(Config, state)
				DuelState.beginResult(Config, state)
				DuelState.endResult(Config, state)
				BotPolicy.play(Config, state, 2, brain)
				expect(brain.plan).toBe(plan)
			end
			expect(math.abs(counts.Couple / 300 - 0.5) < 0.1).toBe(true)
			expect(math.abs(counts.Mare / 300 - 0.3) < 0.1).toBe(true)
			expect(math.abs(counts.Tank / 300 - 0.2) < 0.1).toBe(true)
		end
	)
end)

describe("DuelBot : determinisme (D-M1-32)", function()
	it("100 seeds : meme seed et memes plateaux du joueur => memes achats et placements", function()
		for seed = 1, 100 do
			local _, traceA = runDuel(seed, seed * 31)
			local _, traceB = runDuel(seed, seed * 31)
			expect(#traceA).toBe(#traceB)
			for index, line in traceA do
				expect(traceB[index]).toBe(line)
			end
		end
	end)

	it("2 seeds de bot a plans differents donnent des parties differentes", function()
		local traces: { [string]: string } = {}
		for botSeed = 1, 20 do
			local state = DuelState.new(Config, 5, SEATS)
			local brain = BotPolicy.newBrain(botSeed)
			DuelState.beginPreparation(Config, state)
			BotPolicy.play(Config, state, 2, brain)
			local plan = brain.plan :: string
			if traces[plan] == nil then
				local _, trace = runDuel(5, botSeed)
				traces[plan] = table.concat(trace, ";")
			end
		end
		expect(traces.Couple ~= nil and traces.Mare ~= nil and traces.Tank ~= nil).toBe(true)
		expect(traces.Couple ~= traces.Mare).toBe(true)
		expect(traces.Mare ~= traces.Tank).toBe(true)
	end)
end)

describe("DuelBot : regles d'achat et de placement (D-M1-26 a D-M1-30)", function()
	it("jamais plus d'or que disponible, plateau valide, 1 relance max par manche", function()
		for seed = 1, 40 do
			local state = DuelState.new(Config, seed, SEATS)
			local brain = BotPolicy.newBrain(seed)
			DuelState.beginPreparation(Config, state)
			while state.phase ~= "Fin" and state.round < 30 do
				playHuman(state)
				local seat = state.seats[2]
				local goldBefore = seat.gold
				BotPolicy.play(Config, state, 2, brain)
				expect(seat.gold >= 0).toBe(true)
				expect(seat.ready).toBe(true)
				expect(#seat.board <= seat.level).toBe(true)
				expect(#seat.bench <= Config.Duel.benchSize).toBe(true)
				local cells: { [string]: boolean } = {}
				for _, unit in seat.board do
					expect(unit.row >= 1 and unit.row <= 2 and unit.col >= 1 and unit.col <= 4).toBe(
						true
					)
					local key = `{unit.row},{unit.col}`
					expect(cells[key]).toBeNil()
					cells[key] = true
					local class = Config.Roster.units[unit.slug].class
					local front = class == "Colosse" or class == "Guerrier" or class == "Sprinteur"
					expect(unit.row).toBe(if front then 1 else 2)
					local wanted = if class == "Colosse" and seat.hp < BotPolicy.PRUDENT_HP
						then "Prudent"
						else "Equilibre"
					expect(unit.tactic).toBe(wanted)
				end
				expect(goldBefore - seat.gold <= goldBefore).toBe(true)
				expect(brain.rerolledRound <= state.round).toBe(true)
				DuelState.beginCombat(Config, state)
				DuelState.beginResult(Config, state)
				DuelState.endResult(Config, state)
			end
		end
	end)

	it("achete 4 XP a la manche 4 seulement si l'or restant est >= 12 (D-M1-28)", function()
		local xpBought, skipped = 0, 0
		for seed = 1, 40 do
			local state = DuelState.new(Config, seed, SEATS)
			local brain = BotPolicy.newBrain(seed)
			DuelState.beginPreparation(Config, state)
			while state.round < 4 do
				playHuman(state)
				BotPolicy.play(Config, state, 2, brain)
				DuelState.beginCombat(Config, state)
				DuelState.beginResult(Config, state)
				DuelState.endResult(Config, state)
			end
			local seat = state.seats[2]
			seat.gold = if seed % 2 == 0 then 20 else 10
			local xpBefore, levelBefore = seat.xp, seat.level
			BotPolicy.play(Config, state, 2, brain)
			local gained = seat.xp ~= xpBefore or seat.level ~= levelBefore
			if seed % 2 == 0 then
				expect(gained).toBe(true)
				xpBought += 1
			else
				-- 10 - 4 = 6 < 12 : pas d'achat d'XP (les 2 XP auto sont deja tombes au debut de la manche)
				expect(gained).toBe(false)
				skipped += 1
			end
		end
		expect(xpBought).toBe(20)
		expect(skipped).toBe(20)
	end)

	it("ne joue rien hors Preparation", function()
		local state = DuelState.new(Config, 3, SEATS)
		local brain = BotPolicy.newBrain(3)
		BotPolicy.play(Config, state, 2, brain)
		expect(brain.plan).toBeNil()
		expect(state.seats[2].gold).toBe(3)
	end)
end)
