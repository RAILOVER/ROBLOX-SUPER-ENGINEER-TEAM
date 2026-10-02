--!strict
-- Palette greybox (art/style-bible/BATTLEROT.md section 3) et fabriques d'elements UI. Aucune image : Frames,
-- couleurs plates, texte. Chaque bouton recoit une cible tactile minimale de MIN_TOUCH px (UISizeConstraint +
-- UIPadding), mesuree avant UIScale (le HUD n'applique jamais une echelle < 1, voir HudController).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Theme = {}

Theme.MIN_TOUCH = 44
Theme.FONT = Enum.Font.GothamBold
Theme.FONT_BODY = Enum.Font.Gotham

Theme.colors = table.freeze({
	ink = Color3.fromHex("#1A1A2E"),
	cream = Color3.fromHex("#FFF8E7"),
	blue = Color3.fromHex("#2E7CF6"),
	night = Color3.fromHex("#1B3F8F"),
	gold = Color3.fromHex("#FFC93C"),
	orange = Color3.fromHex("#F28C28"),
	green = Color3.fromHex("#3DDC5C"),
	red = Color3.fromHex("#FF4D4D"),
	purple = Color3.fromHex("#A44CF2"),
	steel = Color3.fromHex("#8FA6C1"),
})

Theme.families = table.freeze({
	Mare = Color3.fromHex("#2EC4F1"),
	Cielo = Color3.fromHex("#8EC5FF"),
	Caffe = Color3.fromHex("#8B5A3C"),
	Giungla = Color3.fromHex("#3CB44B"),
	Frutta = Color3.fromHex("#FF5E7E"),
	Macchina = Color3.fromHex("#8A9AA9"),
	Cosmo = Color3.fromHex("#6C3CE0"),
	Sahur = Color3.fromHex("#FF9F43"),
	Tentafruit = Color3.fromHex("#FF7AC6"),
} :: { [string]: Color3 })

Theme.tierColors = table.freeze({
	Color3.fromHex("#C9843F"), -- bronze
	Color3.fromHex("#C0C8D4"), -- argent
	Color3.fromHex("#FFC93C"), -- or
	Color3.fromHex("#A44CF2"), -- prisme
})

-- Couleur de la premiere famille du slug (bible section 3), gris acier si inconnu.
function Theme.familyColor(slug: string): Color3
	local def = Config.Roster.units[slug]
	if def then
		local color = Theme.families[def.families[1]]
		if color then
			return color
		end
	end
	return Theme.colors.steel
end

function Theme.unitName(slug: string): string
	local def = Config.Roster.units[slug]
	return if def then def.name else slug
end

function Theme.stars(count: number): string
	return string.rep("*", math.clamp(count, 1, 3))
end

function Theme.corner(parent: GuiObject, radius: number?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
	return corner
end

function Theme.padding(parent: GuiObject, px: number): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, px)
	padding.PaddingBottom = UDim.new(0, px)
	padding.PaddingLeft = UDim.new(0, px)
	padding.PaddingRight = UDim.new(0, px)
	padding.Parent = parent
	return padding
end

function Theme.frame(name: string, parent: Instance, color: Color3, transparency: number?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

function Theme.panel(name: string, parent: Instance): Frame
	local frame = Theme.frame(name, parent, Theme.colors.ink, 0.25)
	Theme.corner(frame, 8)
	Theme.padding(frame, 6)
	return frame
end

function Theme.label(name: string, parent: Instance, text: string, textSize: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = Theme.FONT_BODY
	label.TextColor3 = Theme.colors.cream
	label.TextSize = textSize or 14
	label.TextScaled = false
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end

function Theme.button(name: string, parent: Instance, text: string, color: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = color or Theme.colors.blue
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Theme.FONT
	button.TextColor3 = Theme.colors.cream
	button.TextSize = 14
	button.TextWrapped = true
	button.Text = text
	button.Size = UDim2.fromOffset(Theme.MIN_TOUCH, Theme.MIN_TOUCH)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(Theme.MIN_TOUCH, Theme.MIN_TOUCH)
	constraint.Parent = button
	Theme.padding(button, 4)
	Theme.corner(button, 8)
	button.Parent = parent
	return button
end

-- Grise un bouton sans le detruire : l'intention reste visible mais inactive (le serveur tranche de toute facon).
function Theme.setEnabled(button: TextButton, enabled: boolean, activeColor: Color3?)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = if enabled
		then (activeColor or Theme.colors.blue)
		else Theme.colors.steel
	button.TextTransparency = if enabled then 0 else 0.45
	button:SetAttribute("Enabled", enabled)
end

function Theme.listLayout(
	parent: Instance,
	direction: Enum.FillDirection,
	paddingPx: number,
	alignment: Enum.HorizontalAlignment?
): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.Padding = UDim.new(0, paddingPx)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = parent
	return layout
end

function Theme.gridLayout(parent: Instance, cellPx: number, paddingPx: number): UIGridLayout
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(cellPx, cellPx)
	layout.CellPadding = UDim2.fromOffset(paddingPx, paddingPx)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

-- Tuile d'unite (banc, plateau) : couleur de famille, nom + etoiles, attribut InstanceId lu par DragDrop.
function Theme.unitTile(parent: GuiObject, instanceId: string, slug: string, stars: number): Frame
	local tile = Theme.frame("Unit", parent, Theme.familyColor(slug))
	tile.Size = UDim2.fromScale(1, 1)
	tile.ZIndex = parent.ZIndex + 1
	tile.Active = true
	tile:SetAttribute("InstanceId", instanceId)
	tile:SetAttribute("Slug", slug)
	Theme.corner(tile, 6)
	local label = Theme.label("Name", tile, `{Theme.unitName(slug)}\n{Theme.stars(stars)}`, 11)
	label.Size = UDim2.fromScale(1, 1)
	label.TextColor3 = Theme.colors.ink
	label.ZIndex = tile.ZIndex + 1
	return tile
end

return Theme
