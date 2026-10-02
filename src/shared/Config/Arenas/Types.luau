--!strict
-- Schema d'un layout d'arene (design/levels/<arena>/layout.json transcrit par tools/gen_arena.py).
-- Module pur : les modules generes s'annotent avec ces types, luau-lsp verifie donc la structure du JSON.

export type Vec3 = { number } -- { x, y, z } en studs

export type Box = {
	name: string,
	size: Vec3,
	position: Vec3,
	color: string, -- "#RRGGBB"
	shape: string?, -- "Block" (defaut), "Ball", "Cylinder"
	rotationY: number?, -- degres autour de Y
	canCollide: boolean?, -- defaut false pour le decor (brief §17.6)
}

export type Palm = { name: string, position: Vec3, height: number, rotationY: number }

export type Plane = {
	description: string,
	palmColors: { trunk: string, crown: string },
	boxes: { Box },
	palms: { Palm },
}

export type PlaneId = "foreground" | "arena" | "background"
export type SideId = "A" | "B"
export type Side = { direction: number, color: string, frontRowColor: string }
export type CameraShot = { position: Vec3, lookAt: Vec3, fieldOfView: number }

export type ArenaDef = {
	id: string,
	name: string,
	brief: string,
	scale: {
		studsPerMeter: number,
		unitHeight: number,
		cellSize: number,
		cellPitch: number,
		cellHeight: number,
		campGap: number,
		floorY: number,
	},
	board: { rows: number, columns: number },
	sides: { A: Side, B: Side },
	bench: { side: SideId, slots: number, pitch: number, distanceFromCenter: number, color: string },
	spawn: { size: number, color: string, position: Vec3, lookAt: Vec3 },
	cameras: { combat: CameraShot, preparation: CameraShot, victory: CameraShot },
	budgets: { maxParts: number },
	planes: { foreground: Plane, arena: Plane, background: Plane },
}

return {}
