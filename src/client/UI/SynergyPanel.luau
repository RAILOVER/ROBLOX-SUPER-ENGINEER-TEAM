--!strict
-- Panneau de synergies actives (ui_synergy_panel, ui_synergy_row_*). Calcul d'AFFICHAGE seulement : slugs
-- distincts du plateau membres de chaque synergie de Config.Synergies, palier = plus grand `count` atteint.
-- Le serveur (Effects.computeSynergies) reste la reference : hors combat (HorsCombat, K.O.) et cas "Couple" ne
-- sont pas reproduits ici.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types.Duel)
local Theme = require(script.Parent.Theme)

export type SynergyRow = { name: string, count: number, tier: number, nextCount: number? }
export type SynergyPanel = {
	frame: Frame,
	render: (self: SynergyPanel, board: { Types.OwnedUnit }) -> (),
}

local SynergyPanel = {}
SynergyPanel.__index = SynergyPanel

local MAX_ROWS = 8

local ORDER: { string } = {}
for _, name in Config.Synergies.familyOrder do
	table.insert(ORDER, name)
end
for _, name in Config.Synergies.classOrder do
	table.insert(ORDER, name)
end
for name in Config.Synergies.byName do
	if not table.find(ORDER, name) then
		table.insert(ORDER, name)
	end
end

function SynergyPanel.compute(board: { Types.OwnedUnit }): { SynergyRow }
	local present: { [string]: boolean } = {}
	for _, unit in board do
		present[unit.slug] = true
	end
	local rows: { SynergyRow } = {}
	for _, name in ORDER do
		local def = Config.Synergies.byName[name]
		local count = 0
		for _, slug in def.members do
			if present[slug] then
				count += 1
			end
		end
		if count == 0 then
			continue
		end
		local tier, nextCount = 0, nil
		for index, tierDef in def.tiers do
			if count >= tierDef.count then
				tier = index
			elseif nextCount == nil then
				nextCount = tierDef.count
			end
		end
		table.insert(rows, { name = name, count = count, tier = tier, nextCount = nextCount })
	end
	table.sort(rows, function(a, b)
		if a.tier ~= b.tier then
			return a.tier > b.tier
		end
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.name < b.name
	end)
	return rows
end

function SynergyPanel.new(parent: Instance): SynergyPanel
	local frame = Theme.panel("ui_synergy_panel", parent)
	Theme.listLayout(frame, Enum.FillDirection.Vertical, 3)
	local title = Theme.label("Title", frame, "Synergies (plateau)", 12)
	title.Size = UDim2.new(1, 0, 0, 16)
	title.LayoutOrder = 0
	title.Font = Theme.FONT
	for index = 1, MAX_ROWS do
		local row = Theme.frame(`ui_synergy_row_{index}`, frame, Theme.colors.night)
		row.Size = UDim2.new(1, 0, 0, 20)
		row.LayoutOrder = index
		row.Visible = false
		Theme.corner(row, 4)
		local swatch = Theme.frame("Swatch", row, Theme.colors.steel)
		swatch.Size = UDim2.fromOffset(6, 20)
		local label = Theme.label("Label", row, "", 11)
		label.Size = UDim2.new(1, -10, 1, 0)
		label.Position = UDim2.fromOffset(10, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
	local self = setmetatable({ frame = frame }, SynergyPanel)
	return (self :: any) :: SynergyPanel
end

function SynergyPanel.render(self: SynergyPanel, board: { Types.OwnedUnit })
	local rows = SynergyPanel.compute(board)
	for index = 1, MAX_ROWS do
		local row = self.frame:FindFirstChild(`ui_synergy_row_{index}`) :: Frame
		local data = rows[index]
		row.Visible = data ~= nil
		if data == nil then
			continue
		end
		local label = row:FindFirstChild("Label") :: TextLabel
		local swatch = row:FindFirstChild("Swatch") :: Frame
		local progress = if data.nextCount then `{data.count}/{data.nextCount}` else `{data.count}`
		local tierText = if data.tier > 0 then ` palier {data.tier}` else " inactif"
		label.Text = `{data.name} {progress}{tierText}`
		label.TextColor3 = if data.tier > 0 then Theme.colors.cream else Theme.colors.steel
		swatch.BackgroundColor3 = if data.tier > 0
			then Theme.tierColors[math.min(data.tier, #Theme.tierColors)]
			else (Theme.families[data.name] or Theme.colors.steel)
	end
end

return SynergyPanel
