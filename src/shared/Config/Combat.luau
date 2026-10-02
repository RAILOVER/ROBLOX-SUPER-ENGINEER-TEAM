--!strict
-- Constantes du combat au tour par tour (brief §7.3, §11). Module pur, sans require.
-- Gabarit par classe au niveau 11, 1 etoile; multiplie ensuite par le coefficient de rarete et statOverrides.

export type ClassTemplate = {
	HP: number,
	ATQ: number,
	MAG: number,
	DEF: number,
	RES: number,
	VIT: number,
	range: "Melee" | "Ranged" | "MeleeBackline",
	skillCost: number,
	critChance: number,
}

local Combat = {
	classes = {
		Colosse = {
			HP = 1400,
			ATQ = 70,
			MAG = 30,
			DEF = 60,
			RES = 50,
			VIT = 80,
			range = "Melee",
			skillCost = 100,
			critChance = 0.10,
		},
		Guerrier = {
			HP = 1100,
			ATQ = 110,
			MAG = 30,
			DEF = 40,
			RES = 35,
			VIT = 95,
			range = "Melee",
			skillCost = 90,
			critChance = 0.10,
		},
		Assassin = {
			HP = 800,
			ATQ = 140,
			MAG = 30,
			DEF = 25,
			RES = 25,
			VIT = 120,
			range = "MeleeBackline",
			skillCost = 80,
			critChance = 0.20,
		},
		Artilleur = {
			HP = 750,
			ATQ = 120,
			MAG = 60,
			DEF = 20,
			RES = 30,
			VIT = 100,
			range = "Ranged",
			skillCost = 100,
			critChance = 0.10,
		},
		Soigneur = {
			HP = 800,
			ATQ = 50,
			MAG = 110,
			DEF = 30,
			RES = 45,
			VIT = 105,
			range = "Ranged",
			skillCost = 70,
			critChance = 0.10,
		},
		Mage = {
			HP = 750,
			ATQ = 40,
			MAG = 130,
			DEF = 25,
			RES = 45,
			VIT = 100,
			range = "Ranged",
			skillCost = 100,
			critChance = 0.10,
		},
		Sprinteur = {
			HP = 850,
			ATQ = 100,
			MAG = 30,
			DEF = 30,
			RES = 30,
			VIT = 140,
			range = "Melee",
			skillCost = 80,
			critChance = 0.10,
		},
	} :: { [string]: ClassTemplate },
	classOrder = { "Colosse", "Guerrier", "Assassin", "Artilleur", "Soigneur", "Mage", "Sprinteur" },
	maxStatOverride = 0.15, -- ±15 % autour du gabarit (Game Designer)

	-- §11.2 timeline : chaque unite avance de VIT par tick, agit a timelineThreshold, repart de 0.
	-- Position de depart tiree dans [0, timelineStartRandomMax] + timelineStartVitMult * VIT.
	timelineThreshold = 1000,
	timelineStartRandomMax = 200,
	timelineStartVitMult = 2,
	guardTimelineAdvance = 0.30, -- Garde : l'unite reprend a 30 % du seuil au lieu de 0
	-- §11.3 energie : 20 au debut du combat, 100 max, +20 par attaque de base, +10 par coup recu, +30 par Garde.
	energyStart = 20,
	energyMax = 100,
	energyPerBasicAttack = 20,
	energyPerHitTaken = 10,
	guardDamageReduction = 0.50, -- Garde : -50 % degats subis jusqu'au prochain tour de l'unite
	guardEnergyGain = 30,
	-- §11.4 actions : Attaque de base, Duo (energie partagee), ordre Focus manuel
	basicAttackPower = 1.00, -- physique, ATQ contre DEF
	basicAttackMagicPower = 0.80, -- Soigneur et Mage : MAG contre RES
	magicBasicAttackClasses = { "Soigneur", "Mage" },
	duoEnergyCost = 50, -- par partenaire; les 2 partenaires doivent etre vivants et sans controle
	duoPowerMultiplier = 1.20, -- Duo : chaque partenaire inflige une Attaque de base x 1.20 sur la meme cible
	focusOrdersPerCombat = 1,
	focusTurns = 2, -- toute l'equipe vise la cible pendant 2 tours d'equipe
	-- §11.5 formules
	damageVariance = { 0.95, 1.05 },
	critMultiplier = 1.5,
	minimumDamage = 1,
	-- §11.10 limites : apres suddenDeathAfterActions, degats x (1 + ramp) ^ (actions - 40)
	suddenDeathAfterActions = 40,
	suddenDeathDamageRamp = 0.25,
	drawAfterActions = 60,
	-- §9.1 jauge Mega (par equipe)
	megaGaugeMax = 100,
	megaGainPerSynergyAction = 4,
	megaGainPerKO = 8,
	megaUsesPerComboPerCombat = 1, -- chaque combo 1 fois par combat, jauge remise a 0 apres
	megaAutoTriggerSeconds = 8, -- PvP : combo lance seul apres 8 s sans action du joueur
	-- §10.6 plateau 2 lignes x 4 colonnes
	boardRows = 2,
	boardColumns = 4,
	-- §11.6 statuts : valeurs de reference, listees dans un ordre fixe
	statuses = {
		Etourdi = { kind = "control", turns = 1 },
		Endormi = { kind = "control", turns = 1, breaksOnDamage = true },
		Charme = { kind = "control", turns = 1 },
		HorsCombat = { kind = "control", turns = 2, bossImmune = true },
		Ralenti = { kind = "debuff", VIT = -0.30 },
		Enracine = { kind = "debuff", VIT = -0.50 },
		Brulure = { kind = "dot", hpMaxPerTurn = 0.05 },
		Saignement = { kind = "dot", hpMaxPerTurn = 0.04, maxStacks = 3 },
		Expose = { kind = "debuff", damageTaken = 0.25 },
		Bouclier = { kind = "buff" },
		Provocation = { kind = "buff" },
		Invisible = { kind = "buff" },
		Epines = { kind = "buff" },
	},
	controlImmunityTurnsAfterControl = 1,
	bossControlResistance = 0.50,
	-- §11.7 tactiques automatiques. Seuils de Garde revises par D-10 (T-0024) : le brief donnait 0.25 / 0.40, mesure
	-- au miroir R-M1-54 Agressif 88 % / Prudent 7 % ; avec 0.20 / 0.25 et le ciblage R-M1-52 revise : 54 % / 43 %.
	tactics = {
		Agressif = { guardBelowHp = 0, healerHoldsSkillAboveAllyHp = 0 },
		Equilibre = { guardBelowHp = 0.20, healerHoldsSkillAboveAllyHp = 0.70 },
		Prudent = { guardBelowHp = 0.25, healerHoldsSkillAboveAllyHp = 0.85 },
	},
	manualTurnSeconds = 15, -- §11.8
	pvpActionAnimationMaxSeconds = 0.8, -- §11.9
}

for _, template in Combat.classes do
	table.freeze(template)
end

return table.freeze(Combat)
