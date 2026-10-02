--!strict
-- Glisser-deposer tactile et souris (T-0012) : boutique -> banc (BuyShopSlot), banc <-> plateau (PlaceUnit /
-- BenchUnit), banc ou plateau -> zone de vente (SellUnit). UserInputService InputBegan / InputChanged / InputEnded,
-- 1 pointeur a la fois. Aucune mutation locale definitive : la tuile est deplacee en "optimiste" (semi-transparente)
-- et le HUD est integralement redessine au prochain DuelState ; si aucun DuelState n'arrive sous RESYNC_SECONDS
-- (intention ignoree par le serveur), on redessine depuis le dernier etat confirme. Un tap (sans deplacement)
-- sur une case de boutique achete, sur une tuile selectionne l'unite (tactique individuelle).

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local DuelController = require(script.Parent.DuelController)
local HudController = require(script.Parent.HudController)
local Theme = require(script.Parent.Parent.UI.Theme)

local DragDrop = {}

local TAP_PX = 10
local RESYNC_SECONDS = 0.75

type Source = {
	kind: "shop" | "unit",
	slotIndex: number?,
	instanceId: string?,
	slug: string,
	tile: GuiObject,
}
type Drag = {
	input: InputObject,
	source: Source,
	startPos: Vector2,
	ghost: Frame,
	hoverTarget: GuiObject?,
}

local connections: { RBXScriptConnection } = {}
local active: Drag? = nil

local function pointerPosition(input: InputObject, screenGui: ScreenGui): Vector2
	-- InputObject.Position est deja exprime sous la barre Roblox ; si le ScreenGui ignorait l'inset, il faudrait
	-- le rajouter pour retomber dans l'espace AbsolutePosition de ses enfants.
	local pos = Vector2.new(input.Position.X, input.Position.Y)
	if screenGui.IgnoreGuiInset then
		local inset = GuiService:GetGuiInset()
		pos += inset
	end
	return pos
end

local function slotKind(object: Instance): string?
	local kind = object:GetAttribute("SlotKind")
	return if type(kind) == "string" then kind else nil
end

local function numberAttribute(object: Instance, name: string): number?
	local value = object:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

local function stringAttribute(object: Instance, name: string): string?
	local value = object:GetAttribute(name)
	return if type(value) == "string" then value else nil
end

-- Objets du HUD sous le pointeur, du plus haut au plus bas.
local function objectsAt(pos: Vector2): { GuiObject }
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui == nil then
		return {}
	end
	return playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)
end

local function findSource(pos: Vector2): Source?
	for _, object in objectsAt(pos) do
		if object.Name == "Unit" then
			local instanceId = stringAttribute(object, "InstanceId")
			if instanceId then
				return {
					kind = "unit",
					instanceId = instanceId,
					slug = stringAttribute(object, "Slug") or "",
					tile = object,
				}
			end
		end
		if slotKind(object) == "shop" and object:GetAttribute("Sold") ~= true then
			local index = numberAttribute(object, "SlotIndex")
			if index then
				return {
					kind = "shop",
					slotIndex = index,
					slug = stringAttribute(object, "Slug") or "",
					tile = object,
				}
			end
		end
	end
	return nil
end

-- Case cible (bench / board / sell) sous le pointeur.
local function findTarget(pos: Vector2): GuiObject?
	for _, object in objectsAt(pos) do
		local kind = slotKind(object)
		if kind == "bench" or kind == "board" or kind == "sell" then
			return object
		end
	end
	return nil
end

local function placeGhost(drag: Drag, pos: Vector2)
	local handles = HudController.handles()
	if handles == nil then
		return
	end
	local scale = handles.scale.Scale
	local local_ = (pos - handles.root.AbsolutePosition) / scale
	drag.ghost.Position = UDim2.fromOffset(local_.X, local_.Y)
end

local function setHover(drag: Drag, target: GuiObject?)
	if drag.hoverTarget == target then
		return
	end
	if drag.hoverTarget then
		local previous = drag.hoverTarget:FindFirstChild("DropHighlight")
		if previous then
			previous:Destroy()
		end
	end
	drag.hoverTarget = target
	if target then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "DropHighlight"
		stroke.Thickness = 3
		stroke.Color = Theme.colors.gold
		stroke.Parent = target
	end
end

local function beginDrag(input: InputObject)
	local handles = HudController.handles()
	if handles == nil then
		return
	end
	local pos = pointerPosition(input, handles.screenGui)
	local source = findSource(pos)
	if source == nil then
		return
	end
	local ghost = Theme.frame("DragGhost", handles.root, Theme.familyColor(source.slug), 0.2)
	ghost.Size = UDim2.fromOffset(52, 52)
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.ZIndex = 100
	Theme.corner(ghost, 6)
	local label = Theme.label("Name", ghost, Theme.unitName(source.slug), 11)
	label.Size = UDim2.fromScale(1, 1)
	label.TextColor3 = Theme.colors.ink
	label.ZIndex = 101
	source.tile.BackgroundTransparency = 0.6
	active = { input = input, source = source, startPos = pos, ghost = ghost, hoverTarget = nil }
	placeGhost(active :: Drag, pos)
end

-- Affichage optimiste : la tuile rejoint la case cible, grisee, jusqu'au prochain DuelState (ou resync).
local function optimisticMove(source: Source, target: GuiObject)
	if source.kind ~= "unit" then
		return
	end
	source.tile.Parent = target
	source.tile.BackgroundTransparency = 0.5
	source.tile:SetAttribute("Optimistic", true)
	local version = DuelController.getStateVersion()
	task.delay(RESYNC_SECONDS, function()
		local handles = HudController.handles()
		if handles and DuelController.getStateVersion() == version then
			handles.rerender()
		end
	end)
end

local function sendIntent(source: Source, target: GuiObject): boolean
	local kind = slotKind(target)
	if source.kind == "shop" then
		if kind == "bench" and source.slotIndex then
			return DuelController.buyShopSlot(source.slotIndex)
		end
		return false
	end
	local instanceId = source.instanceId
	if instanceId == nil then
		return false
	end
	local fromKind = if source.tile.Parent then slotKind(source.tile.Parent :: Instance) else nil
	if kind == "board" then
		local row, col = numberAttribute(target, "Row"), numberAttribute(target, "Col")
		if row and col and target:FindFirstChild("Unit") == nil then
			return DuelController.placeUnit(instanceId, row, col)
		end
		return false
	elseif kind == "bench" then
		if fromKind == "board" then
			return DuelController.benchUnit(instanceId)
		end
		return false
	elseif kind == "sell" then
		return DuelController.sellUnit(instanceId)
	end
	return false
end

local function endDrag(input: InputObject)
	local drag = active
	if drag == nil or drag.input ~= input then
		return
	end
	active = nil
	local handles = HudController.handles()
	setHover(drag, nil)
	drag.ghost:Destroy()
	if handles == nil then
		return
	end
	local pos = pointerPosition(input, handles.screenGui)
	local moved = (pos - drag.startPos).Magnitude
	if moved < TAP_PX then
		drag.source.tile.BackgroundTransparency = 0
		if drag.source.kind == "shop" and drag.source.slotIndex then
			DuelController.buyShopSlot(drag.source.slotIndex)
		else
			handles.selectUnit(drag.source.instanceId)
		end
		return
	end
	local target = findTarget(pos)
	if target and sendIntent(drag.source, target) then
		optimisticMove(drag.source, target)
	else
		handles.rerender()
	end
end

local function isPointerBegin(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

function DragDrop.start()
	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject)
			-- gameProcessedEvent est vrai au-dessus d'une Frame Active : on ne le filtre pas, on teste la cible.
			if active == nil and isPointerBegin(input) then
				beginDrag(input)
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			local drag = active
			if drag == nil then
				return
			end
			local isMouseMove = drag.input.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseMovement
			if input == drag.input or isMouseMove then
				local handles = HudController.handles()
				if handles then
					local pos = pointerPosition(input, handles.screenGui)
					placeGhost(drag, pos)
					setHover(drag, findTarget(pos))
				end
			end
		end)
	)
	table.insert(
		connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			endDrag(input)
		end)
	)
end

function DragDrop.stop()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	local drag = active
	if drag then
		drag.ghost:Destroy()
		active = nil
	end
end

return DragDrop
