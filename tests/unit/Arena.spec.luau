--!strict
-- Arene 01 Spiaggia Tralala (T-0013) : partie pure (Config.Arenas + World.ArenaGeometry), tourne sous Lune.
-- Verifie les 16 cases, l'absence de chevauchement, le budget de Parts et la visibilite depuis les cameras.

local Arenas = loadShared("Config").Arenas
local Combat = loadShared("Config").Combat
local Duel = loadShared("Config").Duel
local ArenaGeometry = loadShared("World").ArenaGeometry

type Vec = ArenaGeometry.Vec

local arena = Arenas.byId["arena-01"]

local function key(v: Vec): string
	return `{v.x},{v.y},{v.z}`
end

local function allCells(): { { side: Arenas.SideId, row: number, col: number, center: Vec } }
	local cells = {}
	for _, side in Arenas.sideOrder do
		for row = 1, arena.board.rows do
			for col = 1, arena.board.columns do
				table.insert(cells, {
					side = side,
					row = row,
					col = col,
					center = ArenaGeometry.cellCenter(arena, side, row, col),
				})
			end
		end
	end
	return cells
end

describe("Arena01 : plateau", function()
	it("suit Config.Combat.board (2 lignes x 4 colonnes) et Config.Duel.benchSize (6)", function()
		expect(arena.board.rows).toBe(Combat.boardRows)
		expect(arena.board.columns).toBe(Combat.boardColumns)
		expect(arena.bench.slots).toBe(Duel.benchSize)
		expect(Arenas.order[1]).toBe("arena-01")
		expect(Arenas.byId[Arenas.order[1]].id).toBe("arena-01")
	end)

	it("a 16 cases a des positions distinctes", function()
		local cells = allCells()
		expect(#cells).toBe(16)
		local seen: { [string]: boolean } = {}
		for _, cell in cells do
			expect(seen[key(cell.center)]).toBeNil()
			seen[key(cell.center)] = true
		end
	end)

	it("ne fait chevaucher aucune case : ecart entre centres >= cellSize", function()
		local cells = allCells()
		for i = 1, #cells do
			for j = i + 1, #cells do
				local a, b = cells[i].center, cells[j].center
				local gap = math.max(math.abs(a.x - b.x), math.abs(a.z - b.z))
				expect(gap).toBeGreaterThanOrEqual(arena.scale.cellSize)
			end
		end
	end)

	it("place le camp A en z negatif, le camp B en z positif, lignes avant face a face", function()
		local a1 = ArenaGeometry.cellCenter(arena, "A", 1, 1)
		local a2 = ArenaGeometry.cellCenter(arena, "A", 2, 1)
		local b1 = ArenaGeometry.cellCenter(arena, "B", 1, 1)
		expect(a1.z < 0).toBeTruthy()
		expect(b1.z > 0).toBeTruthy()
		expect(math.abs(a1.z)).toBeCloseTo(math.abs(b1.z), 6)
		expect(math.abs(a2.z) > math.abs(a1.z)).toBeTruthy()
		expect(b1.z - a1.z).toBeCloseTo(arena.scale.campGap + arena.scale.cellPitch, 6)
		expect(ArenaGeometry.cellCenter(arena, "A", 1, 4).x - a1.x).toBeCloseTo(
			3 * arena.scale.cellPitch,
			6
		)
		expect(ArenaGeometry.cellTop(arena, "A", 1, 1).y).toBeCloseTo(
			arena.scale.floorY + arena.scale.cellHeight,
			6
		)
	end)

	it("refuse les coordonnees hors plateau", function()
		expect(function()
			ArenaGeometry.cellCenter(arena, "A", 3, 1)
		end).toThrow()
		expect(function()
			ArenaGeometry.cellCenter(arena, "B", 1, 5)
		end).toThrow()
		expect(function()
			ArenaGeometry.cellCenter(arena, "B", 1, 0)
		end).toThrow()
	end)

	it("a 6 places de banc distinctes, cote A, hors du plateau", function()
		local bounds = ArenaGeometry.boardBounds(arena)
		local seen: { [string]: boolean } = {}
		for slot = 1, arena.bench.slots do
			local c = ArenaGeometry.benchSlotCenter(arena, slot)
			expect(seen[key(c)]).toBeNil()
			seen[key(c)] = true
			expect(c.z + arena.scale.cellSize / 2 < bounds.minZ).toBeTruthy()
		end
		expect(function()
			ArenaGeometry.benchSlotCenter(arena, 7)
		end).toThrow()
	end)
end)

describe("Arena01 : decor", function()
	it(
		"laisse le plateau degage : aucun decor ne depasse des cases dans la zone des 2 camps",
		function()
			local bounds = ArenaGeometry.boardBounds(arena)
			local cellTop = arena.scale.floorY + arena.scale.cellHeight
			for _, planeId in Arenas.planeOrder do
				for _, box in ArenaGeometry.planeBoxes(arena.planes[planeId]) do
					if box.canCollide ~= true then
						local top = box.position[2] + box.size[2] / 2
						local overlaps =
							ArenaGeometry.footprintsOverlap(ArenaGeometry.boxFootprint(box), bounds)
						expect(overlaps and top > cellTop).toBe(false)
					end
				end
			end
		end
	)

	it("ne fait chevaucher aucune case par le banc ni le spawn", function()
		local benchFootprints: { ArenaGeometry.Footprint } = {}
		for slot = 1, arena.bench.slots do
			local c = ArenaGeometry.benchSlotCenter(arena, slot)
			local half = arena.scale.cellSize / 2
			table.insert(
				benchFootprints,
				{ minX = c.x - half, maxX = c.x + half, minZ = c.z - half, maxZ = c.z + half }
			)
		end
		local sp = arena.spawn
		local spawnFootprint = {
			minX = sp.position[1] - sp.size / 2,
			maxX = sp.position[1] + sp.size / 2,
			minZ = sp.position[3] - sp.size / 2,
			maxZ = sp.position[3] + sp.size / 2,
		}
		for i = 1, #benchFootprints do
			expect(ArenaGeometry.footprintsOverlap(benchFootprints[i], spawnFootprint)).toBe(false)
			for j = i + 1, #benchFootprints do
				expect(ArenaGeometry.footprintsOverlap(benchFootprints[i], benchFootprints[j])).toBe(
					false
				)
			end
		end
		expect(ArenaGeometry.footprintsOverlap(spawnFootprint, ArenaGeometry.boardBounds(arena))).toBe(
			false
		)
	end)

	it("a des boites nommees de facon unique, couleurs hex #RRGGBB, tailles > 0", function()
		local names: { [string]: boolean } = {}
		for _, planeId in Arenas.planeOrder do
			for _, box in ArenaGeometry.planeBoxes(arena.planes[planeId]) do
				expect(names[box.name]).toBeNil()
				names[box.name] = true
				expect(string.match(box.color, "^#%x%x%x%x%x%x$")).toBeTruthy()
				for axis = 1, 3 do
					expect(box.size[axis]).toBeGreaterThan(0)
				end
			end
		end
	end)

	it("respecte le budget : moins de 300 Parts", function()
		local n = ArenaGeometry.countParts(arena)
		expect(n).toBeGreaterThan(16 + 6 + 1)
		expect(n < arena.budgets.maxParts).toBeTruthy()
		expect(arena.budgets.maxParts).toBeLessThanOrEqual(300)
	end)

	it("a exactement 1 Part sol collisionnable, sous le plateau", function()
		local floors = 0
		for _, planeId in Arenas.planeOrder do
			for _, box in ArenaGeometry.planeBoxes(arena.planes[planeId]) do
				if box.canCollide then
					floors += 1
					expect(box.position[2] + box.size[2] / 2).toBeLessThanOrEqual(
						arena.scale.floorY
					)
				end
			end
		end
		expect(floors).toBe(1)
	end)
end)

describe("Arena01 : cameras", function()
	local aspects = { 16 / 9, 19.5 / 9 } -- paysage mobile courant

	it("cadre les 16 cases et le banc en vue combat (distance plausible)", function()
		local shot = arena.cameras.combat
		local d = ArenaGeometry.cameraDistance(shot)
		expect(d).toBeGreaterThan(30)
		expect(d < 120).toBeTruthy()
		expect(shot.position[2] > shot.lookAt[2] + 20).toBeTruthy()
		for _, aspect in aspects do
			for _, cell in allCells() do
				local foot = ArenaGeometry.cellTop(arena, cell.side, cell.row, cell.col)
				local head = { x = foot.x, y = foot.y + arena.scale.unitHeight, z = foot.z }
				expect(ArenaGeometry.isInView(shot, foot, aspect, 0.15)).toBeTruthy()
				expect(ArenaGeometry.isInView(shot, head, aspect, 0.15)).toBeTruthy()
			end
			for slot = 1, arena.bench.slots do
				expect(
					ArenaGeometry.isInView(
						shot,
						ArenaGeometry.benchSlotCenter(arena, slot),
						aspect,
						0.05
					)
				).toBeTruthy()
			end
		end
	end)

	it("cadre le camp A et le banc en vue preparation", function()
		local shot = arena.cameras.preparation
		for _, aspect in aspects do
			for row = 1, arena.board.rows do
				for col = 1, arena.board.columns do
					local foot = ArenaGeometry.cellTop(arena, "A", row, col)
					expect(ArenaGeometry.isInView(shot, foot, aspect, 0.1)).toBeTruthy()
				end
			end
			for slot = 1, arena.bench.slots do
				expect(
					ArenaGeometry.isInView(
						shot,
						ArenaGeometry.benchSlotCenter(arena, slot),
						aspect,
						0.1
					)
				).toBeTruthy()
			end
		end
	end)

	it("a 3 plans de camera au-dessus du sol, a plus de 10 studs de la cible", function()
		for _, shotId in Arenas.cameraOrder do
			local shot = arena.cameras[shotId]
			expect(shot.position[2] > arena.scale.floorY + 2).toBeTruthy()
			expect(ArenaGeometry.cameraDistance(shot)).toBeGreaterThan(10)
			expect(shot.fieldOfView >= 50 and shot.fieldOfView <= 80).toBeTruthy()
		end
	end)
end)
