--!strict
-- Couverture M-C-05, regles R-M1-01 a R-M1-30 (design/specs/M1-combat-tour-par-tour.md).

local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")
local Actions = loadShared("Combat/Actions")
local Effects = loadShared("Combat/Effects")
local Formulas = loadShared("Combat/Formulas")
local SkillEffects = loadShared("Combat/SkillEffects")
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

-- Fait agir `unit` au prochain step.
local function force(state, unit)
	for _, other in state.units do
		other.timeline = 0
	end
	unit.timeline = Config.Combat.timelineThreshold
	state.lastActedSide = nil
end

-- Rng fixe : variance 1,0 ; NextNumber() = `roll` (0,99 => jamais de critique).
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

describe("R-M1-01 a R-M1-09 : unites et timeline", function()
	it(
		"R-M1-01 : glorbo-fruttodrillo 1 etoile HP 1540, ATQ 77, VIT 88 ; 2 etoiles HP 2772 (VIT inchangee)",
		function()
			local s = Formulas.buildStats(Config, "glorbo-fruttodrillo", 1)
			expect(s.HP).toBe(1540)
			expect(s.ATQ).toBe(77)
			expect(s.VIT).toBe(88)
			local s2 = Formulas.buildStats(Config, "glorbo-fruttodrillo", 2)
			expect(s2.HP).toBe(2772)
			expect(s2.VIT).toBe(88)
		end
	)

	it(
		"R-M1-02 : Colosse 2 => HPmax x1,20 ; les pourcentages s'additionnent ; FlatMAG ajoute",
		function()
			local state =
				newState({ u("glorbo-fruttodrillo", 1, 1), u("boneca-ambalabu", 1, 2) }, FOES_B)
			expect(state.teams.A.activeSynergies.Colosse).toBe(1)
			expect(find(state, "glorbo-fruttodrillo", "A").hpMax).toBe(1848)
			local base = { HP = 1000, ATQ = 100, MAG = 100, DEF = 10, RES = 10, VIT = 10 }
			expect(Formulas.applyStatBonuses(base, { HP = 0.4 }, {}).HP).toBe(1400)
			expect(Formulas.applyStatBonuses(base, {}, { MAG = 20 }).MAG).toBe(120)
		end
	)

	it("R-M1-03 : 4 compteurs ; hp <= 0 => K.O., plus ciblable, statuts effaces", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		expect(banano.energy).toBe(20)
		expect(banano.hp).toBe(banano.hpMax)
		expect(#banano.statuses).toBe(0)
		local foe = find(state, "trippi-troppi")
		Status.apply(state, foe, "Brulure")
		Status.knockOut(state, foe)
		expect(foe.alive).toBe(false)
		expect(#foe.statuses).toBe(0)
		expect(#Targeting.aliveEnemies(state, banano)).toBe(1)
	end)

	it("R-M1-04 : timeline initiale dans [2 x VIT, 200 + 2 x VIT]", function()
		local state = newState(COUPLE_A, FOES_B)
		for _, unit in state.units do
			expect(unit.timeline >= 2 * unit.stats.VIT).toBe(true)
			expect(unit.timeline <= 200 + 2 * unit.stats.VIT).toBe(true)
		end
	end)

	it(
		"R-M1-05 : VIT effective = floor(VIT x 0,70 x 0,50), minimum 1 ; HorsCombat n'avance pas",
		function()
			expect(Formulas.effectiveVit(100, { 0.7, 0.5 })).toBe(35)
			expect(Formulas.effectiveVit(1, { 0.5 })).toBe(1)
			local state = newState(COUPLE_A, FOES_B)
			local banano, foe = find(state, "banano"), find(state, "trippi-troppi")
			Status.apply(state, foe, "HorsCombat")
			local before, foeBefore = banano.timeline, foe.timeline
			Timeline.tick(state)
			expect(banano.timeline).toBe(before + banano.stats.VIT)
			expect(foe.timeline).toBe(foeBefore)
		end
	)

	it(
		"R-M1-06 : VIT la plus haute, puis camp alterne (A au debut), puis case la plus basse",
		function()
			local state = newState(
				{ u("pomito", 1, 1), u("trippi-troppi", 1, 2) },
				{ u("pomito", 1, 1) }
			)
			local a, b, fast =
				find(state, "pomito", "A"), find(state, "pomito", "B"), find(state, "trippi-troppi")
			expect(Timeline.pick(state, { a, b, fast }, nil)).toBe(fast)
			expect(Timeline.pick(state, { b, a }, nil)).toBe(a)
			expect(Timeline.pick(state, { a, b }, "A")).toBe(b)
			local state2 = newState({ u("pomito", 2, 1), u("pomito", 1, 1) }, FOES_B)
			local picked =
				Timeline.pick(state2, { state2.teams.A.units[2], state2.teams.A.units[1] }, nil)
			expect(picked.cell).toBe(0)
		end
	)

	it("R-M1-07 : timeline = 0 apres action, 300 apres Garde", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		Timeline.afterAction(state, banano, false)
		expect(banano.timeline).toBe(0)
		Timeline.afterAction(state, banano, true)
		expect(banano.timeline).toBe(300)
	end)

	it("R-M1-08 : Etourdi => Skip, 1 action, timeline 0, statut decremente", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		Status.apply(state, banano, "Etourdi")
		force(state, banano)
		CombatSim.step(state)
		expect(state.log[1].action).toBe("Skip")
		expect(state.log[1].actor).toBe("banano.A1")
		expect(state.actions).toBe(1)
		expect(banano.timeline).toBe(0)
		expect(Status.has(banano, "Etourdi")).toBe(false)
	end)

	it("R-M1-09 : preview(state, 10) donne 10 acteurs et le 1er est l'acteur reel", function()
		local state = newState(COUPLE_A, FOES_B)
		local preview = CombatSim.preview(state, 10)
		expect(#preview).toBe(10)
		local actor = Timeline.nextActor(state)
		expect(preview[1].side .. preview[1].cell).toBe(actor.side .. actor.cell)
	end)
end)

describe("R-M1-10 a R-M1-15 : formules et energie", function()
	it(
		"R-M1-10 : base = power x ATQ x 100 / (100 + DEF), variance, critique x1,5, mods, minimum 1",
		function()
			expect(Formulas.damage(Config, 1, 100, 100, fixedRng(), 0, 1.5, {})).toBe(50)
			expect(Formulas.damage(Config, 1, 100, 100, fixedRng(), 0, 1.5, { 2 })).toBe(100)
			local crit, isCrit = Formulas.damage(Config, 1, 100, 100, fixedRng(0), 0.1, 1.5, {})
			expect(crit).toBe(75)
			expect(isCrit).toBe(true)
			expect(Formulas.damage(Config, 1, 1, 10000, fixedRng(), 0, 1.5, {})).toBe(1)
		end
	)

	it("R-M1-11 : heal = floor(power x MAG x (1 + HealPct) + 0,5)", function()
		expect(Formulas.heal(2.5, 110, 0.2)).toBe(330)
		expect(Formulas.heal(1, 100, 0)).toBe(100)
	end)

	it(
		"R-M1-12 : Attaque physique power 1,00 ; Soigneur et Mage 0,80 avec MAG contre RES",
		function()
			expect(Config.Combat.basicAttackPower).toBe(1)
			expect(Config.Combat.basicAttackMagicPower).toBe(0.8)
			local state = newState({ u("pomita", 1, 1) }, { u("pomito", 1, 1) })
			state.rng = fixedRng()
			local pomita, pomito = find(state, "pomita"), find(state, "pomito")
			open(state, pomita)
			Actions.attack(state, pomita)
			local expected =
				math.floor(0.8 * pomita.stats.MAG * 100 / (100 + pomito.stats.RES) + 0.5)
			expect(state.currentEntry.values[1]).toBe(expected)
		end
	)

	it("R-M1-13 : mods dans l'ordre competence, synergie, Expose, Garde, mort subite", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano, foe = find(state, "banano"), find(state, "trippi-troppi")
		Status.apply(state, foe, "Expose")
		foe.guarding = true
		state.actions = 44
		local mods = Effects.buildMods(state, banano, foe, 0.25, false)
		expect(#mods).toBe(4)
		expect(mods[1]).toBe(1.25)
		expect(mods[2]).toBe(1.25)
		expect(mods[3]).toBe(0.5)
		expect(mods[4]).toBeCloseTo(2.44, 2)
	end)

	it(
		"R-M1-14 : 1000 degats sur 300 de Bouclier et 1200 PV => bouclier 0, PV 500, +10 energie",
		function()
			local state = newState(COUPLE_A, FOES_B)
			state.rng = fixedRng()
			local banano, foe = find(state, "banano"), find(state, "trippi-troppi")
			banano.stats.ATQ = 1000
			foe.stats.DEF = 0
			foe.hpMax, foe.hp = 1200, 1200
			Status.apply(state, foe, "Bouclier", { shield = 300 })
			open(state, banano)
			expect(Actions.dealDamage(state, banano, foe, 1)).toBe(1000)
			expect(Status.has(foe, "Bouclier")).toBe(false)
			expect(foe.hp).toBe(500)
			expect(foe.energy).toBe(30)
		end
	)

	it(
		"R-M1-15 : energie 20 au depart, bornee a 100 ; Tentafruit 2 => gain x1,15 arrondi inferieur",
		function()
			expect(Config.Combat.energyStart).toBe(20)
			local state = newState({ u("tim-cheese", 1, 1) }, FOES_B)
			local tim = find(state, "tim-cheese")
			tim.energy = 95
			Actions.gainEnergy(state, tim, 20)
			expect(tim.energy).toBe(100)
			local couple = newState(COUPLE_A, FOES_B)
			expect(couple.teams.A.activeSynergies.Tentafruit).toBe(1)
			local banano = find(couple, "banano")
			Actions.gainEnergy(couple, banano, 10)
			expect(banano.energy).toBe(31)
		end
	)
end)

describe("R-M1-16 a R-M1-24 : les 5 actions", function()
	it("R-M1-16 : 4 Attaques depuis 20 donnent exactement 100", function()
		local state = newState({ u("tim-cheese", 1, 1) }, { u("trippi-troppi", 1, 1) })
		local tim, foe = find(state, "tim-cheese"), find(state, "trippi-troppi")
		foe.hpMax, foe.hp = 1e9, 1e9
		for _ = 1, 4 do
			open(state, tim)
			expect(Actions.attack(state, tim)).toBe(true)
		end
		expect(tim.energy).toBe(100)
	end)

	it(
		"R-M1-17 : couts par classe ; la competence debite skillCost sans donner energyPerBasicAttack",
		function()
			local costs = {
				Colosse = 100,
				Guerrier = 90,
				Assassin = 80,
				Artilleur = 100,
				Soigneur = 70,
				Mage = 100,
				Sprinteur = 80,
			}
			for class, cost in costs do
				expect(Config.Combat.classes[class].skillCost).toBe(cost)
			end
			local state = newState({ u("pomito", 1, 1) }, { u("trippi-troppi", 1, 1) })
			local pomito = find(state, "pomito")
			pomito.energy = 100
			open(state, pomito)
			expect(SkillEffects.run(state, pomito)).toBe(true)
			expect(pomito.energy).toBe(10)
			expect(state.currentEntry.skillId).toBe("CroquePomme")
		end
	)

	it(
		"R-M1-18 : Garde => guarding, degats x0,50, +30 energie, timeline 300, leve a l'action suivante",
		function()
			local state = newState(COUPLE_A, { u("trippi-troppi", 1, 1) })
			state.rng = fixedRng()
			local banano, foe = find(state, "banano"), find(state, "trippi-troppi")
			open(state, foe)
			local plain = Actions.dealDamage(state, foe, banano, 1)
			local energyBefore = banano.energy
			Actions.guard(state, banano)
			expect(banano.guarding).toBe(true)
			expect(banano.energy).toBe(energyBefore + math.floor(30 * 1.15))
			local guarded = Actions.dealDamage(state, foe, banano, 1)
			expect(guarded < plain).toBe(true)
			expect(guarded).toBeLessThanOrEqual(math.ceil(plain * 0.5))
			Timeline.afterAction(state, banano, true)
			expect(banano.timeline).toBe(300)
			Actions.finishEntry(state, foe)
			force(state, banano)
			CombatSim.step(state)
			expect(banano.guarding).toBe(false)
		end
	)

	it(
		"R-M1-19 : Duo si Couple 1, partenaire vivant sans controle, 50 energie chacun ; 2 Attaques x1,20",
		function()
			local state = newState(COUPLE_A, FOES_B)
			local banano, bananella = find(state, "banano"), find(state, "bananella")
			expect(Tactics.duoPartner(state, banano)).toBeNil()
			banano.energy, bananella.energy = 50, 50
			expect(Tactics.duoPartner(state, banano)).toBe(bananella)
			Status.apply(state, bananella, "Etourdi")
			expect(Tactics.duoPartner(state, banano)).toBeNil()
			Status.remove(state, bananella, "Etourdi")
			bananella.energy = 49
			expect(Tactics.duoPartner(state, banano)).toBeNil()
			bananella.energy = 50
			local solo = newState({ u("banano", 1, 1) }, FOES_B)
			find(solo, "banano").energy = 100
			expect(Tactics.duoPartner(solo, find(solo, "banano"))).toBeNil()
			local partnerTimeline = bananella.timeline
			open(state, banano)
			expect(Actions.duo(state, banano, bananella)).toBe(true)
			expect(banano.energy).toBe(0)
			expect(bananella.energy).toBe(0)
			expect(#state.currentEntry.values).toBe(2)
			expect(state.currentEntry.targets[1]).toBe(state.currentEntry.targets[2])
			expect(bananella.timeline).toBe(partnerTimeline)
		end
	)

	it("R-M1-20 : le Mega Combo s'insere avant la prochaine action alliee", function()
		local state = newState(COUPLE_A, FOES_B)
		state.teams.A.mega = 100
		local banano = find(state, "banano")
		force(state, banano)
		CombatSim.step(state)
		expect(state.log[1].action).toBe("Mega")
		expect(state.log[2].actor).toBe("banano.A1")
		expect(state.actions).toBe(2)
	end)

	it("R-M1-21 : Charme => Attaque sur un allie au hasard ; seule => Skip", function()
		local state = newState(COUPLE_A, FOES_B)
		local banano = find(state, "banano")
		Status.apply(state, banano, "Charme")
		force(state, banano)
		CombatSim.step(state)
		expect(state.log[1].action).toBe("Attack")
		expect(state.log[1].targets[1]).toBe("A5")
		local solo = newState({ u("banano", 1, 1) }, FOES_B)
		local alone = find(solo, "banano")
		Status.apply(solo, alone, "Charme")
		force(solo, alone)
		CombatSim.step(solo)
		expect(solo.log[1].action).toBe("Skip")
	end)

	it("R-M1-22 : Ta-ta-ta-ta reveille les allies puis 50 % d'Endormi sur 1 ennemi", function()
		local state = newState(
			{ u("ta-ta-ta-ta-sahur", 2, 1), u("banano", 1, 1) },
			{ u("pomito", 1, 1) }
		)
		local mage, banano, foe =
			find(state, "ta-ta-ta-ta-sahur"), find(state, "banano"), find(state, "pomito")
		Status.apply(state, banano, "Endormi")
		mage.energy = 100
		state.rng = fixedRng(0.99)
		open(state, mage)
		expect(SkillEffects.run(state, mage)).toBe(true)
		expect(Status.has(banano, "Endormi")).toBe(false)
		expect(Status.has(foe, "Endormi")).toBe(false)
		state.rng = fixedRng(0.1)
		mage.energy = 100
		SkillEffects.run(state, mage)
		expect(Status.has(foe, "Endormi")).toBe(true)
	end)

	it(
		"R-M1-23 : Grignotage = 2 Attaques sur la meme cible, 1 action, 1 seul gain d'energie pour la cible",
		function()
			local state = newState({ u("tim-cheese", 1, 1) }, { u("trippi-troppi", 1, 1) })
			local tim, foe = find(state, "tim-cheese"), find(state, "trippi-troppi")
			foe.hpMax, foe.hp = 1e9, 1e9
			tim.energy = 100
			force(state, tim)
			CombatSim.step(state)
			local entry = state.log[1]
			expect(entry.action).toBe("Skill")
			expect(#entry.values).toBe(2)
			expect(entry.targets[1]).toBe(entry.targets[2])
			expect(state.actions).toBe(1)
			expect(foe.energy).toBe(30)
		end
	)

	it(
		"R-M1-24 : Provocation 1 tour ; Machoire soigne floor(0,30 x degats) ; Rebond touche 3 ennemis",
		function()
			local state = newState(
				{ u("banano", 1, 1), u("glorbo-fruttodrillo", 1, 2), u("boneca-ambalabu", 1, 3) },
				{
					u("pomito", 1, 1),
					u("trippi-troppi", 1, 2),
					u("tim-cheese", 2, 1),
					u("bananella", 2, 2),
				}
			)
			local banano, glorbo, boneca =
				find(state, "banano"),
				find(state, "glorbo-fruttodrillo"),
				find(state, "boneca-ambalabu")
			banano.energy, glorbo.energy, boneca.energy = 100, 100, 100
			open(state, banano)
			SkillEffects.run(state, banano)
			expect(Status.get(banano, "Provocation").turns).toBe(1)
			expect(Status.get(banano, "Bouclier").shield).toBe(math.floor(0.2 * banano.hpMax))
			glorbo.hp = glorbo.hpMax - 500
			open(state, glorbo)
			SkillEffects.run(state, glorbo)
			local dealt = state.currentEntry.values[1]
			expect(glorbo.hp).toBe(glorbo.hpMax - 500 + math.floor(0.3 * dealt))
			expect(Status.has(glorbo, "Provocation")).toBe(true)
			open(state, boneca)
			SkillEffects.run(state, boneca)
			local entry = state.currentEntry
			expect(#entry.targets).toBe(3)
			expect(entry.targets[1] ~= entry.targets[2] and entry.targets[2] ~= entry.targets[3]).toBe(
				true
			)
		end
	)
end)

describe("R-M1-25 a R-M1-30 : ciblage et jauge Mega", function()
	local FRONT_BACK =
		{ u("pomito", 1, 1), u("trippi-troppi", 1, 2), u("tim-cheese", 2, 1), u("bananella", 2, 2) }

	it("R-M1-25 : Melee => ligne avant, sinon ligne arriere", function()
		local state = newState({ u("banano", 1, 1) }, FRONT_BACK)
		local banano = find(state, "banano")
		local pool = Targeting.candidates(state, banano)
		expect(#pool).toBe(2)
		expect(pool[1].row).toBe(1)
		Status.knockOut(state, find(state, "pomito"))
		Status.knockOut(state, find(state, "trippi-troppi"))
		pool = Targeting.candidates(state, banano)
		expect(#pool).toBe(2)
		expect(pool[1].row).toBe(2)
	end)

	it("R-M1-26 : Ranged et MeleeBackline => tous les ennemis vivants", function()
		local state = newState({ u("bananella", 2, 1), u("trippi-troppi", 1, 1) }, FRONT_BACK)
		expect(#Targeting.candidates(state, find(state, "bananella", "A"))).toBe(4)
		expect(#Targeting.candidates(state, find(state, "trippi-troppi", "A"))).toBe(4)
	end)

	it(
		"R-M1-27 : Provocation force la cible ; Invisible retire des cibles ; toutes Invisible => cible quand meme",
		function()
			local state = newState({ u("bananella", 2, 1) }, FRONT_BACK)
			local shooter = find(state, "bananella", "A")
			local tim = find(state, "tim-cheese")
			Status.apply(state, tim, "Provocation")
			local pool = Targeting.candidates(state, shooter)
			expect(#pool).toBe(1)
			expect(pool[1]).toBe(tim)
			Status.remove(state, tim, "Provocation")
			Status.apply(state, tim, "Invisible")
			expect(#Targeting.candidates(state, shooter)).toBe(3)
			for _, foe in state.teams.B.units do
				Status.apply(state, foe, "Invisible")
			end
			expect(#Targeting.candidates(state, shooter)).toBe(4)
			expect(Targeting.single(state, shooter)).toBeTruthy()
		end
	)

	it("R-M1-28 : a egalite, la cible en face, puis la case la plus basse", function()
		local state = newState({ u("pomito", 1, 2) }, { u("pomito", 1, 1), u("pomito", 1, 2) })
		local attacker = find(state, "pomito", "A")
		expect(Targeting.single(state, attacker).cell).toBe(1)
		local state2 = newState({ u("pomito", 1, 4) }, { u("pomito", 1, 1), u("pomito", 1, 2) })
		expect(Targeting.single(state2, find(state2, "pomito", "A")).cell).toBe(0)
	end)

	it("R-M1-29 : soin sur l'allie au plus petit hp / HPmax ; a egalite le lanceur", function()
		local state = newState({ u("pomita", 2, 1), u("banano", 1, 1) }, FOES_B)
		local pomita, banano = find(state, "pomita"), find(state, "banano")
		expect(Targeting.healTarget(state, pomita)).toBe(pomita)
		banano.hp = math.floor(banano.hpMax * 0.5)
		expect(Targeting.healTarget(state, pomita)).toBe(banano)
	end)

	it("R-M1-30 : jauge mega par equipe, 0 au depart, bornee a 100", function()
		local state = newState(COUPLE_A, FOES_B)
		expect(state.teams.A.mega).toBe(0)
		expect(state.teams.B.mega).toBe(0)
		expect(Config.Combat.megaGaugeMax).toBe(100)
		state.teams.A.mega = 98
		Status.knockOut(state, find(state, "trippi-troppi"))
		expect(state.teams.A.mega).toBe(100)
	end)
end)
