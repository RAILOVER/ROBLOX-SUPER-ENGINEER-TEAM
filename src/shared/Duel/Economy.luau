--!strict
-- Economie du duel (spec M1-duel-minimal D-M1-03, D-M1-07 a D-M1-10, D-M1-16 a D-M1-18). Module pur : toutes les
-- valeurs viennent de Config.Duel et Config.Rarities, injectees en parametre. Testable sous Lune.

local Types = require(script.Parent.Parent.Types.Combat)
local DuelTypes = require(script.Parent.Parent.Types.Duel)

type Config = Types.CombatConfig
type RoundOutcome = DuelTypes.RoundOutcome

export type Income = {
	base: number,
	interest: number,
	streak: number,
	winBonus: number,
	total: number,
}

local Economy = {}

-- D-M1-07 : interets = min(floor(or / interestPer), interestMax).
function Economy.interest(config: Config, gold: number): number
	local eco = config.Duel.economy
	return math.clamp(math.floor(math.max(gold, 0) / eco.interestPer), 0, eco.interestMax)
end

-- D-M1-07 : bonus de serie (victoires ou defaites consecutives), plafonne a la derniere cle de la table.
function Economy.streakBonus(config: Config, streak: number): number
	local table_ = config.Duel.economy.streak
	local maxKey = 0
	for key in table_ do
		maxKey = math.max(maxKey, key)
	end
	local bonus = table_[math.min(streak, maxKey)]
	return bonus or 0
end

-- D-M1-07 : revenu au debut de Preparation de la manche n >= 2.
function Economy.income(config: Config, gold: number, streak: number, wonLastRound: boolean): Income
	local eco = config.Duel.economy
	local interest = Economy.interest(config, gold)
	local streakBonus = Economy.streakBonus(config, streak)
	local winBonus = if wonLastRound then eco.winBonus else 0
	return {
		base = eco.baseIncome,
		interest = interest,
		streak = streakBonus,
		winBonus = winBonus,
		total = eco.baseIncome + interest + streakBonus + winBonus,
	}
end

function Economy.rerollCost(config: Config): number
	return config.Duel.economy.rerollCost
end

function Economy.xpCost(config: Config): number
	return config.Duel.economy.xpCost
end

-- D-M1-09 : XP necessaire pour quitter `level`, 0 au niveau maximum.
function Economy.xpToNext(config: Config, level: number): number
	if level >= config.Duel.maxLevel then
		return 0
	end
	return config.Duel.xpToNext[level] or 0
end

-- Ajoute `amount` XP et monte de niveau autant de fois que possible (max maxLevel). Retourne niveau, xp.
function Economy.addXp(config: Config, level: number, xp: number, amount: number): (number, number)
	local newLevel, newXp = level, xp + amount
	while newLevel < config.Duel.maxLevel do
		local needed = Economy.xpToNext(config, newLevel)
		if needed <= 0 or newXp < needed then
			break
		end
		newXp -= needed
		newLevel += 1
	end
	if newLevel >= config.Duel.maxLevel then
		newXp = 0
	end
	return newLevel, newXp
end

-- D-M1-10 : prix de vente par etoile.
function Economy.sellValue(config: Config, slug: string, stars: number): number
	local def = config.Roster.units[slug]
	local cost = config.Rarities.byName[def.rarity].duelCost
	if stars >= 3 then
		return 9 * cost - 1
	elseif stars == 2 then
		return 3 * cost - 1
	end
	return cost
end

-- Cout d'achat d'une carte en boutique.
function Economy.cardCost(config: Config, slug: string): number
	local def = config.Roster.units[slug]
	return config.Rarities.byName[def.rarity].duelCost
end

-- D-M1-16 : palier = min(ceil(manche / 3), playerDamageTierCap).
function Economy.tier(config: Config, round: number): number
	return math.min(math.ceil(round / 3), config.Duel.playerDamageTierCap)
end

-- D-M1-17 : degats au perdant d'une manche PvP.
function Economy.playerDamage(config: Config, round: number, survivingStars: number): number
	local duel = config.Duel
	return duel.playerDamageBase
		+ duel.playerDamageTierMult * Economy.tier(config, round)
		+ duel.playerDamageStarMult * survivingStars
end

-- D-M1-18 : manche nulle, chaque joueur perd la moitie (arrondi inferieur).
function Economy.drawDamage(config: Config, round: number, survivingStars: number): number
	return math.floor(Economy.playerDamage(config, round, survivingStars) / 2)
end

-- D-M1-05 : duree de Preparation selon la manche ; 3 s quand les 2 sieges sont prets.
function Economy.prepSeconds(config: Config, round: number, bothReady: boolean): number
	local duel = config.Duel
	if bothReady then
		return duel.prepReadySkipSeconds
	end
	return if round <= duel.prepSecondsEarlyRounds
		then duel.prepSecondsEarly
		else duel.prepSecondsLate
end

-- Mise a jour de la serie apres une manche : meme sens que la precedente => +1, sens oppose => 1, nul => inchangee.
function Economy.nextStreak(
	streak: number,
	lastOutcome: RoundOutcome?,
	outcome: RoundOutcome
): number
	if outcome == "draw" then
		return streak
	end
	if lastOutcome == nil or lastOutcome == "draw" or streak == 0 then
		return 1
	end
	return if lastOutcome == outcome then streak + 1 else 1
end

return table.freeze(Economy)
