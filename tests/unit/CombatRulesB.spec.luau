--!strict
-- Couverture M-C-05, regles R-M1-31 a R-M1-60 (design/specs/M1-combat-tour-par-tour.md).

local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")
local Actions = loadShared("Combat/Actions")
local Effects = loadShared("Combat/Effects")
local Formulas = loadShared("Combat/Formulas")
local Status = loadShared("Combat/Status")
local Tactics = loadShared("Combat/Tactics")
local Targeting = loadShared("Combat/Targeting")
local Timeline = loadShared("Combat/Timeline")

local function u(slug: string, row: number, col: number, tactic: string?)
	return { slug = slug, row = row, col = col, tactic = tactic }
end

local function newState(a, b, opts)
	return CombatSim.newState(1, a, b, Config, opts)
end

local function find(state, slug: string, side: string?)
	for _, unit in state.units do
		if unit.slug == slug and (side == nil or unit.side == side) then
			return unit
		end
	end
	error(`unite absente : {slug}`)
end

local function force(state, unit)
	for _, other in state.units do
		other.timeline = 0
	end
	unit.timeline = Config.Combat.timelineThreshold
	state.lastActedSide = nil
end

local function fixedRng(roll: number?)
	local rng = {}
	function rng.NextNumber(_, min, max)
		if min ~= nil then
			return min + (max - min) * 0.5
		end
		return roll or 0.99
	end
	function rng.NextInteger(_, min)
		return min
	end
	function rng.Clone(self)
		return self
	end
	return rng
end

local function open(state, unit)
	return Actions.beginEntry(state, unit, "Attack")
end

local COUPLE_A = { u("banano", 1, 2), u("bananella", 2, 2) }
local FOES_B = { u("trippi-troppi", 1, 2), u("boneca-ambalabu", 2, 3) }

describe("R-M1-31 a R-M1-34 : Mega Combo", function()
	it(
		"R-M1-31 : +4 par action d'un membre de synergie, +8 par K.O. adverse, 25 actions = 100",
		function()
			expect(25 * Config.Combat.megaGainPerSynergyAction).toBe(100)
			local state = newState(COUPLE_A, FOES_B)
			local banano = find(state, "banano")
			expect(banano.synergyMember).toBe(true)
			force(state, banano)
			CombatSim.step(state)
			expect(state.teams.A.mega).toBe(4)
			Status.knockOut(state, find(state, "trippi-troppi"))
			expect(state.teams.A.mega).toBe(12)
			local lone = newState({ u("tim-cheese", 1, 1) }, FOES_B)
			local tim = find(lone, "tim-cheese")
			expect(tim.synergyMember).toBe(false)
			force(lone, tim)
			CombatSim.step(lone)
			expect(lone.teams.A.mega).toBe(0)
		end
	)

	it("R-M1-32 : combo disponible si jauge 100, paire vivante, 1 usage par combat", function()
		local state = newState(COUPLE_A, FOES_B)
		expect(#Effects.availableCombos(state, state.teams.A)).toBe(0)
		state.teams.A.mega = 100
		expect(Effects.availableCombos(state, state.teams.A)[1]).toBe("C05")
		state.teams.A.megaUsed.C05 = 1
		expect(#Effects.availableCombos(state, state.teams.A)).toBe(0)
		state.teams.A.megaUsed.C05 = nil
		Status.knockOut(state, find(state, "bananella"))
		expect(#Effects.availableCombos(state, state.teams.A)).toBe(0)
		state.teams.B.mega = 100
		expect(#Effects.availableCombos(state, state.teams.B)).toBe(0)
	end)

	it("R-M1-33 : autoMega = false => aucun Mega automatique (declenchement manuel M2)", function()
		local state = newState(COUPLE_A, FOES_B, { autoMega = false })
		state.teams.A.mega = 100
		force(state, find(state, "banano"))
		CombatSim.step(state)
		expect(state.log[1].action).toBe("Attack")
		expect(state.teams.A.mega >= 100).toBe(true)
	end)

	it(
		"R-M1-34 : C05 : Bouclier 30 %, soin 25 %, 2 frappes x2,00 sur la cible du plus rapide, jauge 0, 1 action",
		function()
			local state = newState(COUPLE_A, FOES_B)
			local banano, bananella = find(state, "banano"), find(state, "bananella")
			banano.hp = banano.hpMax - 1000
			state.teams.A.mega = 100
			expect(Actions.mega(state, state.teams.A, "C05")).toBe(true)
			local entry = state.log[1]
			expect(entry.action).toBe("Mega")
			expect(entry.combo).toBe("C05")
			expect(entry.actor).toBe("bananella.A5")
			expect(entry.partner).toBe("banano.A1")
			expect(Status.get(banano, "Bouclier").shield).toBe(math.floor(0.3 * banano.hpMax))
			expect(Status.get(bananella, "Bouclier").shield).toBe(math.floor(0.3 * bananella.hpMax))
			expect(banano.hp).toBe(banano.hpMax - 1000 + math.floor(0.25 * banano.hpMax))
			expect(#entry.values).toBe(4)
			expect(entry.targets[3]).toBe(entry.targets[4])
			expect(entry.values[3] > 0 and entry.values[4] > 0).toBe(true)
			expect(state.teams.A.mega).toBe(0)
			expect(state.teams.A.megaUsed.C05).toBe(1)
			expect(state.actions).toBe(1)
		end
	)
end)

describe("R-M1-35 a R-M1-49 : les 13 statuts", function()
	it("R-M1-35 : Etourdi => prochaine action Skip puis tombe", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		Status.apply(state, banano, "Etourdi")
		expect(Status.skipsTurn(banano)).toBe(true)
		force(state, banano)
		CombatSim.step(state)
		expect(state.log[1].action).toBe("Skip")
		expect(#banano.statuses).toBe(0)
	end)

	it("R-M1-36 : Endormi tombe au premier degat > 0", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano, foe = find(state, "banano"), find(state, "trippi-troppi")
		Status.apply(state, banano, "Endormi")
		expect(Status.skipsTurn(banano)).toBe(true)
		open(state, foe)
		Actions.dealDamage(state, foe, banano, 1)
		expect(Status.has(banano, "Endormi")).toBe(false)
		expect(state.currentEntry.statuses.removed[1]).toBe("Endormi@A1")
	end)

	it("R-M1-37 : Charme => Attaque sur un allie", function()
		local state = newState(COUPLE_A, FOES_B)
		local bananella = find(state, "bananella")
		Status.apply(state, bananella, "Charme")
		expect(Status.hasControl(bananella)).toBe(true)
		expect(Status.skipsTurn(bananella)).toBe(false)
		force(state, bananella)
		CombatSim.step(state)
		expect(state.log[1].targets[1]).toBe("A1")
	end)

	it(
		"R-M1-38 : HorsCombat : pas de timeline, pas ciblable, retour apres 2 tours d'equipe, hp et energie intacts",
		function()
			local state = newState(COUPLE_A, FOES_B)
			local banano, bananella = find(state, "banano"), find(state, "bananella")
			local foe = find(state, "trippi-troppi")
			banano.energy = 57
			Status.apply(state, banano, "HorsCombat")
			expect(Timeline.canAdvance(banano)).toBe(false)
			expect(#Targeting.aliveEnemies(state, foe)).toBe(1)
			for _ = 1, 2 do
				force(state, bananella)
				CombatSim.step(state)
			end
			expect(Status.has(banano, "HorsCombat")).toBe(false)
			expect(banano.energy).toBe(57)
			expect(banano.hp).toBe(banano.hpMax)
		end
	)

	it("R-M1-39 : Ralenti => VIT x0,70", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		Status.apply(state, banano, "Ralenti")
		expect(Timeline.effectiveVit(state, banano)).toBe(math.floor(banano.stats.VIT * 0.7))
	end)

	it("R-M1-40 : Enracine => VIT x0,50, cumul avec Ralenti x0,35", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		Status.apply(state, banano, "Enracine")
		expect(Timeline.effectiveVit(state, banano)).toBe(math.floor(banano.stats.VIT * 0.5))
		Status.apply(state, banano, "Ralenti")
		expect(Timeline.effectiveVit(state, banano)).toBe(math.floor(banano.stats.VIT * 0.7 * 0.5))
	end)

	it(
		"R-M1-41 : Brulure : floor(0,05 x HPmax) au debut du tour, ignore Bouclier, pas d'energie, peut K.O.",
		function()
			local state = newState(COUPLE_A, FOES_B)
			local banano = find(state, "banano")
			Status.apply(state, banano, "Brulure")
			Status.apply(state, banano, "Bouclier", { shield = 500 })
			open(state, banano)
			local dealt = Status.onTurnStart(state, banano, 1)
			expect(dealt).toBe(math.floor(0.05 * banano.hpMax))
			expect(banano.hp).toBe(banano.hpMax - dealt)
			expect(Status.get(banano, "Bouclier").shield).toBe(500)
			expect(banano.energy).toBe(20)
			banano.hp = 1
			Status.onTurnStart(state, banano, 1)
			expect(banano.alive).toBe(false)
		end
	)

	it(
		"R-M1-42 : Saignement : 3 stacks max, degats = stacks x 0,04 x HPmax, chute groupee",
		function()
			local state = newState(COUPLE_A, FOES_B)
			local banano = find(state, "banano")
			for _ = 1, 4 do
				Status.apply(state, banano, "Saignement", { turns = 1 })
			end
			expect(Status.get(banano, "Saignement").stacks).toBe(3)
			open(state, banano)
			expect(Status.onTurnStart(state, banano, 1)).toBe(math.floor(3 * 0.04 * banano.hpMax))
			state.actions += 1
			Status.onTurnEnd(state, banano)
			expect(Status.has(banano, "Saignement")).toBe(false)
		end
	)

	it("R-M1-43 : Expose => degats recus x1,25", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		Status.apply(state, banano, "Expose")
		expect(Status.damageTakenMult(Config, banano)).toBe(1.25)
	end)

	it("R-M1-44 : Bouclier : garde la plus grande valeur, tombe a 0", function()
		local state = newState(COUPLE_A, FOES_B)
		state.rng = fixedRng()
		local banano, foe = find(state, "banano"), find(state, "trippi-troppi")
		Status.apply(state, banano, "Bouclier", { shield = 300 })
		Status.apply(state, banano, "Bouclier", { shield = 100 })
		expect(Status.get(banano, "Bouclier").shield).toBe(300)
		Status.apply(state, banano, "Bouclier", { shield = 400 })
		expect(Status.get(banano, "Bouclier").shield).toBe(400)
		foe.stats.ATQ, banano.stats.DEF = 1000, 0
		open(state, foe)
		Actions.dealDamage(state, foe, banano, 1)
		expect(Status.has(banano, "Bouclier")).toBe(false)
		expect(banano.hp).toBe(banano.hpMax - 600)
	end)

	it("R-M1-45 : 1 seule Provocation par camp, la plus recente", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano, bananella = find(state, "banano"), find(state, "bananella")
		Status.apply(state, banano, "Provocation")
		Status.apply(state, bananella, "Provocation")
		expect(Status.has(banano, "Provocation")).toBe(false)
		expect(Status.has(bananella, "Provocation")).toBe(true)
		local foe = find(state, "trippi-troppi")
		expect(Targeting.single(state, foe)).toBe(bananella)
	end)

	it(
		"R-M1-46 : Invisible : hors cible unique, touche par la zone, retire en attaquant",
		function()
			local state = newState(COUPLE_A, FOES_B)
			local banano, foe = find(state, "banano"), find(state, "trippi-troppi")
			Status.apply(state, banano, "Invisible")
			expect(Targeting.single(state, foe)).toBe(find(state, "bananella"))
			local aoe = Targeting.multiple(state, foe, 2)
			expect(#aoe).toBe(2)
			force(state, banano)
			CombatSim.step(state)
			expect(state.log[1].action).toBe("Attack")
			expect(Status.has(banano, "Invisible")).toBe(false)
		end
	)

	it(
		"R-M1-47 : Epines renvoie floor(degats x thornsPct) aux attaquants Melee, pas aux Ranged, sans rebond",
		function()
			local state = newState(COUPLE_A, { u("trippi-troppi", 1, 2), u("bananella", 2, 2) })
			state.rng = fixedRng()
			local banano = find(state, "banano")
			local melee, ranged = find(state, "trippi-troppi"), find(state, "bananella", "B")
			Status.apply(state, banano, "Epines", { thornsPct = 0.5 })
			Status.apply(state, melee, "Epines", { thornsPct = 0.5 })
			open(state, melee)
			local dealt = Actions.dealDamage(state, melee, banano, 1)
			expect(melee.hp).toBe(melee.hpMax - math.floor(dealt * 0.5))
			expect(banano.hp).toBe(banano.hpMax - dealt)
			Actions.finishEntry(state, melee)
			open(state, ranged)
			Actions.dealDamage(state, ranged, banano, 1)
			expect(ranged.hp).toBe(ranged.hpMax)
		end
	)

	it(
		"R-M1-48 : immunite 1 tour aux controles apres la chute d'un controle ; boss resiste a 50 %",
		function()
			local state = newState(COUPLE_A, FOES_B)
			local banano = find(state, "banano")
			Status.apply(state, banano, "Etourdi")
			force(state, banano)
			CombatSim.step(state)
			expect(banano.controlImmunity).toBe(1)
			expect(Status.apply(state, banano, "Endormi")).toBe(false)
			expect(Status.apply(state, banano, "Ralenti")).toBe(true)
			force(state, banano)
			CombatSim.step(state)
			expect(banano.controlImmunity).toBe(0)
			expect(Status.apply(state, banano, "Endormi")).toBe(true)
			local boss = find(state, "trippi-troppi")
			boss.isBoss = true
			expect(Status.apply(state, boss, "HorsCombat")).toBe(false)
			state.rng = fixedRng(0.1)
			expect(Status.apply(state, boss, "Etourdi")).toBe(false)
			state.rng = fixedRng(0.9)
			expect(Status.apply(state, boss, "Etourdi")).toBe(true)
		end
	)

	it("R-M1-49 : Combat.statuses contient exactement les 13 cles", function()
		local expected = {
			"Etourdi",
			"Endormi",
			"Charme",
			"HorsCombat",
			"Ralenti",
			"Enracine",
			"Brulure",
			"Saignement",
			"Expose",
			"Bouclier",
			"Provocation",
			"Invisible",
			"Epines",
		}
		local count = 0
		for name in Config.Combat.statuses do
			count += 1
			expect(table.find(expected, name)).toBeTruthy()
		end
		expect(count).toBe(13)
	end)
end)

describe("R-M1-50 a R-M1-54 : tactiques", function()
	it(
		"R-M1-50 : Garde sous le seuil si Prudent ou Soigneur allie vivant ; Agressif jamais",
		function()
			local state = newState({ u("pomito", 1, 1, "Agressif"), u("pomita", 2, 1) }, FOES_B)
			local pomito, pomita = find(state, "pomito"), find(state, "pomita")
			pomito.hp = 1
			expect(Tactics.wantsGuard(state, pomito)).toBe(false)
			pomito.tactic = "Equilibre"
			pomito.hp = math.ceil(pomito.hpMax * 0.2)
			expect(Tactics.wantsGuard(state, pomito)).toBe(false)
			pomito.hp = math.floor(pomito.hpMax * 0.15)
			expect(Tactics.wantsGuard(state, pomito)).toBe(true)
			Status.knockOut(state, pomita)
			expect(Tactics.wantsGuard(state, pomito)).toBe(false)
			pomito.tactic = "Prudent"
			pomito.hp = math.floor(pomito.hpMax * 0.24)
			expect(Tactics.wantsGuard(state, pomito)).toBe(true)
			pomito.hp = math.ceil(pomito.hpMax * 0.25)
			expect(Tactics.wantsGuard(state, pomito)).toBe(false)
			pomito.hp = math.floor(pomito.hpMax * 0.24)
			expect(Tactics.decide(state, pomito).kind).toBe("Guard")
		end
	)

	it(
		"R-M1-51 : Soigneur garde sa competence au-dessus du seuil ; Prudent joue la defensive d'abord",
		function()
			local state = newState({ u("pomita", 2, 1), u("banano", 1, 1) }, FOES_B)
			local pomita, banano = find(state, "pomita"), find(state, "banano")
			pomita.energy = 100
			expect(Tactics.wantsSkill(state, pomita)).toBe(false)
			banano.hp = math.floor(banano.hpMax * 0.69)
			expect(Tactics.wantsSkill(state, pomita)).toBe(true)
			banano.hp = banano.hpMax
			pomita.tactic = "Agressif"
			expect(Tactics.wantsSkill(state, pomita)).toBe(true)
			pomita.energy = 69
			expect(Tactics.wantsSkill(state, pomita)).toBe(false)
			local offensive = Config.Skills.bySlug.pomito
			local defensive = Config.Skills.bySlug.banano
			expect(Tactics.chooseSkill({ offensive, defensive }, "Prudent")).toBe(defensive)
			expect(Tactics.chooseSkill({ offensive, defensive }, "Equilibre")).toBe(offensive)
		end
	)

	it(
		"R-M1-52 : Agressif => hp min ; Assassin => arriere ; Artilleur => ligne pleine ; Colosse => plus de degats",
		function()
			local foes = {
				u("pomito", 1, 1),
				u("trippi-troppi", 1, 2),
				u("tim-cheese", 2, 1),
				u("bananella", 2, 2),
			}
			local state = newState({
				u("banano", 1, 1, "Agressif"),
				u("trippi-troppi", 1, 2),
				u("bananella", 2, 1),
				u("glorbo-fruttodrillo", 1, 3),
			}, foes)
			local weakest, frontWeak = find(state, "tim-cheese"), find(state, "trippi-troppi", "B")
			weakest.hp, frontWeak.hp = 2, 1
			expect(Targeting.single(state, find(state, "banano"))).toBe(frontWeak)
			expect(Targeting.single(state, find(state, "trippi-troppi", "A"))).toBe(weakest)
			expect(Targeting.single(state, find(state, "bananella", "A")).row).toBe(1)
			Status.knockOut(state, find(state, "pomito"))
			expect(Targeting.single(state, find(state, "bananella", "A"))).toBe(weakest)
			local foeTrippi = find(state, "trippi-troppi", "B")
			state.teams.A.damageFromEnemy[foeTrippi.id] = 999
			expect(Targeting.single(state, find(state, "glorbo-fruttodrillo"))).toBe(foeTrippi)
		end
	)

	it("R-M1-53 : tactique par defaut Equilibre, fixee par unite", function()
		local state = newState({ u("banano", 1, 1), u("bananella", 2, 1, "Prudent") }, FOES_B)
		expect(find(state, "banano").tactic).toBe("Equilibre")
		expect(find(state, "bananella").tactic).toBe("Prudent")
	end)

	it(
		"R-M1-54 : 100 combats miroir Agressif contre Prudent : part de victoires mesuree (cible 35 a 65 %, T-0015)",
		function()
			local slugs = { "banano", "bananella", "glorbo-fruttodrillo", "pomita", "tim-cheese" }
			local cells = { { 1, 2 }, { 2, 2 }, { 1, 3 }, { 2, 3 }, { 2, 1 } }
			local function team(tactic: string)
				local out = {}
				for i, slug in slugs do
					table.insert(out, u(slug, cells[i][1], cells[i][2], tactic))
				end
				return out
			end
			local winsA, winsB, draws = 0, 0, 0
			for seed = 1, 100 do
				local result = CombatSim.simulate(seed, team("Agressif"), team("Prudent"), Config)
				if result.winner == "A" then
					winsA += 1
				elseif result.winner == "B" then
					winsB += 1
				else
					draws += 1
				end
			end
			print(
				`  R-M1-54 miroir : Agressif {winsA} / Prudent {winsB} / nuls {draws} (cible 35 a 65 par camp)`
			)
			expect(winsA + winsB + draws).toBe(100)
			local inTarget = winsA >= 35 and winsA <= 65 and winsB >= 35 and winsB <= 65
			if not inTarget then
				print(
					"  R-M1-54 : hors cible avec les valeurs actuelles de Config, voir D-10 (T-0024) et tests/sim/MirrorTactics"
				)
			end
		end
	)
end)

describe("R-M1-55 a R-M1-60 : focus, limites, journal", function()
	it(
		"R-M1-55 : 1 ordre de focus par combat, vise la cible designee 2 tours d'equipe, 2e ordre ignore",
		function()
			local state = newState(
				{ u("bananella", 2, 1) },
				{ u("pomito", 1, 1), u("tim-cheese", 2, 2) }
			)
			local shooter, tim = find(state, "bananella", "A"), find(state, "tim-cheese")
			tim.hp = tim.hpMax
			expect(CombatSim.orderFocus(state, "A", tim.cell)).toBe(true)
			expect(Targeting.single(state, shooter)).toBe(tim)
			expect(CombatSim.orderFocus(state, "A", 0)).toBe(false)
			expect(state.teams.A.focusCell).toBe(tim.cell)
			for _ = 1, 2 do
				force(state, shooter)
				CombatSim.step(state)
				expect(state.log[#state.log].targets[1]).toBe(`B{tim.cell}`)
			end
			expect(state.teams.A.focusTurnsLeft).toBe(0)
			expect(Targeting.single(state, shooter).cell).toBe(0)
		end
	)

	it("R-M1-56 : actions compte unites et Mega, pas les ticks", function()
		local state = newState(COUPLE_A, FOES_B)
		state.teams.A.mega = 100
		local banano = find(state, "banano")
		Status.apply(state, banano, "Etourdi")
		force(state, banano)
		CombatSim.step(state)
		expect(state.actions).toBe(2)
		expect(state.ticks).toBe(0)
		CombatSim.step(state)
		expect(state.actions).toBe(3)
		expect(state.ticks > 0).toBe(true)
	end)

	it("R-M1-57 : mort subite : x1 jusqu'a 40, x2,44 a 44, x86,74 a 60", function()
		expect(Formulas.suddenDeathMult(Config, 40)).toBe(1)
		expect(Formulas.suddenDeathMult(Config, 44)).toBeCloseTo(2.44, 2)
		expect(Formulas.suddenDeathMult(Config, 60)).toBeCloseTo(86.74, 2)
	end)

	it("R-M1-58 : nul a 60 actions si les 2 camps ont encore une unite", function()
		local state = newState(COUPLE_A, FOES_B)
		for _, unit in state.units do
			unit.hpMax, unit.hp = 1e9, 1e9
		end
		local running = true
		while running do
			running = CombatSim.step(state)
		end
		expect(state.actions).toBe(60)
		expect(CombatSim.result(state).winner).toBe("draw")
	end)

	it(
		"R-M1-59 : victoire quand un camp est vide ; les 2 camps tombent dans la meme action => nul",
		function()
			local state = newState({ u("banano", 1, 1) }, { u("trippi-troppi", 1, 1) })
			Status.knockOut(state, find(state, "trippi-troppi"))
			CombatSim.step(state)
			expect(CombatSim.result(state).winner).toBe("A")
			local tie = newState({ u("banano", 1, 1) }, { u("trippi-troppi", 1, 1) })
			local banano, foe = find(tie, "banano"), find(tie, "trippi-troppi")
			Status.apply(tie, banano, "Epines", { thornsPct = 1 })
			banano.hp, foe.hp = 1, 1
			force(tie, foe)
			CombatSim.step(tie)
			expect(banano.alive).toBe(false)
			expect(foe.alive).toBe(false)
			expect(CombatSim.result(tie).winner).toBe("draw")
		end
	)

	it(
		"R-M1-60 : ActionLog version 1 : t, actor, action, targets, values, statuses, gauges, hp, kos ; mvp",
		function()
			local result = CombatSim.simulate(3, COUPLE_A, FOES_B, Config)
			expect(result.version).toBe(1)
			expect(CombatSim.VERSION).toBe(1)
			expect(result.turns > 0).toBe(true)
			expect(result.actions).toBe(#result.actionLog)
			expect(result.mvp ~= nil).toBe(true)
			for index, entry in result.actionLog do
				expect(entry.t).toBe(index)
				expect(type(entry.actor)).toBe("string")
				expect(string.match(entry.actor, "^[%w%-]+%.[AB]%d$") ~= nil).toBe(true)
				expect(type(entry.action)).toBe("string")
				expect(#entry.values).toBe(#entry.targets)
				expect(#entry.crits).toBe(#entry.targets)
				expect(type(entry.statuses.applied)).toBe("table")
				expect(type(entry.statuses.removed)).toBe("table")
				expect(type(entry.gauges.energy)).toBe("number")
				expect(type(entry.gauges.mega)).toBe("number")
				expect(type(entry.hp)).toBe("table")
				expect(type(entry.kos)).toBe("table")
			end
		end
	)
end)
