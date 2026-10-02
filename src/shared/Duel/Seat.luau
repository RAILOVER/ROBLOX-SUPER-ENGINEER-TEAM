--!strict
-- Un siege du duel : or, PV, niveau, banc (6), plateau (2 x 4), boutique (5). Operations pures, chacune retourne
-- { ok, reason } sans jamais lever d'erreur sur une intention client invalide (D-M1-04, D-M1-08 a D-M1-11).

local Types = require(script.Parent.Parent.Types.Combat)
local DuelTypes = require(script.Parent.Parent.Types.Duel)
local Economy = require(script.Parent.Economy)
local Rng = require(script.Parent.Parent.Combat.Rng)
local Shop = require(script.Parent.Shop)

type Config = Types.CombatConfig
type ActionResult = DuelTypes.ActionResult
type OwnedUnit = DuelTypes.OwnedUnit
type Seat = DuelTypes.Seat
type SeatKind = DuelTypes.SeatKind
type Tactic = DuelTypes.Tactic
type UnitInstance = DuelTypes.UnitInstance

local Seat = {}

local function ok(): ActionResult
	return { ok = true }
end

local function fail(reason: string): ActionResult
	return { ok = false, reason = reason }
end

function Seat.new(
	config: Config,
	seatIndex: number,
	kind: SeatKind,
	userId: number,
	displayName: string,
	deck: { string },
	seed: number
): Seat
	return {
		seatIndex = seatIndex,
		kind = kind,
		userId = userId,
		displayName = displayName,
		hp = config.Duel.playerHp,
		gold = config.Duel.economy.startGold,
		level = config.Duel.startLevel,
		xp = 0,
		streak = 0,
		lastOutcome = nil,
		ready = false,
		bench = {},
		board = {},
		shop = {},
		pool = Shop.newPool(config, deck),
		rng = Rng.new(seed),
		nextUnitId = 1,
		roundsWon = 0,
		invalidRequests = 0,
	}
end

function Seat.allUnits(seat: Seat): { OwnedUnit }
	local units = table.clone(seat.board)
	for _, unit in seat.bench do
		table.insert(units, unit)
	end
	return units
end

-- Retourne l'unite, la liste qui la contient et son index, ou nil.
function Seat.findUnit(seat: Seat, instanceId: string): (OwnedUnit?, { OwnedUnit }?, number?)
	for index, unit in seat.board do
		if unit.instanceId == instanceId then
			return unit, seat.board, index
		end
	end
	for index, unit in seat.bench do
		if unit.instanceId == instanceId then
			return unit, seat.bench, index
		end
	end
	return nil, nil, nil
end

function Seat.unitAt(seat: Seat, row: number, col: number): OwnedUnit?
	for _, unit in seat.board do
		if unit.row == row and unit.col == col then
			return unit
		end
	end
	return nil
end

local function removeUnit(seat: Seat, unit: OwnedUnit): ()
	local _, list, index = Seat.findUnit(seat, unit.instanceId)
	if list and index then
		table.remove(list, index)
	end
end

-- D-M1-10 : fusionne tant que 3 exemplaires identiques existent. L'exemplaire conserve est celui du plateau s'il y
-- en a un (sa case est gardee), sinon le plus ancien du banc. Retourne le nombre de fusions.
function Seat.fuse(seat: Seat, slug: string): number
	local fusions = 0
	for stars = 1, 2 do
		local triple = Shop.findTriple(Seat.allUnits(seat), slug, stars)
		while triple do
			local keep = triple[1]
			for _, unit in triple do
				if unit.row > 0 then
					keep = unit
					break
				end
			end
			for _, unit in triple do
				if unit ~= keep then
					removeUnit(seat, unit)
				end
			end
			keep.stars = stars + 1
			fusions += 1
			triple = Shop.findTriple(Seat.allUnits(seat), slug, stars)
		end
	end
	return fusions
end

local function addToBench(seat: Seat, slug: string): OwnedUnit
	local unit: OwnedUnit = {
		instanceId = `u{seat.nextUnitId}`,
		slug = slug,
		stars = 1,
		tactic = "Equilibre",
		row = 0,
		col = 0,
	}
	seat.nextUnitId += 1
	table.insert(seat.bench, unit)
	return unit
end

-- Carte gratuite (recompense PvE, D-M1-06) : ajoutee au banc si une place existe, sinon perdue.
function Seat.grantFreeCard(config: Config, seat: Seat, slug: string): boolean
	if #seat.bench >= config.Duel.benchSize then
		return false
	end
	if (seat.pool[slug] or 0) > 0 then
		seat.pool[slug] -= 1
	end
	addToBench(seat, slug)
	Seat.fuse(seat, slug)
	return true
end

-- D-M1-08 : achat d'un emplacement. Banc plein => refuse, sauf si la carte complete une fusion (1 place liberee).
function Seat.buy(config: Config, seat: Seat, slotIndex: number): ActionResult
	local slot = seat.shop[slotIndex]
	if slot == nil or slot.sold then
		return fail("slot_empty")
	end
	if seat.gold < slot.cost then
		return fail("not_enough_gold")
	end
	local completesFusion = false
	for stars = 1, 2 do
		local same = 0
		for _, unit in Seat.allUnits(seat) do
			if unit.slug == slot.slug and unit.stars == stars then
				same += 1
			end
		end
		if stars == 1 and same == 2 then
			completesFusion = true
		end
	end
	if #seat.bench >= config.Duel.benchSize and not completesFusion then
		return fail("bench_full")
	end
	seat.gold -= slot.cost
	slot.sold = true
	addToBench(seat, slot.slug)
	Seat.fuse(seat, slot.slug)
	return ok()
end

function Seat.rollShop(config: Config, seat: Seat): ()
	Shop.returnUnsold(seat.pool, seat.shop)
	seat.shop = Shop.roll(config, seat.rng, seat.pool, seat.level)
end

function Seat.reroll(config: Config, seat: Seat): ActionResult
	local cost = Economy.rerollCost(config)
	if seat.gold < cost then
		return fail("not_enough_gold")
	end
	seat.gold -= cost
	Seat.rollShop(config, seat)
	return ok()
end

function Seat.buyXp(config: Config, seat: Seat): ActionResult
	if seat.level >= config.Duel.maxLevel then
		return fail("max_level")
	end
	local cost = Economy.xpCost(config)
	if seat.gold < cost then
		return fail("not_enough_gold")
	end
	seat.gold -= cost
	seat.level, seat.xp =
		Economy.addXp(config, seat.level, seat.xp, config.Duel.economy.xpPerPurchase)
	return ok()
end

-- D-M1-11 : place une unite (banc ou plateau) sur une case. Case occupee => echange des positions.
function Seat.place(
	config: Config,
	seat: Seat,
	instanceId: string,
	row: number,
	col: number
): ActionResult
	if row < 1 or row > config.Combat.boardRows or col < 1 or col > config.Combat.boardColumns then
		return fail("bad_cell")
	end
	local unit = Seat.findUnit(seat, instanceId)
	if unit == nil then
		return fail("unknown_unit")
	end
	local occupant = Seat.unitAt(seat, row, col)
	if occupant == unit then
		return ok()
	end
	local fromBench = unit.row == 0
	if fromBench and occupant == nil and #seat.board >= seat.level then
		return fail("board_full")
	end
	if occupant then
		if fromBench then
			removeUnit(seat, occupant)
			occupant.row, occupant.col = 0, 0
			table.insert(seat.bench, occupant)
		else
			occupant.row, occupant.col = unit.row, unit.col
		end
	end
	if fromBench then
		removeUnit(seat, unit)
		table.insert(seat.board, unit)
	end
	unit.row, unit.col = row, col
	return ok()
end

function Seat.bench(config: Config, seat: Seat, instanceId: string): ActionResult
	local unit = Seat.findUnit(seat, instanceId)
	if unit == nil then
		return fail("unknown_unit")
	end
	if unit.row == 0 then
		return fail("already_benched")
	end
	if #seat.bench >= config.Duel.benchSize then
		return fail("bench_full")
	end
	removeUnit(seat, unit)
	unit.row, unit.col = 0, 0
	table.insert(seat.bench, unit)
	return ok()
end

-- D-M1-10 : vente, les exemplaires retournent au pool.
function Seat.sell(config: Config, seat: Seat, instanceId: string): ActionResult
	local unit = Seat.findUnit(seat, instanceId)
	if unit == nil then
		return fail("unknown_unit")
	end
	removeUnit(seat, unit)
	seat.gold += Economy.sellValue(config, unit.slug, unit.stars)
	Shop.returnCopies(seat.pool, unit.slug, unit.stars)
	return ok()
end

-- Tactique d'une unite, ou de toutes les unites du siege quand `instanceId` est nil.
function Seat.setTactic(seat: Seat, tactic: Tactic, instanceId: string?): ActionResult
	if instanceId == nil then
		for _, unit in Seat.allUnits(seat) do
			unit.tactic = tactic
		end
		return ok()
	end
	local unit = Seat.findUnit(seat, instanceId)
	if unit == nil then
		return fail("unknown_unit")
	end
	unit.tactic = tactic
	return ok()
end

-- Equipe pour CombatSim.simulate, triee par case (stable).
function Seat.toTeam(seat: Seat): { UnitInstance }
	local team: { UnitInstance } = {}
	for _, unit in seat.board do
		table.insert(team, {
			slug = unit.slug,
			stars = unit.stars,
			row = unit.row,
			col = unit.col,
			tactic = unit.tactic,
		})
	end
	table.sort(team, function(a, b)
		return (a.row * 10 + a.col) < (b.row * 10 + b.col)
	end)
	return team
end

-- Debut de Preparation (D-M1-07, D-M1-09) : revenu et XP automatiques des la manche 2, nouvelle boutique.
function Seat.beginRound(config: Config, seat: Seat, round: number): ()
	if round >= 2 then
		local income = Economy.income(config, seat.gold, seat.streak, seat.lastOutcome == "win")
		seat.gold += income.total
		seat.level, seat.xp = Economy.addXp(config, seat.level, seat.xp, config.Duel.xpPerRound)
	end
	seat.ready = false
	Seat.rollShop(config, seat)
end

return table.freeze(Seat)
