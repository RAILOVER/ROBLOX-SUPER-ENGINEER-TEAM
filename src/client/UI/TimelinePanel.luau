--!strict
-- Timeline des 10 prochaines actions (ui_timeline_bar, ui_timeline_slot_*), lue dans le plan de lecture construit
-- depuis CombatLogPayload (le serveur n'envoie pas de preview separe en M1). Hors combat : "en attente".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaybackPlan = require(ReplicatedStorage.Shared.Duel.PlaybackPlan)
local Theme = require(script.Parent.Theme)

export type TimelinePanel = {
	frame: Frame,
	render: (
		self: TimelinePanel,
		plan: PlaybackPlan.Plan?,
		fromIndex: number,
		mySide: string
	) -> (),
}

local TimelinePanel = {}
TimelinePanel.__index = TimelinePanel

TimelinePanel.COUNT = 10

local KIND_GLYPH = {
	Attack = "ATQ",
	Skill = "CAP",
	Guard = "GAR",
	Duo = "DUO",
	Mega = "MEGA",
	Skip = "...",
}

function TimelinePanel.new(parent: Instance): TimelinePanel
	local frame = Theme.panel("ui_timeline_bar", parent)
	Theme.listLayout(frame, Enum.FillDirection.Vertical, 2)
	local title = Theme.label("Title", frame, "Prochaines actions", 12)
	title.Size = UDim2.new(1, 0, 0, 16)
	title.LayoutOrder = 0
	title.Font = Theme.FONT
	for index = 1, TimelinePanel.COUNT do
		local slot = Theme.frame(`ui_timeline_slot_{index}`, frame, Theme.colors.night)
		slot.Size = UDim2.new(1, 0, 0, 18)
		slot.LayoutOrder = index
		Theme.corner(slot, 4)
		local label = Theme.label("Label", slot, "", 10)
		label.Size = UDim2.new(1, -6, 1, 0)
		label.Position = UDim2.fromOffset(6, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
	local self = setmetatable({ frame = frame }, TimelinePanel)
	return (self :: any) :: TimelinePanel
end

function TimelinePanel.render(
	self: TimelinePanel,
	plan: PlaybackPlan.Plan?,
	fromIndex: number,
	mySide: string
)
	local steps = if plan then PlaybackPlan.upcoming(plan, fromIndex, TimelinePanel.COUNT) else {}
	for index = 1, TimelinePanel.COUNT do
		local slot = self.frame:FindFirstChild(`ui_timeline_slot_{index}`) :: Frame
		local label = slot:FindFirstChild("Label") :: TextLabel
		local step = steps[index]
		if step == nil then
			label.Text = if index == 1 and plan == nil then "en attente du combat" else ""
			slot.BackgroundColor3 = Theme.colors.night
			continue
		end
		local mine = string.sub(step.actorCell, 1, 1) == mySide
		local glyph = KIND_GLYPH[step.kind] or step.kind
		label.Text = `{step.t}. {Theme.unitName(step.actorSlug)} {glyph}`
		label.TextColor3 = if step.kind == "Mega" then Theme.colors.gold else Theme.colors.cream
		slot.BackgroundColor3 = if mine then Theme.colors.night else Color3.fromHex("#5A2A2A")
		slot.BackgroundTransparency = if index == 1 then 0 else 0.35
	end
end

return TimelinePanel
