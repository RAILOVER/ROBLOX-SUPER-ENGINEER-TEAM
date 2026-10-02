--!strict
-- Banc (6, ui_bench_slot_*), plateau 2 x 4 vu de dessus (ui_board_cell_*) et zone de vente (ui_sell_zone).
-- Vue schematique 2D : chaque case est une Frame ; les unites sont des tuiles recreees a chaque DuelState recu.
-- Les cases portent des attributs (SlotKind, SlotIndex, Row, Col) lus par DragDrop pour nommer la cible.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types.Duel)
local Theme = require(script.Parent.Theme)

export type BoardPanel = {
	frame: Frame,
	benchSlots: { Frame },
	boardCells: { [number]: Frame }, -- cle = (row - 1) * colonnes + col
	sellZone: Frame,
	capacityLabel: TextLabel,
	render: (self: BoardPanel, me: Types.OwnSeatView, selectedId: string?) -> (),
	cellKey: (row: number, col: number) -> number,
}

local BoardPanel = {}
BoardPanel.__index = BoardPanel

local CELL_PX = 52
local GAP_PX = 4

function BoardPanel.cellKey(row: number, col: number): number
	return (row - 1) * Config.Combat.boardColumns + col
end

local function clearUnits(slot: Frame)
	for _, child in slot:GetChildren() do
		if child.Name == "Unit" then
			child:Destroy()
		end
	end
end

function BoardPanel.new(parent: Instance): BoardPanel
	local frame = Theme.panel("ui_board_panel", parent)
	Theme.listLayout(frame, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center)

	local rows, columns = Config.Combat.boardRows, Config.Combat.boardColumns
	local board = Theme.frame("Board", frame, Theme.colors.ink, 1)
	board.Size = UDim2.fromOffset(columns * (CELL_PX + GAP_PX), rows * (CELL_PX + GAP_PX))
	board.LayoutOrder = 1
	Theme.gridLayout(board, CELL_PX, GAP_PX)
	local boardCells: { [number]: Frame } = {}
	-- Ligne 2 (arriere) affichee en haut, ligne 1 (avant, cote adversaire) en bas : vue de dessus depuis le banc.
	for row = rows, 1, -1 do
		for col = 1, columns do
			local cell = Theme.frame(`ui_board_cell_{row}_{col}`, board, Theme.colors.night)
			cell.LayoutOrder = (rows - row) * columns + col
			cell.Active = true
			cell:SetAttribute("SlotKind", "board")
			cell:SetAttribute("Row", row)
			cell:SetAttribute("Col", col)
			Theme.corner(cell, 6)
			local hint = Theme.label("Hint", cell, if row == 1 then "avant" else "arriere", 9)
			hint.Size = UDim2.fromScale(1, 1)
			hint.TextColor3 = Theme.colors.steel
			boardCells[BoardPanel.cellKey(row, col)] = cell
		end
	end

	local capacityLabel = Theme.label("ui_board_capacity", frame, "", 11)
	capacityLabel.Size = UDim2.fromOffset(200, 14)
	capacityLabel.LayoutOrder = 2
	capacityLabel.TextColor3 = Theme.colors.gold

	local benchRow = Theme.frame("BenchRow", frame, Theme.colors.ink, 1)
	benchRow.Size = UDim2.fromOffset((Config.Duel.benchSize + 1) * (CELL_PX + GAP_PX) + 40, CELL_PX)
	benchRow.LayoutOrder = 3
	Theme.listLayout(
		benchRow,
		Enum.FillDirection.Horizontal,
		GAP_PX,
		Enum.HorizontalAlignment.Center
	)

	local benchSlots: { Frame } = {}
	for index = 1, Config.Duel.benchSize do
		local slot = Theme.frame(`ui_bench_slot_{index}`, benchRow, Theme.colors.steel, 0.5)
		slot.Size = UDim2.fromOffset(CELL_PX, CELL_PX)
		slot.LayoutOrder = index
		slot.Active = true
		slot:SetAttribute("SlotKind", "bench")
		slot:SetAttribute("SlotIndex", index)
		Theme.corner(slot, 6)
		benchSlots[index] = slot
	end

	local sellZone = Theme.frame("ui_sell_zone", benchRow, Theme.colors.red, 0.35)
	sellZone.Size = UDim2.fromOffset(CELL_PX + 36, CELL_PX)
	sellZone.LayoutOrder = Config.Duel.benchSize + 1
	sellZone.Active = true
	sellZone:SetAttribute("SlotKind", "sell")
	Theme.corner(sellZone, 6)
	local sellLabel = Theme.label("Label", sellZone, "VENDRE\n(glisser ici)", 11)
	sellLabel.Size = UDim2.fromScale(1, 1)
	sellLabel.Font = Theme.FONT

	local self = setmetatable({
		frame = frame,
		benchSlots = benchSlots,
		boardCells = boardCells,
		sellZone = sellZone,
		capacityLabel = capacityLabel,
	}, BoardPanel)
	return (self :: any) :: BoardPanel
end

local function placeTile(slot: Frame, unit: Types.OwnedUnit, selected: boolean)
	local tile = Theme.unitTile(slot, unit.instanceId, unit.slug, unit.stars)
	tile:SetAttribute("Tactic", unit.tactic)
	if selected then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.colors.gold
		stroke.Thickness = 3
		stroke.Parent = tile
	end
end

-- Redessine banc et plateau depuis la vue serveur. Tout etat local (tuile deplacee en optimiste) est ecrase ici.
function BoardPanel.render(self: BoardPanel, me: Types.OwnSeatView, selectedId: string?)
	for _, slot in self.benchSlots do
		clearUnits(slot)
	end
	for _, cell in self.boardCells do
		clearUnits(cell)
	end
	for index, unit in me.bench do
		local slot = self.benchSlots[index]
		if slot then
			placeTile(slot, unit, unit.instanceId == selectedId)
		end
	end
	for _, unit in me.board do
		local cell = self.boardCells[BoardPanel.cellKey(unit.row, unit.col)]
		if cell then
			placeTile(cell, unit, unit.instanceId == selectedId)
		end
	end
	-- Niveau = nombre max d'unites sur le plateau (D-M1-07) : rappel affiche, le serveur refuse au-dela.
	self.capacityLabel.Text = `Plateau {#me.board} / {me.level} (niveau {me.level})`
end

return BoardPanel
