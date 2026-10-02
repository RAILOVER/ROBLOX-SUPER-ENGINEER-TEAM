--!strict
-- HUD greybox du duel (T-0012), cree en Luau. Paysage mobile d'abord : canevas de reference 400 px de haut,
-- UIScale = clamp(viewport.Y / 400, 1, 2.4) (jamais < 1 : les cibles tactiles de 44 px restent >= 44 px reels),
-- ScreenInsets = DeviceSafeInsets + SafeAreaCompatibility.FullscreenExtension, IgnoreGuiInset = false (la barre
-- Roblox reste libre). Le HUD ne fait que redessiner ClientView ; la source de verite est DuelController.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Shared.Types.Duel)
local PlaybackPlan = require(ReplicatedStorage.Shared.Duel.PlaybackPlan)
local DuelController = require(script.Parent.DuelController)
local CameraController = require(script.Parent.CameraController)
local CombatPlayback = require(script.Parent.CombatPlayback)
local Theme = require(script.Parent.Parent.UI.Theme)
local ShopPanel = require(script.Parent.Parent.UI.ShopPanel)
local BoardPanel = require(script.Parent.Parent.UI.BoardPanel)
local StatusPanel = require(script.Parent.Parent.UI.StatusPanel)
local SynergyPanel = require(script.Parent.Parent.UI.SynergyPanel)
local TimelinePanel = require(script.Parent.Parent.UI.TimelinePanel)
local ActionBar = require(script.Parent.Parent.UI.ActionBar)
local Banner = require(script.Parent.Parent.UI.Banner)

export type Handles = {
	screenGui: ScreenGui,
	root: Frame,
	scale: UIScale,
	shop: ShopPanel.ShopPanel,
	board: BoardPanel.BoardPanel,
	rerender: () -> (),
	selectUnit: (instanceId: string?) -> (),
}

local HudController = {}

local REFERENCE_HEIGHT = 400
local MAX_SCALE = 2.4
local PHASE_SHOTS: { [string]: CameraController.ShotName } = {
	Preparation = "preparation" :: CameraController.ShotName,
	Combat = "combat" :: CameraController.ShotName,
	Resultat = "victory" :: CameraController.ShotName,
	Fin = "victory" :: CameraController.ShotName,
}

local handles: Handles? = nil
local status: StatusPanel.StatusPanel? = nil
local synergies: SynergyPanel.SynergyPanel? = nil
local timeline: TimelinePanel.TimelinePanel? = nil
local actions: ActionBar.ActionBar? = nil
local banner: Banner.Banner? = nil
local joinButton: TextButton? = nil
local connections: { RBXScriptConnection } = {}
local disconnects: { () -> () } = {}
local selectedId: string? = nil
local lastPhase: string? = nil
local currentPlan: PlaybackPlan.Plan? = nil
local mySide = "A"

local function applyScale(h: Handles)
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local viewport = camera.ViewportSize
	local scale = math.clamp(viewport.Y / REFERENCE_HEIGHT, 1, MAX_SCALE)
	h.scale.Scale = scale
	h.root.Size = UDim2.fromOffset(math.floor(viewport.X / scale), math.floor(viewport.Y / scale))
	h.root:SetAttribute("CanvasScale", scale)
end

local function selectedUnit(view: Types.ClientView): Types.OwnedUnit?
	for _, list in { view.me.board, view.me.bench } do
		for _, unit in list do
			if unit.instanceId == selectedId then
				return unit
			end
		end
	end
	return nil
end

local function render(view: Types.ClientView)
	local h = handles
	if h == nil or status == nil or synergies == nil or actions == nil or banner == nil then
		return
	end
	local prep = view.phase == "Preparation"
	status:render(view)
	h.shop:render(view.me.shop, prep)
	if selectedUnit(view) == nil then
		selectedId = nil
	end
	h.board:render(view.me, selectedId)
	synergies:render(view.me.board)
	actions:setReady(DuelController.isIntentOpen("Ready"), view.me.ready)
	local unit = selectedUnit(view)
	actions:setTactic(
		DuelController.isIntentOpen("SetTactic"),
		if unit then unit.tactic else nil,
		if unit then `Tactique : {Theme.unitName(unit.slug)}` else "Tactique (toutes les unites)"
	)
	-- Aucune intention MegaCombo dans DuelRemotes (T-0011) : bouton visible mais grise (ticket T-0032).
	actions:setMega(CombatPlayback.lastMegaGauge(), DuelController.isIntentOpen("MegaCombo"))
	if joinButton then
		joinButton.Visible = view.phase == "Lobby"
	end
	if view.phase ~= lastPhase then
		lastPhase = view.phase
		local shot: CameraController.ShotName? = PHASE_SHOTS[view.phase]
		if shot then
			CameraController.set(shot)
			actions:setCamera(shot)
		end
		if view.phase == "Lobby" then
			banner:show("En attente d'un adversaire...", Theme.colors.cream)
		elseif view.phase == "Preparation" then
			CombatPlayback.clear()
			currentPlan = nil
			if timeline then
				timeline:render(nil, 1, mySide)
			end
			banner:show(`Manche {view.round} : preparation`, Theme.colors.gold, 2)
		elseif view.phase == "Combat" then
			banner:hide()
		end
	end
end

local function onCombatLog(payload: Types.CombatLogPayload)
	mySide = payload.side
	currentPlan = CombatPlayback.play(payload)
	if timeline then
		timeline:render(currentPlan, 1, mySide)
	end
end

local function onStep(plan: PlaybackPlan.Plan, index: number)
	if timeline then
		timeline:render(plan, index + 1, mySide)
	end
	if actions then
		actions:setMega(plan[index].gauges.mega, DuelController.isIntentOpen("MegaCombo"))
	end
end

local function onEnded(payload: Types.DuelEndedPayload)
	if banner == nil then
		return
	end
	local text = if payload.youWon
		then "VICTOIRE"
		elseif payload.reason == "draw" then "EGALITE"
		else "DEFAITE"
	banner:show(
		`{text} en {payload.rounds} manches\nPV {payload.hp[1]} / {payload.hp[2]} ({payload.reason})`,
		if payload.youWon then Theme.colors.green else Theme.colors.red
	)
end

local function buildLayout(h: Handles)
	local root = h.root
	local top = Theme.frame("TopRow", root, Theme.colors.ink, 1)
	top.Size = UDim2.new(1, 0, 0, 44)
	top.Position = UDim2.fromOffset(0, 0)
	local statusPanel = StatusPanel.new(top)
	statusPanel.frame.Size = UDim2.new(1, -12, 1, -4)
	statusPanel.frame.Position = UDim2.fromOffset(6, 2)
	status = statusPanel

	local left = Theme.frame("LeftColumn", root, Theme.colors.ink, 1)
	left.Size = UDim2.new(0.2, -8, 1, -52)
	left.Position = UDim2.fromOffset(6, 48)
	local synergyPanel = SynergyPanel.new(left)
	synergyPanel.frame.Size = UDim2.fromScale(1, 1)
	synergies = synergyPanel

	local center = Theme.frame("CenterColumn", root, Theme.colors.ink, 1)
	center.Size = UDim2.new(0.6, -8, 1, -52)
	center.Position = UDim2.new(0.2, 4, 0, 48)
	Theme.listLayout(center, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center)
	h.board.frame.Parent = center
	h.board.frame.Size = UDim2.new(1, 0, 0, 200)
	h.board.frame.LayoutOrder = 1
	h.shop.frame.Parent = center
	h.shop.frame.Size = UDim2.new(1, 0, 0, 80)
	h.shop.frame.LayoutOrder = 2

	local right = Theme.frame("RightColumn", root, Theme.colors.ink, 1)
	right.Size = UDim2.new(0.2, -8, 1, -52)
	right.Position = UDim2.new(0.8, 2, 0, 48)
	Theme.listLayout(right, Enum.FillDirection.Vertical, 6)
	local timelinePanel = TimelinePanel.new(right)
	timelinePanel.frame.Size = UDim2.fromScale(1, 0)
	timelinePanel.frame.AutomaticSize = Enum.AutomaticSize.Y
	timelinePanel.frame.LayoutOrder = 1
	timeline = timelinePanel
	local actionBar = ActionBar.new(right, {
		onMega = function()
			DuelController.send("MegaCombo")
		end,
		onReady = function()
			DuelController.ready()
		end,
		onTactic = function(tactic)
			DuelController.setTactic(tactic :: Types.Tactic, selectedId)
		end,
		onCamera = function(shot)
			CameraController.set(shot :: CameraController.ShotName)
			if actions then
				actions:setCamera(shot)
			end
		end,
	})
	actionBar.frame.Size = UDim2.fromScale(1, 0)
	actionBar.frame.AutomaticSize = Enum.AutomaticSize.Y
	actionBar.frame.LayoutOrder = 2
	actions = actionBar

	banner = Banner.new(root)
	local join =
		Theme.button("ui_button_primary_join", root, "Rejoindre le duel", Theme.colors.green)
	join.AnchorPoint = Vector2.new(0.5, 0.5)
	join.Position = UDim2.fromScale(0.5, 0.58)
	join.Size = UDim2.fromOffset(200, 48)
	join.ZIndex = 52
	join.Visible = false
	table.insert(
		connections,
		join.Activated:Connect(function()
			DuelController.join()
		end)
	)
	joinButton = join

	table.insert(
		connections,
		h.shop.rerollButton.Activated:Connect(function()
			if h.shop.rerollButton:GetAttribute("Enabled") == true then
				DuelController.reroll()
			end
		end)
	)
	table.insert(
		connections,
		h.shop.xpButton.Activated:Connect(function()
			if h.shop.xpButton:GetAttribute("Enabled") == true then
				DuelController.buyXp()
			end
		end)
	)
end

function HudController.start(): Handles
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui", 10) :: PlayerGui

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DuelHud"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	screenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 10

	local root = Theme.frame("Root", screenGui, Theme.colors.ink, 1)
	root.Position = UDim2.fromOffset(0, 0)
	local scale = Instance.new("UIScale")
	scale.Parent = root

	local h: Handles = {
		screenGui = screenGui,
		root = root,
		scale = scale,
		shop = ShopPanel.new(root),
		board = BoardPanel.new(root),
		rerender = function()
			local view = DuelController.getView()
			if view then
				render(view)
			end
		end,
		selectUnit = function(instanceId: string?)
			selectedId = if selectedId == instanceId then nil else instanceId
			local view = DuelController.getView()
			if view then
				render(view)
			end
		end,
	}
	handles = h
	buildLayout(h)
	applyScale(h)
	screenGui.Parent = playerGui

	local camera = Workspace.CurrentCamera
	if camera then
		table.insert(
			connections,
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				applyScale(h)
			end)
		)
	end
	local accumulator = 0
	table.insert(
		connections,
		RunService.Heartbeat:Connect(function(dt)
			accumulator += dt
			if accumulator >= 0.25 and status then
				accumulator = 0
				status:tick(os.clock())
			end
		end)
	)
	CombatPlayback.setStepHook(onStep)
	table.insert(disconnects, DuelController.onState(render))
	table.insert(disconnects, DuelController.onCombatLog(onCombatLog))
	table.insert(disconnects, DuelController.onEnded(onEnded))
	if banner then
		banner:show("Connexion au duel...", Theme.colors.cream)
	end
	return h
end

function HudController.stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, disconnect in disconnects do
		disconnect()
	end
	table.clear(disconnects)
	if actions then
		actions:destroy()
	end
	if handles then
		handles.screenGui:Destroy()
	end
	handles = nil
end

function HudController.handles(): Handles?
	return handles
end

return HudController
