--!strict
-- Arena01 : GENERE par tools/gen_arena.py depuis design/levels/arena-01/layout.json. Ne pas editer a la main.
-- Table pure (aucun type Roblox) : positions en studs [x, y, z], couleurs en hex #RRGGBB.

local Types = require(script.Parent.Types)

local foreground: Types.Plane = {
	description = "Plage cote joueur (z -50 a -16), cadre le plateau sans le couvrir",
	palmColors = { trunk = "#9C7B5A", crown = "#5E9B5A" },
	boxes = {
		{
			name = "ParasolPole",
			size = { 0.5, 8, 0.5 },
			position = { -8, 4, -42 },
			color = "#F2F2F2",
		},
		{
			name = "ParasolTop",
			size = { 8, 0.6, 8 },
			position = { -8, 8.3, -42 },
			color = "#FF5E7E",
			rotationY = 45,
		},
		{ name = "Towel", size = { 6, 0.2, 3 }, position = { -9, 0.1, -36 }, color = "#2EC4F1" },
		{ name = "RockBig", size = { 5, 3, 4 }, position = { 30, 1.5, -40 }, color = "#9FA3A8" },
		{ name = "RockSmall", size = { 3, 2, 3 }, position = { 34, 1, -36 }, color = "#B4B8BC" },
		{
			name = "BeachBall",
			shape = "Ball",
			size = { 2.5, 2.5, 2.5 },
			position = { 26, 1.25, -44 },
			color = "#FFC93C",
		},
	},
	palms = {
		{ name = "PalmNearLeft", position = { -24, 0, -18 }, height = 20, rotationY = 20 },
		{ name = "PalmNearRight", position = { 30, 0, -22 }, height = 18, rotationY = 70 },
	},
}

local arena: Types.Plane = {
	description = "Sable, plateau 2 camps x (2 x 4), banc, ligne mediane, rivage a z = 65",
	palmColors = { trunk = "#9C7B5A", crown = "#5E9B5A" },
	boxes = {
		{
			name = "Sand",
			size = { 140, 1, 110 },
			position = { 0, -0.5, 10 },
			color = "#E9D8A6",
			canCollide = true,
		},
		{
			name = "CenterLine",
			size = { 0.5, 0.1, 38 },
			position = { 0, 0.05, 0 },
			color = "#FFF8E7",
		},
		{
			name = "BenchBase",
			size = { 46, 0.3, 8 },
			position = { 0, 0.15, -25 },
			color = "#D9C48E",
		},
		{ name = "Water", size = { 240, 1, 140 }, position = { 0, -0.6, 135 }, color = "#5FC9E6" },
		{
			name = "Foam1",
			size = { 240, 0.2, 1.5 },
			position = { 0, -0.05, 66 },
			color = "#F2F7F7",
		},
		{ name = "Foam2", size = { 240, 0.2, 1 }, position = { 0, -0.05, 71 }, color = "#F2F7F7" },
	},
	palms = {},
}

local background: Types.Plane = {
	description = "Fond (z > 40) : basket bleue geante, palmiers, bouees, dunes, saturation -15 %",
	palmColors = { trunk = "#A58B6E", crown = "#6FA86A" },
	boxes = {
		{
			name = "SneakerSole",
			size = { 30, 4, 12 },
			position = { -40, 2, 100 },
			color = "#F2F2F2",
		},
		{
			name = "SneakerBody",
			size = { 26, 10, 11 },
			position = { -41, 9, 100 },
			color = "#7FA3DE",
		},
		{
			name = "SneakerToe",
			size = { 8, 5, 10 },
			position = { -29, 6.5, 100 },
			color = "#7FA3DE",
		},
		{
			name = "SneakerHeel",
			size = { 6, 14, 11 },
			position = { -52, 11, 100 },
			color = "#7FA3DE",
		},
		{
			name = "SneakerTongue",
			size = { 8, 6, 5 },
			position = { -34, 16, 100 },
			color = "#A9C2EA",
		},
		{
			name = "SneakerLace",
			size = { 12, 0.6, 7 },
			position = { -40, 14.4, 100 },
			color = "#F2F2F2",
		},
		{
			name = "Buoy1",
			shape = "Ball",
			size = { 3, 3, 3 },
			position = { -10, 1, 82 },
			color = "#E86E6E",
		},
		{
			name = "Buoy2",
			shape = "Ball",
			size = { 3, 3, 3 },
			position = { 12, 1, 90 },
			color = "#E86E6E",
		},
		{
			name = "Buoy3",
			shape = "Ball",
			size = { 3, 3, 3 },
			position = { 34, 1, 80 },
			color = "#E86E6E",
		},
		{
			name = "Buoy4",
			shape = "Ball",
			size = { 3, 3, 3 },
			position = { -70, 1, 88 },
			color = "#E86E6E",
		},
		{
			name = "DuneFarRight",
			size = { 90, 6, 24 },
			position = { 95, 2.5, 160 },
			color = "#CFC0A0",
		},
		{
			name = "DuneFarLeft",
			size = { 70, 5, 20 },
			position = { -120, 2, 150 },
			color = "#CFC0A0",
		},
	},
	palms = {
		{ name = "PalmBg1", position = { -62, 0, 44 }, height = 18, rotationY = 0 },
		{ name = "PalmBg2", position = { -48, 0, 58 }, height = 14, rotationY = 30 },
		{ name = "PalmBg3", position = { 58, 0, 42 }, height = 20, rotationY = 10 },
		{ name = "PalmBg4", position = { 70, 0, 56 }, height = 16, rotationY = 45 },
		{ name = "PalmBg5", position = { 95, 5, 160 }, height = 20, rotationY = 15 },
		{ name = "PalmBg6", position = { -120, 4, 150 }, height = 17, rotationY = 60 },
	},
}

local arenaDef: Types.ArenaDef = {
	id = "arena-01",
	name = "Spiaggia Tralala",
	brief = "design/brief/BATTLEROT.md 15.5 arene 1 (Plage de Tralalero), 10.6, 17.6",
	scale = {
		studsPerMeter = 3.571,
		unitHeight = 5,
		cellSize = 6,
		cellPitch = 7,
		cellHeight = 0.5,
		campGap = 10,
		floorY = 0,
	},
	board = { rows = 2, columns = 4 },
	sides = {
		A = { direction = -1, color = "#2E7CF6", frontRowColor = "#6FA8FF" },
		B = { direction = 1, color = "#FF8A00", frontRowColor = "#FFB04D" },
	},
	bench = { side = "A", slots = 6, pitch = 7, distanceFromCenter = 25, color = "#FFF8E7" },
	spawn = { size = 8, color = "#3DDC5C", position = { 0, 0.15, -38 }, lookAt = { 0, 0.15, 0 } },
	cameras = {
		combat = { position = { 14, 40, -58 }, lookAt = { 0, 3, 0 }, fieldOfView = 70 },
		preparation = { position = { 10, 30, -50 }, lookAt = { 0, 2, -12 }, fieldOfView = 70 },
		victory = { position = { 8, 8, 14 }, lookAt = { 0, 4, -12 }, fieldOfView = 60 },
	},
	budgets = { maxParts = 300 },
	planes = {
		foreground = foreground,
		arena = arena,
		background = background,
	},
}

return table.freeze(arenaDef)
