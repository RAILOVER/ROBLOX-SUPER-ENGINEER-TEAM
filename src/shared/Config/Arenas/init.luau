--!strict
-- Index des arenes (brief §15.5) et types de leur layout. Chaque Arena0X.luau est GENERE par tools/gen_arena.py
-- depuis design/levels/arena-0X/layout.json : ne pas editer les tables a la main. Module pur (aucun type Roblox).

local Types = require(script.Types)

export type Vec3 = Types.Vec3
export type Box = Types.Box
export type Palm = Types.Palm
export type Plane = Types.Plane
export type PlaneId = Types.PlaneId
export type SideId = Types.SideId
export type Side = Types.Side
export type CameraShot = Types.CameraShot
export type ArenaDef = Types.ArenaDef

local Arena01: ArenaDef = require(script.Arena01)

-- Ordre de construction fixe (du plus proche de la camera au plus lointain).
local planeOrder: { PlaneId } = { "foreground", "arena", "background" }
local sideOrder: { SideId } = { "A", "B" }
local cameraOrder: { "preparation" | "combat" | "victory" } = { "preparation", "combat", "victory" }

local Arenas = {
	planeOrder = planeOrder,
	sideOrder = sideOrder,
	cameraOrder = cameraOrder,
	byId = { ["arena-01"] = Arena01 } :: { [string]: ArenaDef },
	order = { "arena-01" },
}

return table.freeze(Arenas)
