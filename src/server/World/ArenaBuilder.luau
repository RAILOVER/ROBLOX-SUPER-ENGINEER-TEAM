--!strict
-- Construit une arene greybox en Parts anchored, couleurs plates, depuis une ArenaDef (Config.Arenas).
-- Aucune texture, aucun MeshPart (P1). Le decor ne collisionne pas (brief §17.6) ; seuls le sol, les cases
-- et le banc sont solides et interrogeables par raycast (tap). Le Model est Persistent pour StreamingEnabled :
-- tout le plateau est visible des le spawn. `parent` peut etre Workspace ou ReplicatedStorage (§16.3).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arenas = require(ReplicatedStorage.Shared.Config.Arenas)
local ArenaGeometry = require(ReplicatedStorage.Shared.World.ArenaGeometry)

type ArenaDef = Arenas.ArenaDef
type Box = Arenas.Box
type SideId = Arenas.SideId

local ArenaBuilder = {}

local SHAPES: { [string]: Enum.PartType } = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

type PartOptions = { collide: boolean, castShadow: boolean }

local DECOR: PartOptions = { collide = false, castShadow = false }
local SOLID: PartOptions = { collide = true, castShadow = false }

local function toVector3(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function makePart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: string,
	options: PartOptions
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = Color3.fromHex(color)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = options.collide
	part.CanQuery = options.collide
	part.CanTouch = false
	part.CastShadow = options.castShadow
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function makeBox(box: Box, parent: Instance): Part
	local cframe = CFrame.new(toVector3(box.position))
		* CFrame.Angles(0, math.rad(box.rotationY or 0), 0)
	local options: PartOptions = if box.canCollide then SOLID else DECOR
	local part = makePart(box.name, toVector3(box.size), cframe, box.color, options)
	part.Shape = SHAPES[box.shape or "Block"] or Enum.PartType.Block
	part.Parent = parent
	return part
end

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function buildPlanes(arena: ArenaDef, model: Model): Part?
	local decor = makeFolder("Decor", model)
	local floor: Part? = nil
	for _, planeId in Arenas.planeOrder do
		local folder = makeFolder(planeId, decor)
		for _, box in ArenaGeometry.planeBoxes(arena.planes[planeId]) do
			local part = makeBox(box, folder)
			if floor == nil and box.canCollide then
				floor = part
			end
		end
	end
	return floor
end

local function buildBoard(arena: ArenaDef, model: Model)
	local folder = makeFolder("Board", model)
	local cellSize = Vector3.new(arena.scale.cellSize, arena.scale.cellHeight, arena.scale.cellSize)
	for _, side: SideId in Arenas.sideOrder do
		local sideDef = ArenaGeometry.sideDef(arena, side)
		for row = 1, arena.board.rows do
			for col = 1, arena.board.columns do
				local center = ArenaGeometry.cellCenter(arena, side, row, col)
				local color = if row == 1 then sideDef.frontRowColor else sideDef.color
				local cell = makePart(
					`Cell_{side}_{row}_{col}`,
					cellSize,
					CFrame.new(center.x, center.y, center.z),
					color,
					SOLID
				)
				cell:SetAttribute("Side", side)
				cell:SetAttribute("Row", row)
				cell:SetAttribute("Col", col)
				cell.Parent = folder
			end
		end
	end
end

local function buildBench(arena: ArenaDef, model: Model)
	local folder = makeFolder("Bench", model)
	local slotSize = Vector3.new(arena.scale.cellSize, arena.scale.cellHeight, arena.scale.cellSize)
	for slot = 1, arena.bench.slots do
		local center = ArenaGeometry.benchSlotCenter(arena, slot)
		local part = makePart(
			`Bench_{slot}`,
			slotSize,
			CFrame.new(center.x, center.y, center.z),
			arena.bench.color,
			SOLID
		)
		part:SetAttribute("Slot", slot)
		part.Parent = folder
	end
end

local function buildSpawn(arena: ArenaDef, model: Model)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(arena.spawn.size, 0.3, arena.spawn.size)
	spawn.CFrame = CFrame.lookAt(toVector3(arena.spawn.position), toVector3(arena.spawn.lookAt))
	spawn.Color = Color3.fromHex(arena.spawn.color)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = model
end

-- Ancres invisibles : le client (05) lit `Cameras.combat.CFrame` pour placer sa camera (§16.9, 3 positions).
local function buildCameras(arena: ArenaDef, model: Model)
	local folder = makeFolder("Cameras", model)
	for _, shotId in Arenas.cameraOrder do
		local shot = arena.cameras[shotId]
		local cframe = CFrame.lookAt(toVector3(shot.position), toVector3(shot.lookAt))
		local anchor = makePart(shotId, Vector3.one, cframe, "#FFFFFF", DECOR)
		anchor.Transparency = 1
		anchor:SetAttribute("FieldOfView", shot.fieldOfView)
		anchor.Parent = folder
	end
end

function ArenaBuilder.build(parent: Instance, arena: ArenaDef): Model
	local model = Instance.new("Model")
	model.Name = arena.id
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local floor = buildPlanes(arena, model)
	buildBoard(arena, model)
	buildBench(arena, model)
	buildSpawn(arena, model)
	buildCameras(arena, model)
	if floor then
		model.PrimaryPart = floor
	end
	model:SetAttribute("PartCount", ArenaGeometry.countParts(arena))
	model.Parent = parent
	return model
end

-- Point ou poser une unite : dessus de la case (side "A" ou "B", row 1 = avant, col 1 = x minimal).
function ArenaBuilder.cellPosition(arena: ArenaDef, side: SideId, row: number, col: number): Vector3
	local top = ArenaGeometry.cellTop(arena, side, row, col)
	return Vector3.new(top.x, top.y, top.z)
end

function ArenaBuilder.benchPosition(arena: ArenaDef, slot: number): Vector3
	local center = ArenaGeometry.benchSlotCenter(arena, slot)
	return Vector3.new(center.x, center.y + arena.scale.cellHeight / 2, center.z)
end

return table.freeze(ArenaBuilder)
