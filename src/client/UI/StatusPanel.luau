--!strict
-- Bandeau haut : PV des 2 sieges (ui_hp_bar_*), manche (ui_round_badge), timer serveur (ui_timer_ring, affiche
-- comme compte a rebours local recale a chaque DuelState), or (ui_gold_panel), niveau / XP (ui_level_panel).
-- Toutes les valeurs viennent de ClientView ; le timer est une interpolation d'affichage, jamais une decision.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types.Duel)
local Theme = require(script.Parent.Theme)

export type StatusPanel = {
	frame: Frame,
	render: (self: StatusPanel, view: Types.ClientView) -> (),
	tick: (self: StatusPanel, now: number) -> (),
}

local StatusPanel = {}
StatusPanel.__index = StatusPanel

type Fields = {
	frame: Frame,
	myHp: Frame,
	myHpLabel: TextLabel,
	theirHp: Frame,
	theirHpLabel: TextLabel,
	round: TextLabel,
	timer: TextLabel,
	gold: TextLabel,
	level: TextLabel,
	timerAnchor: number,
	timerSeconds: number,
	phase: string,
}

local PHASE_LABELS = {
	Lobby = "Attente",
	Preparation = "Preparation",
	Combat = "Combat",
	Resultat = "Resultat",
	Fin = "Fin du duel",
}

local function hpBar(
	name: string,
	parent: Instance,
	color: Color3,
	order: number
): (Frame, TextLabel)
	local bar = Theme.frame(name, parent, Theme.colors.night)
	bar.Size = UDim2.fromOffset(150, 24)
	bar.LayoutOrder = order
	Theme.corner(bar, 6)
	local fill = Theme.frame("Fill", bar, color)
	fill.Size = UDim2.fromScale(1, 1)
	Theme.corner(fill, 6)
	local label = Theme.label("Label", bar, "", 12)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Theme.FONT
	label.ZIndex = 3
	return bar, label
end

function StatusPanel.new(parent: Instance): StatusPanel
	local frame = Theme.panel("ui_status_bar", parent)
	Theme.listLayout(frame, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center)

	local gold = Theme.label("ui_gold_panel", frame, "", 14)
	gold.Size = UDim2.fromOffset(70, 24)
	gold.LayoutOrder = 1
	gold.TextColor3 = Theme.colors.gold
	gold.Font = Theme.FONT

	local level = Theme.label("ui_level_panel", frame, "", 12)
	level.Size = UDim2.fromOffset(110, 24)
	level.LayoutOrder = 2

	local myHp, myHpLabel = hpBar("ui_hp_bar_me", frame, Theme.colors.blue, 3)
	local round = Theme.label("ui_round_badge", frame, "", 13)
	round.Size = UDim2.fromOffset(120, 24)
	round.LayoutOrder = 4
	round.Font = Theme.FONT
	local timer = Theme.label("ui_timer_ring", frame, "", 16)
	timer.Size = UDim2.fromOffset(56, 24)
	timer.LayoutOrder = 5
	timer.Font = Theme.FONT
	timer.TextColor3 = Theme.colors.gold
	local theirHp, theirHpLabel = hpBar("ui_hp_bar_opponent", frame, Theme.colors.orange, 6)

	local self: Fields = {
		frame = frame,
		myHp = myHp,
		myHpLabel = myHpLabel,
		theirHp = theirHp,
		theirHpLabel = theirHpLabel,
		round = round,
		timer = timer,
		gold = gold,
		level = level,
		timerAnchor = os.clock(),
		timerSeconds = 0,
		phase = "Lobby",
	}
	return (setmetatable(self, StatusPanel) :: any) :: StatusPanel
end

local function setHp(bar: Frame, label: TextLabel, name: string, hp: number)
	local fill = bar:FindFirstChild("Fill") :: Frame
	fill.Size = UDim2.fromScale(math.clamp(hp / Config.Duel.playerHp, 0, 1), 1)
	label.Text = `{name} {hp} PV`
end

function StatusPanel.render(self: StatusPanel, view: Types.ClientView)
	local fields = (self :: any) :: Fields
	setHp(fields.myHp, fields.myHpLabel, "Moi", view.me.hp)
	setHp(fields.theirHp, fields.theirHpLabel, view.opponent.displayName, view.opponent.hp)
	fields.gold.Text = `{view.me.gold} or`
	fields.level.Text =
		`Niv {view.me.level}  XP {view.me.xp}/{view.me.xpToNext}  (+{view.me.nextIncome})`
	local pve = if view.isPve then " (bot)" else ""
	fields.round.Text = `Manche {view.round}{pve}\n{PHASE_LABELS[view.phase] or view.phase}`
	fields.phase = view.phase
	fields.timerSeconds = view.timerSeconds
	fields.timerAnchor = os.clock()
	self:tick(os.clock())
end

-- Compte a rebours d'affichage : timer serveur recu moins le temps ecoule depuis la reception.
function StatusPanel.tick(self: StatusPanel, now: number)
	local fields = (self :: any) :: Fields
	local remaining = math.max(0, fields.timerSeconds - (now - fields.timerAnchor))
	fields.timer.Text = if fields.phase == "Fin" then "" else `{math.ceil(remaining)} s`
end

return StatusPanel
