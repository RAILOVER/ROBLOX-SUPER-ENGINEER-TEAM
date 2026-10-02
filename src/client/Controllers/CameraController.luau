--!strict
-- Camera du duel : 3 cadrages fixes de Arena01 (preparation, combat, victory), appliques en CameraType.Scriptable.
-- Aucune lecture de l'etat de jeu ici : HudController choisit le cadrage selon la phase ou le bouton presse.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraController = {}

export type ShotName = "preparation" | "combat" | "victory"

local TWEEN = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local current: ShotName? = nil

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

function CameraController.start()
	CameraController.set("preparation")
end

function CameraController.current(): ShotName?
	return current
end

function CameraController.set(shot: ShotName)
	local arena = Config.Arenas.byId["arena-01"]
	local def = arena.cameras[shot]
	if def == nil then
		warn(`[CameraController] cadrage inconnu : {shot}`)
		return
	end
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local goal = CFrame.lookAt(vec(def.position), vec(def.lookAt))
	if current == nil then
		camera.CFrame = goal
		camera.FieldOfView = def.fieldOfView
	else
		TweenService:Create(camera, TWEEN, { CFrame = goal, FieldOfView = def.fieldOfView }):Play()
	end
	current = shot
end

return CameraController
