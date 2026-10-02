--!strict
-- Boutique greybox : 5 cases (ui_shop_slot_*) + boutons Relance / XP (ui_shop_button_*). Affiche le contenu
-- recu dans OwnSeatView.shop (slug, cout, vendu) ; n'invente ni prix ni disponibilite. Les couts des boutons sont
-- des constantes partagees (Config.Duel), affichees a titre indicatif : le serveur debite ce qu'il veut.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types.Duel)
local Theme = require(script.Parent.Theme)

export type ShopPanel = {
	frame: Frame,
	slots: { Frame },
	rerollButton: TextButton,
	xpButton: TextButton,
	render: (self: ShopPanel, shop: { Types.ShopSlot }, interactive: boolean) -> (),
}

local ShopPanel = {}
ShopPanel.__index = ShopPanel

local SLOT_PX = 64

function ShopPanel.new(parent: Instance): ShopPanel
	local frame = Theme.panel("ui_shop_panel", parent)
	Theme.listLayout(frame, Enum.FillDirection.Horizontal, 6)

	local slots: { Frame } = {}
	for index = 1, Config.Duel.shopSlots do
		local slot = Theme.frame(`ui_shop_slot_{index}`, frame, Theme.colors.night)
		slot.Size = UDim2.fromOffset(SLOT_PX + 8, SLOT_PX)
		slot.LayoutOrder = index
		slot.Active = true
		slot:SetAttribute("SlotKind", "shop")
		slot:SetAttribute("SlotIndex", index)
		Theme.corner(slot, 6)
		local name = Theme.label("Name", slot, "", 11)
		name.Size = UDim2.new(1, 0, 0.6, 0)
		name.Position = UDim2.fromScale(0, 0)
		local cost = Theme.label("Cost", slot, "", 12)
		cost.Size = UDim2.new(1, 0, 0.4, 0)
		cost.Position = UDim2.fromScale(0, 0.6)
		cost.TextColor3 = Theme.colors.gold
		cost.Font = Theme.FONT
		slots[index] = slot
	end

	local buttons = Theme.frame("Buttons", frame, Theme.colors.ink, 1)
	buttons.Size = UDim2.fromOffset(96, SLOT_PX)
	buttons.LayoutOrder = Config.Duel.shopSlots + 1
	Theme.listLayout(buttons, Enum.FillDirection.Vertical, 4)
	local rerollButton =
		Theme.button("ui_shop_button_reroll", buttons, `Relance ({Config.Duel.rerollCost} or)`, Theme.colors.orange)
	rerollButton.Size = UDim2.new(1, 0, 0, 30)
	rerollButton.LayoutOrder = 1
	local xpButton =
		Theme.button("ui_shop_button_xp", buttons, `XP ({Config.Duel.xpCost} or)`, Theme.colors.purple)
	xpButton.Size = UDim2.new(1, 0, 0, 30)
	xpButton.LayoutOrder = 2

	local self = setmetatable({
		frame = frame,
		slots = slots,
		rerollButton = rerollButton,
		xpButton = xpButton,
	}, ShopPanel)
	return (self :: any) :: ShopPanel
end

function ShopPanel.render(self: ShopPanel, shop: { Types.ShopSlot }, interactive: boolean)
	for index, slot in self.slots do
		local entry = shop[index]
		local name = slot:FindFirstChild("Name") :: TextLabel
		local cost = slot:FindFirstChild("Cost") :: TextLabel
		if entry == nil then
			name.Text = ""
			cost.Text = ""
			slot.BackgroundColor3 = Theme.colors.night
			slot:SetAttribute("Sold", true)
			continue
		end
		name.Text = Theme.unitName(entry.slug)
		cost.Text = if entry.sold then "VENDU" else `{entry.cost} or`
		slot.BackgroundColor3 = if entry.sold then Theme.colors.steel else Theme.familyColor(entry.slug)
		slot.BackgroundTransparency = if entry.sold then 0.5 else 0
		slot:SetAttribute("Sold", entry.sold)
		slot:SetAttribute("Slug", entry.slug)
		name.TextColor3 = if entry.sold then Theme.colors.cream else Theme.colors.ink
	end
	Theme.setEnabled(self.rerollButton, interactive, Theme.colors.orange)
	Theme.setEnabled(self.xpButton, interactive, Theme.colors.purple)
end

return ShopPanel
