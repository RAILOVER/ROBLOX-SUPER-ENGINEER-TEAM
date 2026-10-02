--!strict
-- Ciblage (R-M1-25 a R-M1-29, R-M1-52 revise T-0024, R-M1-55). Toutes les egalites se departagent par la case "en face"
-- (meme colonne) puis la case la plus basse, pour rester deterministe.

local Types = require(script.Parent.Parent.Types.Combat)
local Status = require(script.Parent.Status)

type State = Types.State
type Unit = Types.Unit

local Targeting = {}

local function targetable(unit: Unit): boolean
	return unit.alive and not Status.has(unit, "HorsCombat")
end

function Targeting.aliveEnemies(state: State, unit: Unit): { Unit }
	local out: { Unit } = {}
	for _, enemy in Status.enemyTeamOf(state, unit).units do
		if targetable(enemy) then
			table.insert(out, enemy)
		end
	end
	return out
end

function Targeting.aliveAllies(state: State, unit: Unit, includeSelf: boolean): { Unit }
	local out: { Unit } = {}
	for _, ally in Status.teamOf(state, unit).units do
		if targetable(ally) and (includeSelf or ally ~= unit) then
			table.insert(out, ally)
		end
	end
	return out
end

local function filterRow(units: { Unit }, row: number): { Unit }
	local out: { Unit } = {}
	for _, unit in units do
		if unit.row == row then
			table.insert(out, unit)
		end
	end
	return out
end

-- Cibles possibles d'une action a cible unique (R-M1-25, R-M1-26, R-M1-27). `rangeOverride` sert aux competences.
function Targeting.candidates(state: State, unit: Unit, rangeOverride: string?): { Unit }
	local enemies = Targeting.aliveEnemies(state, unit)
	if #enemies == 0 then
		return enemies
	end
	for _, enemy in enemies do
		if Status.has(enemy, "Provocation") then
			return { enemy }
		end
	end
	local range = rangeOverride or unit.range
	local pool = enemies
	if range == "Melee" then
		local front = filterRow(enemies, 1)
		pool = if #front > 0 then front else enemies
	end
	local visible: { Unit } = {}
	for _, enemy in pool do
		if not Status.has(enemy, "Invisible") then
			table.insert(visible, enemy)
		end
	end
	return if #visible > 0 then visible else pool
end

-- Compare 2 candidats sur un score, puis "en face", puis case la plus basse.
local function better(
	unit: Unit,
	a: Unit,
	scoreA: number,
	b: Unit,
	scoreB: number,
	lowerIsBetter: boolean
): boolean
	if scoreA ~= scoreB then
		return if lowerIsBetter then scoreA < scoreB else scoreA > scoreB
	end
	local faceA, faceB = a.col == unit.col, b.col == unit.col
	if faceA ~= faceB then
		return faceA
	end
	return a.cell < b.cell
end

local function choose(
	unit: Unit,
	pool: { Unit },
	score: (Unit) -> number,
	lowerIsBetter: boolean
): Unit?
	local best: Unit? = nil
	local bestScore = 0
	for _, candidate in pool do
		local s = score(candidate)
		if best == nil or better(unit, candidate, s, best, bestScore, lowerIsBetter) then
			best = candidate
			bestScore = s
		end
	end
	return best
end

local function lowestHp(unit: Unit, pool: { Unit }): Unit?
	return choose(unit, pool, function(c)
		return c.hp
	end, true)
end

-- R-M1-28 et R-M1-52 : choix final parmi les candidats, ordre de focus R-M1-55 en premier.
function Targeting.pickSingle(state: State, unit: Unit, pool: { Unit }): Unit?
	if #pool == 0 then
		return nil
	end
	local team = Status.teamOf(state, unit)
	if team.focusTurnsLeft > 0 and team.focusCell ~= nil then
		for _, candidate in pool do
			if candidate.cell == team.focusCell then
				return candidate
			end
		end
	end
	if unit.tactic == "Agressif" then
		return lowestHp(unit, pool)
	end
	if unit.class == "Assassin" then
		local back = filterRow(pool, 2)
		return lowestHp(unit, if #back > 0 then back else pool)
	elseif unit.class == "Artilleur" then
		local front, back = filterRow(pool, 1), filterRow(pool, 2)
		return lowestHp(unit, if #back > #front then back else front)
	elseif unit.class == "Colosse" then
		return choose(unit, pool, function(c)
			return team.damageFromEnemy[c.id] or 0
		end, false)
	end
	return lowestHp(unit, pool)
end

-- Attaque ou competence a cible unique : candidats puis choix.
function Targeting.single(state: State, unit: Unit, rangeOverride: string?): Unit?
	return Targeting.pickSingle(state, unit, Targeting.candidates(state, unit, rangeOverride))
end

-- R-M1-29 : l'allie vivant (lanceur compris) avec le plus petit hp / HPmax ; a egalite le lanceur.
function Targeting.healTarget(state: State, unit: Unit): Unit
	local best = unit
	local bestRatio = unit.hp / unit.hpMax
	for _, ally in Targeting.aliveAllies(state, unit, false) do
		local ratio = ally.hp / ally.hpMax
		if ratio < bestRatio then
			best, bestRatio = ally, ratio
		end
	end
	return best
end

-- R-M1-21 : allie vivant au hasard, lanceur exclu.
function Targeting.randomAlly(state: State, unit: Unit): Unit?
	local allies = Targeting.aliveAllies(state, unit, false)
	if #allies == 0 then
		return nil
	end
	return allies[state.rng:NextInteger(1, #allies)]
end

-- Cibles multiples : `count` ennemis distincts, les plus faibles d'abord (Invisible touche par la zone, R-M1-46).
function Targeting.multiple(state: State, unit: Unit, count: number): { Unit }
	local pool = Targeting.aliveEnemies(state, unit)
	local out: { Unit } = {}
	while #out < count and #pool > 0 do
		local pick = lowestHp(unit, pool)
		if pick == nil then
			break
		end
		table.insert(out, pick)
		table.remove(pool, table.find(pool, pick))
	end
	return out
end

return Targeting
