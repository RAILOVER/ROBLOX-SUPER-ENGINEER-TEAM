--!strict
-- Etat du duel : transitions, vue client, duel complet simule (spec M1-duel-minimal D-M1-03 a D-M1-20). Pur, Lune.

local Config = loadShared("Config")
local DuelState = loadShared("Duel/DuelState")
local BotPolicy = loadShared("Duel/BotPolicy")
local DuelRemotes = loadShared("Remotes/DuelRemotes")

local SEATS = {
	{ kind = "human", userId = 1, displayName = "Joueur" },
	{ kind = "bot", userId = 0, displayName = "Bot" },
}

local function newDuel(seed: number)
	return DuelState.new(Config, seed, SEATS)
end

-- Joue une manche complete : les 2 sieges suivent BotPolicy (le siege 1 joue le role du joueur humain).
local function playRound(state, brains)
	BotPolicy.play(Config, state, 1, brains[1])
	BotPolicy.play(Config, state, 2, brains[2])
	DuelState.beginCombat(Config, state)
	DuelState.beginResult(Config, state)
	DuelState.endResult(Config, state)
end

describe("DuelState : transitions (D-M1-03 a D-M1-05)", function()
	it("demarre en Lobby avec 100 PV, 3 or, niveau 2, 0 unite", function()
		local state = newDuel(1)
		expect(state.phase).toBe("Lobby")
		expect(state.round).toBe(0)
		for _, seat in state.seats do
			expect(seat.hp).toBe(100)
			expect(seat.gold).toBe(3)
			expect(seat.level).toBe(2)
			expect(#seat.board + #seat.bench).toBe(0)
		end
	end)

	it("Lobby -> Preparation -> Combat -> Resultat -> Preparation, minuteurs par manche", function()
		local state = newDuel(2)
		DuelState.beginPreparation(Config, state)
		expect(state.phase).toBe("Preparation")
		expect(state.round).toBe(1)
		expect(state.timerSeconds).toBe(20)
		expect(#state.seats[1].shop).toBe(5)
		DuelState.beginCombat(Config, state)
		expect(state.phase).toBe("Combat")
		expect(#state.combats).toBe(2)
		DuelState.beginResult(Config, state)
		expect(state.phase).toBe("Resultat")
		expect(state.timerSeconds).toBe(DuelState.RESULT_SECONDS + DuelState.TRANSITION_SECONDS)
		DuelState.endResult(Config, state)
		expect(state.phase).toBe("Preparation")
		expect(state.round).toBe(2)
		expect(state.seats[1].gold >= 3 + 5).toBe(true)
		for _ = 3, 4 do
			DuelState.beginCombat(Config, state)
			DuelState.beginResult(Config, state)
			DuelState.endResult(Config, state)
		end
		expect(state.round).toBe(4)
		expect(state.timerSeconds).toBe(30)
	end)

	it("les 2 sieges prets : minuteur ramene a 3 s, 1 seul depart (spec §6)", function()
		local state = newDuel(3)
		DuelState.beginPreparation(Config, state)
		expect(DuelState.apply(Config, state, 1, "Ready", {}).ok).toBe(true)
		expect(state.timerSeconds).toBe(20)
		expect(DuelState.apply(Config, state, 2, "Ready", {}).ok).toBe(true)
		expect(state.timerSeconds).toBe(3)
		expect(DuelState.apply(Config, state, 1, "Ready", {}).ok).toBe(true)
		expect(state.timerSeconds).toBe(3)
		expect(DuelState.tick(state, 2.9)).toBe(false)
		expect(DuelState.tick(state, 0.1)).toBe(true)
		DuelState.beginCombat(Config, state)
		expect(state.phase).toBe("Combat")
	end)

	it("refuse toute intention hors Preparation, sans erreur (D-M1-04)", function()
		local state = newDuel(4)
		expect(DuelState.apply(Config, state, 1, "BuyShopSlot", { 1 }).reason).toBe("wrong_phase")
		DuelState.beginPreparation(Config, state)
		DuelState.beginCombat(Config, state)
		expect(DuelState.apply(Config, state, 1, "Reroll", {}).reason).toBe("wrong_phase")
		expect(DuelState.apply(Config, state, 1, "OrderFocus", { 3 }).ok).toBe(true)
		expect(DuelState.apply(Config, state, 3, "Ready", {}).reason).toBe("no_seat")
		expect(DuelState.apply(Config, state, 1, "Hack", {}).reason).toBe("wrong_phase")
	end)

	it("manche 1 PvE : 0 degat au joueur, le vainqueur gagne 3 or et 1 carte (D-M1-06)", function()
		local state = newDuel(5)
		DuelState.beginPreparation(Config, state)
		expect(DuelState.isPve(Config, state)).toBe(true)
		DuelState.beginCombat(Config, state)
		DuelState.beginResult(Config, state)
		for _, seat in state.seats do
			expect(seat.hp).toBe(100)
		end
		for _, record in state.combats do
			if record.outcome == "win" then
				local seat = state.seats[record.seatIndex]
				expect(seat.gold).toBe(6)
				expect(#seat.bench).toBe(1)
			end
		end
	end)

	it("abandon en Lobby : fin immediate, l'autre siege gagne (D-M1-20)", function()
		local state = newDuel(6)
		DuelState.forfeit(state, 2)
		expect(state.phase).toBe("Fin")
		expect(state.winnerSeat).toBe(1)
		expect(state.endReason).toBe("forfeit")
	end)
end)

describe("DuelState : vue client (D-M1-11)", function()
	it("ne contient ni la boutique, ni le banc, ni l'or, ni le pool de l'adversaire", function()
		local state = newDuel(7)
		DuelState.beginPreparation(Config, state)
		state.seats[2].gold = 50
		DuelState.apply(Config, state, 2, "BuyShopSlot", { 1 })
		local view = DuelState.toClientView(Config, state, 1)
		expect(view.seatIndex).toBe(1)
		expect(#view.me.shop).toBe(5)
		expect(view.me.gold).toBe(3)
		expect((view.opponent :: any).shop).toBeNil()
		expect((view.opponent :: any).bench).toBeNil()
		expect((view.opponent :: any).gold).toBeNil()
		expect((view.opponent :: any).pool).toBeNil()
		expect((view.opponent :: any).rng).toBeNil()
		expect((view.me :: any).pool).toBeNil()
		expect((view.me :: any).rng).toBeNil()
		expect(view.opponent.hp).toBe(100)
		expect(view.opponent.boardCount).toBe(0)
	end)

	it("cache le plateau adverse en Preparation, le montre a partir de Combat", function()
		local state = newDuel(8)
		DuelState.beginPreparation(Config, state)
		state.seats[2].gold = 50
		DuelState.apply(Config, state, 2, "BuyShopSlot", { 1 })
		local unit = state.seats[2].bench[1]
		expect(DuelState.apply(Config, state, 2, "PlaceUnit", { unit.instanceId, 1, 2 }).ok).toBe(
			true
		)
		local view = DuelState.toClientView(Config, state, 1)
		expect(#view.opponent.board).toBe(0)
		expect(view.opponent.boardCount).toBe(1)
		DuelState.beginCombat(Config, state)
		view = DuelState.toClientView(Config, state, 1)
		expect(#view.opponent.board).toBe(1)
		expect(view.opponent.board[1].slug).toBe(unit.slug)
		-- la vue est une copie : la modifier ne touche pas l'etat serveur
		view.opponent.board[1].stars = 3
		expect(state.seats[2].board[1].stars).toBe(1)
	end)

	it("plateau : niveau = unites max, case occupee = echange, hors bornes refuse", function()
		local state = newDuel(9)
		DuelState.beginPreparation(Config, state)
		local seat = state.seats[1]
		seat.gold = 50
		for slot = 1, 3 do
			expect(DuelState.apply(Config, state, 1, "BuyShopSlot", { slot }).ok).toBe(true)
		end
		local ids = {}
		for _, unit in seat.bench do
			table.insert(ids, unit.instanceId)
		end
		expect(DuelState.apply(Config, state, 1, "PlaceUnit", { ids[1], 1, 1 }).ok).toBe(true)
		expect(DuelState.apply(Config, state, 1, "PlaceUnit", { ids[2], 1, 2 }).ok).toBe(true)
		if #ids >= 3 then
			expect(DuelState.apply(Config, state, 1, "PlaceUnit", { ids[3], 2, 1 }).reason).toBe(
				"board_full"
			)
			expect(DuelState.apply(Config, state, 1, "PlaceUnit", { ids[3], 1, 1 }).ok).toBe(true)
			expect(#seat.board).toBe(2)
		end
		expect(DuelState.apply(Config, state, 1, "PlaceUnit", { ids[1], 3, 1 }).reason).toBe(
			"bad_cell"
		)
		expect(DuelState.apply(Config, state, 1, "PlaceUnit", { "u99", 1, 1 }).reason).toBe(
			"unknown_unit"
		)
		expect(DuelState.apply(Config, state, 1, "BenchUnit", { ids[2] }).ok).toBe(true)
		expect(DuelState.apply(Config, state, 1, "SetTactic", { "Prudent" }).ok).toBe(true)
		for _, unit in seat.bench do
			expect(unit.tactic).toBe("Prudent")
		end
	end)
end)

describe("DuelRemotes : contrat", function()
	it("expose 10 remotes client -> serveur et 3 serveur -> client, cooldown 100 ms", function()
		expect(#DuelRemotes.clientOrder).toBe(10)
		for _, name in DuelRemotes.clientOrder do
			expect(DuelRemotes.clientToServer[name] ~= nil).toBe(true)
		end
		expect(#DuelRemotes.serverToClient).toBe(3)
		expect(DuelRemotes.COOLDOWN_SECONDS).toBe(0.1)
	end)

	it("valide types et bornes, refuse le reste", function()
		expect(DuelRemotes.validateArgs("BuyShopSlot", { 5 })).toBe(true)
		expect(DuelRemotes.validateArgs("BuyShopSlot", { 6 })).toBe(false)
		expect(DuelRemotes.validateArgs("BuyShopSlot", { 1.5 })).toBe(false)
		expect(DuelRemotes.validateArgs("BuyShopSlot", { "1" })).toBe(false)
		expect(DuelRemotes.validateArgs("BuyShopSlot", { 0 / 0 })).toBe(false)
		expect(DuelRemotes.validateArgs("PlaceUnit", { "u12", 2, 4 })).toBe(true)
		expect(DuelRemotes.validateArgs("PlaceUnit", { "u12", 3, 4 })).toBe(false)
		expect(DuelRemotes.validateArgs("PlaceUnit", { "x12", 1, 1 })).toBe(false)
		expect(DuelRemotes.validateArgs("SetTactic", { "Prudent" })).toBe(true)
		expect(DuelRemotes.validateArgs("SetTactic", { "Prudent", "u3" })).toBe(true)
		expect(DuelRemotes.validateArgs("SetTactic", { "Furieux" })).toBe(false)
		expect(DuelRemotes.validateArgs("OrderFocus", { 7 })).toBe(true)
		expect(DuelRemotes.validateArgs("OrderFocus", { 8 })).toBe(false)
		expect(DuelRemotes.validateArgs("Ready", {})).toBe(true)
		expect(DuelRemotes.validateArgs("Inconnu", {})).toBe(false)
	end)
end)

describe("DuelState : 100 duels complets simules (D-M1-19, D-M1-21)", function()
	it("se terminent, 50 % au moins en 8 a 11 manches (mesure affichee)", function()
		local rounds = {}
		local histogram: { [number]: number } = {}
		local inTarget, draws = 0, 0
		local lo, hi = Config.Duel.targetRounds[1], Config.Duel.targetRounds[2]
		for seed = 1, 100 do
			local state = newDuel(seed)
			local brains = { BotPolicy.newBrain(seed * 7), BotPolicy.newBrain(seed * 13) }
			DuelState.beginPreparation(Config, state)
			while state.phase ~= "Fin" and state.round < 60 do
				playRound(state, brains)
				for _, seat in state.seats do
					expect(seat.gold >= 0).toBe(true)
					expect(#seat.board <= seat.level).toBe(true)
					expect(#seat.bench <= Config.Duel.benchSize).toBe(true)
				end
			end
			expect(state.phase).toBe("Fin")
			local loser = state.seats[3 - (state.winnerSeat or 1)]
			if state.winnerSeat then
				expect(loser.hp <= 0).toBe(true)
				expect(state.seats[state.winnerSeat].hp > 0 or state.endReason == "hp").toBe(true)
			else
				draws += 1
			end
			table.insert(rounds, state.round)
			histogram[state.round] = (histogram[state.round] or 0) + 1
			if state.round >= lo and state.round <= hi then
				inTarget += 1
			end
		end
		table.sort(rounds)
		local parts = {}
		for round = rounds[1], rounds[100] do
			if histogram[round] then
				table.insert(parts, `{round}:{histogram[round]}`)
			end
		end
		print(
			`  mesure 100 duels bot vs bot : mediane {rounds[50]} manches, min {rounds[1]}, max {rounds[100]}, `
				.. `{inTarget} % en {lo} a {hi} manches, {draws} nul(s), repartition {table.concat(
					parts,
					" "
				)}`
		)
		expect(inTarget >= 50).toBe(true)
	end)
end)
