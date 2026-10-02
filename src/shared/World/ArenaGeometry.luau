--!strict
-- Geometrie pure d'une arene (aucun type Roblox) : centres des cases et du banc, boites des palmiers, budget
-- de Parts, test de visibilite camera. Partage par ArenaBuilder (serveur) et les tests Lune (tests/unit/Arena.spec).
-- Repere : y vers le haut, les 2 camps se font face le long de z (camp A en z negatif, camera derriere A).
-- Ligne 1 = ligne avant (la plus proche de l'adversaire), ligne 2 = ligne arriere. Colonne 1 = x minimal.

local Arenas = require(script.Parent.Parent.Config.Arenas)

type ArenaDef = Arenas.ArenaDef
type Box = Arenas.Box
type Palm = Arenas.Palm
type Plane = Arenas.Plane
type SideId = Arenas.SideId
type CameraShot = Arenas.CameraShot

export type Vec = { x: number, y: number, z: number }
export type Footprint = { minX: number, maxX: number, minZ: number, maxZ: number }

local ArenaGeometry = {}

local function vec(x: number, y: number, z: number): Vec
	return { x = x, y = y, z = z }
end

local function sub(a: Vec, b: Vec): Vec
	return vec(a.x - b.x, a.y - b.y, a.z - b.z)
end

local function dot(a: Vec, b: Vec): number
	return a.x * b.x + a.y * b.y + a.z * b.z
end

local function cross(a: Vec, b: Vec): Vec
	return vec(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

local function length(a: Vec): number
	return math.sqrt(dot(a, a))
end

local function normalize(a: Vec): Vec
	local l = length(a)
	return vec(a.x / l, a.y / l, a.z / l)
end

function ArenaGeometry.fromArray(v: { number }): Vec
	return vec(v[1], v[2], v[3])
end

function ArenaGeometry.sideDef(arena: ArenaDef, side: SideId): Arenas.Side
	if side == "A" then
		return arena.sides.A
	end
	return arena.sides.B
end

-- Centre de la Part "case" (le dessus est a y + cellHeight / 2).
function ArenaGeometry.cellCenter(arena: ArenaDef, side: SideId, row: number, col: number): Vec
	local board, scale = arena.board, arena.scale
	assert(row >= 1 and row <= board.rows and row % 1 == 0, `ligne hors plateau : {row}`)
	assert(col >= 1 and col <= board.columns and col % 1 == 0, `colonne hors plateau : {col}`)
	local direction = ArenaGeometry.sideDef(arena, side).direction
	local x = (col - (board.columns + 1) / 2) * scale.cellPitch
	local z = direction * (scale.campGap / 2 + (row - 0.5) * scale.cellPitch)
	return vec(x, scale.floorY + scale.cellHeight / 2, z)
end

-- Point ou l'unite pose les pieds (dessus de la case).
function ArenaGeometry.cellTop(arena: ArenaDef, side: SideId, row: number, col: number): Vec
	local center = ArenaGeometry.cellCenter(arena, side, row, col)
	return vec(center.x, center.y + arena.scale.cellHeight / 2, center.z)
end

function ArenaGeometry.benchSlotCenter(arena: ArenaDef, slot: number): Vec
	local bench, scale = arena.bench, arena.scale
	assert(
		slot >= 1 and slot <= bench.slots and slot % 1 == 0,
		`place de banc hors limites : {slot}`
	)
	local direction = ArenaGeometry.sideDef(arena, bench.side).direction
	local x = (slot - (bench.slots + 1) / 2) * bench.pitch
	return vec(x, scale.floorY + scale.cellHeight / 2, direction * bench.distanceFromCenter)
end

-- Boite englobante (xz) des 2 camps, ecart central compris : aucun decor ne doit la couvrir.
function ArenaGeometry.boardBounds(
	arena: ArenaDef
): { minX: number, maxX: number, minZ: number, maxZ: number }
	local board, scale = arena.board, arena.scale
	local halfWidth = board.columns * scale.cellPitch / 2
	local depth = scale.campGap / 2 + board.rows * scale.cellPitch
	return { minX = -halfWidth, maxX = halfWidth, minZ = -depth, maxZ = depth }
end

-- Emprise au sol (xz) d'une boite : exacte pour une rotation multiple de 90 degres, sinon rectangle
-- englobant de la boite tournee (conservateur).
function ArenaGeometry.boxFootprint(box: Box): Footprint
	local x, z = box.position[1], box.position[3]
	local a = math.rad(box.rotationY or 0)
	local c, s = math.abs(math.cos(a)), math.abs(math.sin(a))
	local halfX = (box.size[1] * c + box.size[3] * s) / 2
	local halfZ = (box.size[1] * s + box.size[3] * c) / 2
	return { minX = x - halfX, maxX = x + halfX, minZ = z - halfZ, maxZ = z + halfZ }
end

function ArenaGeometry.footprintsOverlap(a: Footprint, b: Footprint): boolean
	return a.minX < b.maxX and b.minX < a.maxX and a.minZ < b.maxZ and b.minZ < a.maxZ
end

-- Un palmier = 1 tronc + 3 palmes (4 Parts).
function ArenaGeometry.palmBoxes(plane: Plane, palm: Palm): { Box }
	local x, y, z = palm.position[1], palm.position[2], palm.position[3]
	local h = palm.height
	local crownY = y + h + 0.5
	local crown = plane.palmColors.crown
	return {
		{
			name = `{palm.name}_Trunk`,
			size = { 2, h, 2 },
			position = { x, y + h / 2, z },
			color = plane.palmColors.trunk,
		},
		{
			name = `{palm.name}_Leaf1`,
			size = { 11, 1, 3 },
			position = { x, crownY, z },
			color = crown,
			rotationY = palm.rotationY,
		},
		{
			name = `{palm.name}_Leaf2`,
			size = { 3, 1, 11 },
			position = { x, crownY, z },
			color = crown,
			rotationY = palm.rotationY,
		},
		{
			name = `{palm.name}_Leaf3`,
			size = { 8, 1, 8 },
			position = { x, crownY + 0.5, z },
			color = crown,
			rotationY = palm.rotationY + 45,
		},
	}
end

-- Toutes les boites de decor d'un plan, palmiers developpes, dans un ordre stable.
function ArenaGeometry.planeBoxes(plane: Plane): { Box }
	local boxes: { Box } = table.clone(plane.boxes)
	for _, palm in plane.palms do
		for _, box in ArenaGeometry.palmBoxes(plane, palm) do
			table.insert(boxes, box)
		end
	end
	return boxes
end

-- Nombre total de BaseParts que construit ArenaBuilder.build : decor + cases + banc + spawn + ancres camera.
function ArenaGeometry.countParts(arena: ArenaDef): number
	local n = 0
	for _, planeId in Arenas.planeOrder do
		n += #ArenaGeometry.planeBoxes(arena.planes[planeId])
	end
	n += 2 * arena.board.rows * arena.board.columns
	n += arena.bench.slots
	n += 1 -- spawn
	n += #Arenas.cameraOrder
	return n
end

function ArenaGeometry.cameraDistance(shot: CameraShot): number
	return length(sub(ArenaGeometry.fromArray(shot.lookAt), ArenaGeometry.fromArray(shot.position)))
end

-- Angles ecran d'un point vu par la camera, en degres : yaw (droite > 0) et pitch (haut > 0) par rapport
-- a l'axe de visee. Le point est visible si |yaw| < demi-champ horizontal et |pitch| < fieldOfView / 2.
function ArenaGeometry.screenAngles(shot: CameraShot, point: Vec): (number, number)
	local eye = ArenaGeometry.fromArray(shot.position)
	local forward = normalize(sub(ArenaGeometry.fromArray(shot.lookAt), eye))
	local right = normalize(cross(forward, vec(0, 1, 0)))
	local up = cross(right, forward)
	local d = sub(point, eye)
	local depth = dot(d, forward)
	return math.deg(math.atan2(dot(d, right), depth)), math.deg(math.atan2(dot(d, up), depth))
end

-- Visible dans le champ (FieldOfView Roblox = vertical), pour un ratio largeur / hauteur donne,
-- avec une marge en fraction du demi-champ (0.1 = le point reste a 10 % du bord).
function ArenaGeometry.isInView(
	shot: CameraShot,
	point: Vec,
	aspect: number,
	margin: number?
): boolean
	local keep = 1 - (margin or 0)
	local halfV = math.rad(shot.fieldOfView / 2)
	local halfH = math.atan(math.tan(halfV) * aspect)
	local yaw, pitch = ArenaGeometry.screenAngles(shot, point)
	local eye = ArenaGeometry.fromArray(shot.position)
	local forward = normalize(sub(ArenaGeometry.fromArray(shot.lookAt), eye))
	if dot(sub(point, eye), forward) <= 0 then
		return false
	end
	return math.abs(math.rad(yaw)) <= halfH * keep and math.abs(math.rad(pitch)) <= halfV * keep
end

return table.freeze(ArenaGeometry)
