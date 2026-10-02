--!strict
-- Boutons d'action : Mega Combo (ui_megacombo_button, grise tant que le contrat ne propose pas d'intention
-- MegaCombo : voir tickets T-0032), Pret (ui_button_primary_ready), selecteur de tactique (ui_tactic_*) et 3
-- cadrages camera (ui_camera_*). Les callbacks recoivent des intentions ; aucune regle n'est evaluee ici.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Theme = require(script.Parent.Theme)

export type Callbacks = {
	onMega: () -> (),
	onReady: () -> (),
	onTactic: (tactic: string) -> (),
	onCamera: (shot: string) -> (),
}

export type ActionBar = {
	frame: Frame,
	megaButton: TextButton,
	readyButton: TextButton,
	tacticButtons: { [string]: TextButton },
	cameraButtons: { [string]: TextButton },
	connections: { RBXScriptConnection },
	setMega: (self: ActionBar, gauge: number, available: boolean) -> (),
	setReady: (self: ActionBar, open: boolean, ready: boolean) -> (),
	setTactic: (self: ActionBar, open: boolean, current: string?, label: string) -> (),
	setCamera: (self: ActionBar, shot: string) -> (),
	destroy: (self: ActionBar) -> (),
}

local ActionBar = {}
ActionBar.__index = ActionBar

ActionBar.TACTICS = { "Agressif", "Equilibre", "Prudent" }
ActionBar.CAMERAS = { "preparation", "combat", "victory" }
local CAMERA_LABELS = { preparation = "Cam prepa", combat = "Cam combat", victory = "Cam victoire" }

function ActionBar.new(parent: Instance, callbacks: Callbacks): ActionBar
	local frame = Theme.panel("ui_action_bar", parent)
	Theme.listLayout(frame, Enum.FillDirection.Vertical, 4)
	local connections: { RBXScriptConnection } = {}

	local megaButton = Theme.button("ui_megacombo_button", frame, "MEGA COMBO", Theme.colors.purple)
	megaButton.Size = UDim2.new(1, 0, 0, 44)
	megaButton.LayoutOrder = 1
	table.insert(
		connections,
		megaButton.Activated:Connect(function()
			if megaButton:GetAttribute("Enabled") == true then
				callbacks.onMega()
			end
		end)
	)

	local readyButton = Theme.button("ui_button_primary_ready", frame, "PRET", Theme.colors.green)
	readyButton.Size = UDim2.new(1, 0, 0, 44)
	readyButton.LayoutOrder = 2
	table.insert(
		connections,
		readyButton.Activated:Connect(function()
			if readyButton:GetAttribute("Enabled") == true then
				callbacks.onReady()
			end
		end)
	)

	local tacticTitle = Theme.label("ui_tactic_title", frame, "Tactique (toutes)", 11)
	tacticTitle.Size = UDim2.new(1, 0, 0, 14)
	tacticTitle.LayoutOrder = 3
	local tacticRow = Theme.frame("ui_tactic_row", frame, Theme.colors.ink, 1)
	tacticRow.Size = UDim2.new(1, 0, 0, 44)
	tacticRow.LayoutOrder = 4
	Theme.listLayout(tacticRow, Enum.FillDirection.Horizontal, 3)
	local tacticButtons: { [string]: TextButton } = {}
	for index, tactic in ActionBar.TACTICS do
		local button = Theme.button(
			`ui_tactic_{string.lower(tactic)}`,
			tacticRow,
			string.sub(tactic, 1, 4),
			Theme.colors.night
		)
		button.Size = UDim2.new(1 / #ActionBar.TACTICS, -2, 1, 0)
		button.LayoutOrder = index
		button.TextSize = 11
		tacticButtons[tactic] = button
		table.insert(
			connections,
			button.Activated:Connect(function()
				if button:GetAttribute("Enabled") == true then
					callbacks.onTactic(tactic)
				end
			end)
		)
	end

	local cameraRow = Theme.frame("ui_camera_row", frame, Theme.colors.ink, 1)
	cameraRow.Size = UDim2.new(1, 0, 0, 44)
	cameraRow.LayoutOrder = 5
	Theme.listLayout(cameraRow, Enum.FillDirection.Horizontal, 3)
	local cameraButtons: { [string]: TextButton } = {}
	for index, shot in ActionBar.CAMERAS do
		local button =
			Theme.button(`ui_camera_{shot}`, cameraRow, CAMERA_LABELS[shot], Theme.colors.steel)
		button.Size = UDim2.new(1 / #ActionBar.CAMERAS, -2, 1, 0)
		button.LayoutOrder = index
		button.TextSize = 10
		cameraButtons[shot] = button
		table.insert(
			connections,
			button.Activated:Connect(function()
				callbacks.onCamera(shot)
			end)
		)
	end

	local self = setmetatable({
		frame = frame,
		megaButton = megaButton,
		readyButton = readyButton,
		tacticButtons = tacticButtons,
		cameraButtons = cameraButtons,
		connections = connections,
	}, ActionBar)
	return (self :: any) :: ActionBar
end

-- `gauge` = derniere jauge Mega lue dans le journal (0 a Config.Combat.megaGaugeMax), affichage seulement.
function ActionBar.setMega(self: ActionBar, gauge: number, available: boolean)
	local pct = math.floor(math.clamp(gauge / Config.Combat.megaGaugeMax, 0, 1) * 100 + 0.5)
	self.megaButton.Text = if available then `MEGA COMBO {pct} %` else `MEGA COMBO {pct} % (auto)`
	Theme.setEnabled(self.megaButton, available, Theme.colors.purple)
end

function ActionBar.setReady(self: ActionBar, open: boolean, ready: boolean)
	self.readyButton.Text = if ready then "PRET (envoye)" else "PRET"
	Theme.setEnabled(self.readyButton, open and not ready, Theme.colors.green)
end

function ActionBar.setTactic(self: ActionBar, open: boolean, current: string?, label: string)
	local title = self.frame:FindFirstChild("ui_tactic_title") :: TextLabel
	title.Text = label
	for tactic, button in self.tacticButtons do
		Theme.setEnabled(
			button,
			open,
			if tactic == current then Theme.colors.blue else Theme.colors.night
		)
	end
end

function ActionBar.setCamera(self: ActionBar, shot: string)
	for name, button in self.cameraButtons do
		button.BackgroundColor3 = if name == shot then Theme.colors.blue else Theme.colors.steel
	end
end

function ActionBar.destroy(self: ActionBar)
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.frame:Destroy()
end

return ActionBar
