--!strict
-- Generation d'equipes aleatoires pour le harnais QA (tests/sim/run_duels.luau).
-- Mode L0 : cases tirees au hasard sur la grille 2 x 4. Mode realiste (--m1, D-M1-29) : Colosse, Guerrier et
-- Sprinteur en ligne avant (row 1), Assassin, Artilleur, Mage et Soigneur en ligne arriere (row 2), colonne la
-- plus proche du centre libre, partenaires de couple dans la meme colonne quand c'est possible.

local Teams = {}

export type Unit = { slug: string, row: number, col: number, stars: number, tactic: string }
type Rng = { NextInteger: (self: Rng, min: number, max: number) -> number }
type Free = { [number]: { [number]: boolean } }

Teams.TACTICS = { "Agressif", "Equilibre", "Prudent" }
Teams.MIN_SIZE = 2
Teams.MAX_SIZE = 8

local FRONT_CLASSES: { [string]: boolean } = { Colosse = true, Guerrier = true, Sprinteur = true }
local CENTER_FIRST = { 2, 3, 1, 4 }

local function newFree(rows: number, cols: number): Free
	local free: Free = {}
	for row = 1, rows do
		free[row] = {}
		for col = 1, cols do
			free[row][col] = true
		end
	end
	return free
end

local function freeCount(free: Free): number
	local n = 0
	for _, cols in free do
		for _, isFree in cols do
			if isFree then
				n += 1
			end
		end
	end
	return n
end

local function randomCell(free: Free, rng: Rng): (number, number)
	local cells: { { number } } = {}
	for row, cols in free do
		for col, isFree in cols do
			if isFree then
				table.insert(cells, { row, col })
			end
		end
	end
	table.sort(cells, function(a, b)
		return if a[1] ~= b[1] then a[1] < b[1] else a[2] < b[2]
	end)
	local cell = cells[rng:NextInteger(1, #cells)]
	return cell[1], cell[2]
end

local function firstFreeInRow(free: Free, row: number, preferredCol: number?): number?
	if preferredCol and free[row][preferredCol] then
		return preferredCol
	end
	for _, col in CENTER_FIRST do
		if free[row][col] then
			return col
		end
	end
	return nil
end

local function realisticCell(
	config: any,
	free: Free,
	team: { Unit },
	slug: string
): (number, number)
	local def = config.Roster.units[slug]
	local wantRow = if FRONT_CLASSES[def.class] then 1 else 2
	local partnerCol: number? = nil
	for _, placed in team do
		if table.find(def.duoPartners, placed.slug) then
			partnerCol = placed.col
		end
	end
	local col = firstFreeInRow(free, wantRow, partnerCol)
	if col then
		return wantRow, col
	end
	local otherRow = 3 - wantRow
	local otherCol = firstFreeInRow(free, otherRow, partnerCol)
	assert(otherCol, "grille pleine")
	return otherRow, otherCol
end

-- Equipe de `size` unites (2 a 8 par defaut) tirees de `slugs` (doublons permis), etoiles 1 a 3,
-- tactique tiree au sort sauf si `tactic` est fourni.
function Teams.random(
	config: any,
	rng: Rng,
	slugs: { string },
	realistic: boolean,
	size: number?,
	tactic: string?
): { Unit }
	local count = size or rng:NextInteger(Teams.MIN_SIZE, Teams.MAX_SIZE)
	local free = newFree(config.Combat.boardRows, config.Combat.boardColumns)
	assert(count <= freeCount(free), "equipe plus grande que la grille")
	local team: { Unit } = {}
	for _ = 1, count do
		local slug = slugs[rng:NextInteger(1, #slugs)]
		local row, col
		if realistic then
			row, col = realisticCell(config, free, team, slug)
		else
			row, col = randomCell(free, rng)
		end
		free[row][col] = false
		table.insert(team, {
			slug = slug,
			row = row,
			col = col,
			stars = rng:NextInteger(1, 3),
			tactic = tactic or Teams.TACTICS[rng:NextInteger(1, #Teams.TACTICS)],
		})
	end
	return team
end

-- Copie de l'equipe avec la meme tactique pour toutes les unites (duels de tactiques au miroir).
function Teams.withTactic(team: { Unit }, tactic: string): { Unit }
	local out: { Unit } = {}
	for _, unit in team do
		table.insert(out, {
			slug = unit.slug,
			row = unit.row,
			col = unit.col,
			stars = unit.stars,
			tactic = tactic,
		})
	end
	return out
end

-- Forme compacte pour le CSV : slug*etoiles:tactique@row.col, triee par case.
function Teams.describe(team: { Unit }): string
	local sorted = table.clone(team)
	table.sort(sorted, function(a, b)
		return if a.row ~= b.row then a.row < b.row else a.col < b.col
	end)
	local parts: { string } = {}
	for _, unit in sorted do
		table.insert(parts, `{unit.slug}*{unit.stars}:{unit.tactic}@{unit.row}.{unit.col}`)
	end
	return table.concat(parts, ";")
end

return Teams
