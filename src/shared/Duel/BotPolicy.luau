--!strict
-- Politique du bot adversaire M1 (spec M1-duel-minimal §5, D-M1-24 a D-M1-32). Module pur : joue un siege a travers
-- DuelState.apply, memes regles que le joueur, deterministe a seed egale. DuelBot (serveur) ne fait que l'appeler.

local Types = require(script.Parent.Parent.Types.Combat)
local DuelTypes = require(script.Parent.Parent.Types.Duel)
local DuelState = require(script.Parent.DuelState)
local Economy = require(script.Parent.Economy)
local Rng = require(script.Parent.Parent.Combat.Rng)

type Config = Types.CombatConfig
type OwnedUnit = DuelTypes.OwnedUnit
type Seat = DuelTypes.Seat
type State = DuelTypes.State
type Plan = "Couple" | "Mare" | "Tank"
export type Brain = { seed: number, plan: Plan?, rerolledRound: number }

local BotPolicy = {}

-- D-M1-24 : a ajouter dans Config.Duel par le game designer (ticket ouvert par T-0011).
BotPolicy.THINK_SECONDS = 3
BotPolicy.PRUDENT_HP = 40
BotPolicy.PLAN_WEIGHTS = {
	{ plan = "Couple" :: Plan, weight = 0.5 },
	{ plan = "Mare" :: Plan, weight = 0.3 },
	{ plan = "Tank" :: Plan, weight = 0.2 },
}
BotPolicy.XP_ROUNDS = { [4] = true, [7] = true }
BotPolicy.XP_KEEP_GOLD = 12
BotPolicy.REROLL_KEEP_GOLD = 10
BotPolicy.ECONOMY_ROUND = 4

local FRONT_CLASSES: { [string]: boolean } = { Colosse = true, Guerrier = true, Sprinteur = true }
local CENTER_COLUMNS = { 2, 3, 1, 4 }

function BotPolicy.newBrain(seed: number): Brain
	return { seed = seed, plan = nil, rerolledRound = 0 }
end

-- D-M1-25 : cartes cibles d'un plan, par ordre de priorite.
function BotPolicy.planTargets(config: Config, plan: Plan): { string }
	local targets: { string } = {}
	local function addByFilter(
		predicate: (slug: string, def: typeof(config.Roster.units[""])) -> boolean
	)
		local found: { string } = {}
		for slug, def in config.Roster.units do
			if predicate(slug, def) then
				table.insert(found, slug)
			end
		end
		table.sort(found)
		for _, slug in found do
			if table.find(targets, slug) == nil then
				table.insert(targets, slug)
			end
		end
	end
	if plan == "Couple" then
		for _, slug in { "banano", "bananella", "pomito", "pomita" } do
			table.insert(targets, slug)
		end
		addByFilter(function(_, def)
			return def.class == "Soigneur"
		end)
	elseif plan == "Mare" then
		addByFilter(function(_, def)
			return table.find(def.families, "Mare") ~= nil
		end)
		table.insert(targets, "banano")
	else
		addByFilter(function(_, def)
			return def.class == "Colosse"
		end)
		addByFilter(function(_, def)
			return def.class == "Soigneur"
		end)
	end
	return targets
end

local function choosePlan(rng: Types.Rng): Plan
	local u = rng:NextNumber()
	local cumulative = 0
	for _, entry in BotPolicy.PLAN_WEIGHTS do
		cumulative += entry.weight
		if u < cumulative then
			return entry.plan
		end
	end
	return "Tank"
end

local function countSame(seat: Seat, slug: string, stars: number): number
	local n = 0
	for _, unit in seat.board do
		if unit.slug == slug and unit.stars == stars then
			n += 1
		end
	end
	for _, unit in seat.bench do
		if unit.slug == slug and unit.stars == stars then
			n += 1
		end
	end
	return n
end

-- Or que le bot refuse de depenser (D-M1-26) : 10 or des la manche 4 si son plateau est deja rempli.
local function reserve(config: Config, state: State, seat: Seat): number
	if state.round >= BotPolicy.ECONOMY_ROUND and #seat.board + #seat.bench >= seat.level then
		return config.Duel.economy.interestPer
	end
	return 0
end

-- Achete l'emplacement s'il est affordable en respectant la reserve. Retourne true si achete.
local function tryBuy(
	config: Config,
	state: State,
	seat: Seat,
	slotIndex: number,
	keep: number
): boolean
	local slot = seat.shop[slotIndex]
	if slot.sold or seat.gold - slot.cost < keep then
		return false
	end
	return DuelState.apply(config, state, seat.seatIndex, "BuyShopSlot", { slotIndex }).ok
end

local function shopHasPlanCard(seat: Seat, targets: { string }): boolean
	for _, slot in seat.shop do
		if not slot.sold and table.find(targets, slot.slug) then
			return true
		end
	end
	return false
end

-- D-M1-26 : (1) fusions, (2) plan, (3) hasard si le plateau n'est pas plein.
local function buyPass(
	config: Config,
	state: State,
	seat: Seat,
	targets: { string },
	rng: Types.Rng
)
	local keep = reserve(config, state, seat)
	for slotIndex, slot in seat.shop do
		if
			not slot.sold
			and (countSame(seat, slot.slug, 1) == 2 or countSame(seat, slot.slug, 2) == 2)
		then
			tryBuy(config, state, seat, slotIndex, 0)
		end
	end
	for _, target in targets do
		for slotIndex, slot in seat.shop do
			if not slot.sold and slot.slug == target then
				tryBuy(config, state, seat, slotIndex, keep)
			end
		end
	end
	local candidates: { number } = {}
	for slotIndex, slot in seat.shop do
		if not slot.sold then
			table.insert(candidates, slotIndex)
		end
	end
	while #candidates > 0 and #seat.board + #seat.bench < seat.level do
		local pick = table.remove(candidates, rng:NextInteger(1, #candidates)) :: number
		tryBuy(config, state, seat, pick, keep)
	end
end

-- D-M1-29 : ligne par classe, colonne la plus centrale libre, partenaires de duo dans la meme colonne.
local function targetCell(config: Config, seat: Seat, unit: OwnedUnit): (number?, number?)
	local def = config.Roster.units[unit.slug]
	local row = if FRONT_CLASSES[def.class] then 1 else 2
	local taken: { [number]: boolean } = {}
	for _, placed in seat.board do
		if placed.row == row then
			taken[placed.col] = true
		end
	end
	for _, placed in seat.board do
		if
			placed.row ~= row
			and table.find(def.duoPartners, placed.slug)
			and not taken[placed.col]
		then
			return row, placed.col
		end
	end
	for _, col in CENTER_COLUMNS do
		if not taken[col] then
			return row, col
		end
	end
	return nil
end

-- Monte sur le plateau, meilleures unites d'abord (etoiles puis cout), tant que le niveau le permet.
local function placePass(config: Config, state: State, seat: Seat)
	local bench = table.clone(seat.bench)
	table.sort(bench, function(a, b)
		if a.stars ~= b.stars then
			return a.stars > b.stars
		end
		local costA, costB = Economy.cardCost(config, a.slug), Economy.cardCost(config, b.slug)
		if costA ~= costB then
			return costA > costB
		end
		return a.instanceId < b.instanceId
	end)
	for _, unit in bench do
		if #seat.board >= seat.level then
			break
		end
		local row, col = targetCell(config, seat, unit)
		if row and col then
			DuelState.apply(
				config,
				state,
				seat.seatIndex,
				"PlaceUnit",
				{ unit.instanceId, row, col }
			)
		end
	end
end

-- D-M1-30 : Equilibre partout, Prudent pour les Colosses sous 40 PV.
local function tacticPass(config: Config, state: State, seat: Seat)
	for _, unit in seat.board do
		local wanted = if config.Roster.units[unit.slug].class == "Colosse"
				and seat.hp < BotPolicy.PRUDENT_HP
			then "Prudent"
			else "Equilibre"
		if unit.tactic ~= wanted then
			DuelState.apply(config, state, seat.seatIndex, "SetTactic", { wanted, unit.instanceId })
		end
	end
end

-- Joue toute la Preparation du siege `seatIndex` puis se declare Pret. A appeler 1 fois par manche.
function BotPolicy.play(config: Config, state: State, seatIndex: number, brain: Brain): ()
	if state.phase ~= "Preparation" then
		return
	end
	local seat = state.seats[seatIndex]
	local rng = Rng.new(brain.seed + state.round)
	if brain.plan == nil then
		brain.plan = choosePlan(rng)
	end
	local targets = BotPolicy.planTargets(config, brain.plan :: Plan)

	-- D-M1-28 : XP aux manches 4 et 7 si l'or restant apres achat est >= 12.
	if
		BotPolicy.XP_ROUNDS[state.round]
		and seat.gold - Economy.xpCost(config) >= BotPolicy.XP_KEEP_GOLD
	then
		DuelState.apply(config, state, seatIndex, "BuyXp", {})
	end

	buyPass(config, state, seat, targets, rng)

	-- D-M1-27 : 1 relance max par manche, or restant >= 10, aucune carte du plan visible.
	if
		brain.rerolledRound ~= state.round
		and not shopHasPlanCard(seat, targets)
		and seat.gold - Economy.rerollCost(config) >= BotPolicy.REROLL_KEEP_GOLD
	then
		brain.rerolledRound = state.round
		if DuelState.apply(config, state, seatIndex, "Reroll", {}).ok then
			buyPass(config, state, seat, targets, rng)
		end
	end

	placePass(config, state, seat)
	tacticPass(config, state, seat)
	DuelState.apply(config, state, seatIndex, "Ready", {})
end

return table.freeze(BotPolicy)
