--!strict
-- Bandeau central (ui_banner) : phase d'attente, "MEGA COMBO" placeholder, resultat de manche, fin du duel.
-- Texte et couleurs plates seulement.

local Theme = require(script.Parent.Theme)

export type Banner = {
	frame: Frame,
	label: TextLabel,
	show: (self: Banner, text: string, color: Color3, seconds: number?) -> (),
	hide: (self: Banner) -> (),
}

local Banner = {}
Banner.__index = Banner

function Banner.new(parent: Instance): Banner
	local frame = Theme.frame("ui_banner", parent, Theme.colors.ink, 0.15)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.42)
	frame.Size = UDim2.fromOffset(360, 64)
	frame.ZIndex = 50
	frame.Visible = false
	Theme.corner(frame, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.colors.gold
	stroke.Parent = frame
	local label = Theme.label("Label", frame, "", 22)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.FONT
	label.ZIndex = 51
	local self = setmetatable({ frame = frame, label = label, token = 0 }, Banner)
	return (self :: any) :: Banner
end

function Banner.show(self: Banner, text: string, color: Color3, seconds: number?)
	local fields = (self :: any) :: { token: number }
	fields.token += 1
	local token = fields.token
	self.label.Text = text
	self.label.TextColor3 = color
	local stroke = self.frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
	self.frame.Visible = true
	if seconds then
		task.delay(seconds, function()
			if fields.token == token then
				self.frame.Visible = false
			end
		end)
	end
end

function Banner.hide(self: Banner)
	local fields = (self :: any) :: { token: number }
	fields.token += 1
	self.frame.Visible = false
end

return Banner
