--!strict
-- Boutique du duel (spec M1-duel-minimal D-M1-01, D-M1-02, D-M1-08, D-M1-10). Module pur, Rng seedable injecte.
-- Le pool d'un siege est un dictionnaire slug -> exemplaires restants ; le tirage retire les copies, la relance et
-- le debut de manche remettent les cartes non vendues, la vente rend 3 ^ (etoiles - 1) exemplaires.

local Types = require(script.Parent.Parent.Types.Combat)
local DuelTypes = require(script.Parent.Parent.Types.Duel)

type Config = Types.CombatConfig
type Rng = Types.Rng
type ShopSlot = DuelTypes.ShopSlot
type OwnedUnit = DuelTypes.OwnedUnit

local Shop = {}

Shop.EMPTY_SLUG = ""

-- D-M1-01 : pool = poolCopies de la rarete pour chaque carte du deck.
function Shop.newPool(config: Config, deck: { string }): { [string]: number }
	local pool: { [string]: number } = {}
	for _, slug in deck do
		local def = config.Roster.units[slug]
		assert(def ~= nil, `carte inconnue dans le deck : {slug}`)
		pool[slug] = config.Rarities.byName[def.rarity].poolCopies
	end
	return pool
end

function Shop.poolTotal(pool: { [string]: number }): number
	local total = 0
	for _, copies in pool do
		total += copies
	end
	return total
end

-- Couts (1 a 5) qui ont encore au moins 1 exemplaire dans le pool.
local function availableCosts(config: Config, pool: { [string]: number }): { [number]: boolean }
	local costs: { [number]: boolean } = {}
	for slug, copies in pool do
		if copies > 0 then
			local def = config.Roster.units[slug]
			costs[config.Rarities.byName[def.rarity].duelCost] = true
		end
	end
	return costs
end

-- Tirage du cout selon Duel.shopOdds[level] (D-M1-08). Le niveau est borne a la table.
function Shop.rollCost(config: Config, rng: Rng, level: number): number
	local odds =
		config.Duel.shopOdds[math.clamp(level, config.Duel.startLevel, config.Duel.maxLevel)]
	local u = rng:NextNumber()
	local cumulative = 0
	for cost, probability in ipairs(odds) do
		cumulative += probability
		if u < cumulative then
			return cost
		end
	end
	return #odds
end

-- D-M1-02 : repli sur le cout disponible le plus proche en dessous, sinon le plus proche au-dessus, nil si vide.
function Shop.fallbackCost(cost: number, available: { [number]: boolean }): number?
	for candidate = cost, 1, -1 do
		if available[candidate] then
			return candidate
		end
	end
	for candidate = cost + 1, 5 do
		if available[candidate] then
			return candidate
		end
	end
	return nil
end

-- Carte tiree parmi les slugs du cout voulu, ponderee par les exemplaires restants (ordre des slugs trie : determinisme).
local function pickSlug(config: Config, rng: Rng, pool: { [string]: number }, cost: number): string?
	local slugs: { string } = {}
	local total = 0
	for slug, copies in pool do
		local def = config.Roster.units[slug]
		if copies > 0 and config.Rarities.byName[def.rarity].duelCost == cost then
			table.insert(slugs, slug)
			total += copies
		end
	end
	if total == 0 then
		return nil
	end
	table.sort(slugs)
	local target = rng:NextInteger(1, total)
	for _, slug in slugs do
		target -= pool[slug]
		if target <= 0 then
			return slug
		end
	end
	return slugs[#slugs]
end

-- Tire `Duel.shopSlots` cartes et les retire du pool. Un emplacement sans carte possible est vide et deja `sold`.
function Shop.roll(
	config: Config,
	rng: Rng,
	pool: { [string]: number },
	level: number
): { ShopSlot }
	local slots: { ShopSlot } = {}
	for _ = 1, config.Duel.shopSlots do
		local wanted = Shop.rollCost(config, rng, level)
		local cost = Shop.fallbackCost(wanted, availableCosts(config, pool))
		local slug = if cost then pickSlug(config, rng, pool, cost) else nil
		if slug == nil or cost == nil then
			table.insert(slots, { slug = Shop.EMPTY_SLUG, cost = 0, sold = true })
		else
			pool[slug] -= 1
			table.insert(slots, { slug = slug, cost = cost, sold = false })
		end
	end
	return slots
end

-- Remet au pool les cartes non vendues (relance, debut de manche) et marque les emplacements vendus.
function Shop.returnUnsold(pool: { [string]: number }, slots: { ShopSlot }): ()
	for _, slot in slots do
		if not slot.sold then
			pool[slot.slug] = (pool[slot.slug] or 0) + 1
			slot.sold = true
		end
	end
end

-- Exemplaires que represente une unite (1, 3 ou 9) : rendus au pool a la vente.
function Shop.copiesOf(stars: number): number
	return 3 ^ (stars - 1)
end

function Shop.returnCopies(pool: { [string]: number }, slug: string, stars: number): ()
	pool[slug] = (pool[slug] or 0) + Shop.copiesOf(stars)
end

-- D-M1-10 : les 3 exemplaires identiques (slug, etoiles) presents dans `units`, ou nil s'il y en a moins de 3.
function Shop.findTriple(units: { OwnedUnit }, slug: string, stars: number): { OwnedUnit }?
	local found: { OwnedUnit } = {}
	for _, unit in units do
		if unit.slug == slug and unit.stars == stars then
			table.insert(found, unit)
			if #found == 3 then
				return found
			end
		end
	end
	return nil
end

-- Part de chaque cout dans une liste d'emplacements (outil de test et de doc).
function Shop.costShares(slots: { ShopSlot }): { [number]: number }
	local shares: { [number]: number } = {}
	local count = 0
	for _, slot in slots do
		if slot.slug ~= Shop.EMPTY_SLUG then
			shares[slot.cost] = (shares[slot.cost] or 0) + 1
			count += 1
		end
	end
	for cost, n in shares do
		shares[cost] = n / math.max(count, 1)
	end
	return shares
end

return table.freeze(Shop)
