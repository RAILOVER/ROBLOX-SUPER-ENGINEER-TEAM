--!strict
-- Lecteur du plan de combat (T-0012) : 1 Part par unite (couleur de famille, taille selon etoiles), posee sur les
-- cases de Arena01 (ArenaGeometry.cellTop), BillboardGui PV + nom, deplacement court de l'attaquant vers sa cible,
-- nombres flottants (rouge degats, vert soins, jaune critique), disparition au K.O., bandeau "MEGA COMBO",
-- puis resultat de manche. Tout vient du journal : le client ne calcule ni degats ni PV. Les PV max affiches
-- sont deduits du journal (PV apres + degats du 1er coup recu) tant que le serveur ne les envoie pas (T-0032).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types.Duel)
local PlaybackPlan = require(ReplicatedStorage.Shared.Duel.PlaybackPlan)
local ArenaGeometry = require(ReplicatedStorage.Shared.World.ArenaGeometry)
local Theme = require(script.Parent.Parent.UI.Theme)
local Banner = require(script.Parent.Parent.UI.Banner)

local CombatPlayback = {}

type StepHook = (plan: PlaybackPlan.Plan, index: number) -> ()
type Puppet = { part: Part, fill: Frame, hpLabel: TextLabel, hpMax: number?, alive: boolean }

local ARENA = Config.Arenas.byId["arena-01"]
local BASE_SIZE = 2.4
local STAR_SIZE = 0.6
local FLOAT_RISE = 4
local RESULT_SECONDS = 3

local folder: Folder? = nil
local bannerGui: ScreenGui? = nil
local banner: Banner.Banner? = nil
local puppets: { [string]: Puppet } = {}
local generation = 0
local stepHook: StepHook? = nil
local lastMegaGauge = 0

local function toVector3(v: ArenaGeometry.Vec): Vector3
	return Vector3.new(v.x, v.y, v.z)
end

local function cellOf(unit: Types.UnitInstance): number
	return (unit.row - 1) * Config.Combat.boardColumns + (unit.col - 1)
end

local function ensureFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "DuelPlayback"
	f.Parent = Workspace
	folder = f
	return f
end

local function ensureBanner(): Banner.Banner
	if banner and bannerGui and bannerGui.Parent then
		return banner
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "DuelPlaybackBanner"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.DisplayOrder = 20
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
	bannerGui = gui
	banner = Banner.new(gui)
	return banner :: Banner.Banner
end

local function billboard(part: Part, slug: string, stars: number): (Frame, TextLabel)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Status"
	gui.Size = UDim2.fromOffset(90, 34)
	gui.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + 1.5, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part
	local name = Theme.label("Name", gui, `{Theme.unitName(slug)} {Theme.stars(stars)}`, 12)
	name.Size = UDim2.new(1, 0, 0, 16)
	name.TextStrokeTransparency = 0.5
	local bar = Theme.frame("HpBar", gui, Theme.colors.ink)
	bar.Size = UDim2.new(1, 0, 0, 10)
	bar.Position = UDim2.fromOffset(0, 20)
	local fill = Theme.frame("Fill", bar, Theme.colors.green)
	fill.Size = UDim2.fromScale(1, 1)
	local hpLabel = Theme.label("Hp", bar, "", 9)
	hpLabel.Size = UDim2.fromScale(1, 1)
	hpLabel.ZIndex = 2
	return fill, hpLabel
end

local function spawnTeam(side: Types.Side, units: { Types.UnitInstance })
	local parent = ensureFolder()
	for _, unit in units do
		local stars = unit.stars or 1
		local size = BASE_SIZE + STAR_SIZE * (stars - 1)
		local part = Instance.new("Part")
		local cell = `{side}{cellOf(unit)}`
		part.Name = cell
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Theme.familyColor(unit.slug)
		part.Size = Vector3.new(size, size * 1.4, size)
		local top = toVector3(ArenaGeometry.cellTop(ARENA, side, unit.row, unit.col))
		part.CFrame = CFrame.new(top + Vector3.new(0, part.Size.Y / 2, 0))
		part.Parent = parent
		local fill, hpLabel = billboard(part, unit.slug, stars)
		puppets[cell] = { part = part, fill = fill, hpLabel = hpLabel, hpMax = nil, alive = true }
	end
end

local function floatText(at: Vector3, text: string, color: Color3, seconds: number)
	local parent = ensureFolder()
	local anchor = Instance.new("Part")
	anchor.Name = "FloatAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = parent
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(80, 30)
	gui.AlwaysOnTop = true
	gui.Parent = anchor
	local label = Theme.label("Value", gui, text, 20)
	label.Size = UDim2.fromScale(1, 1)
	label.TextColor3 = color
	label.Font = Theme.FONT
	label.TextStrokeTransparency = 0.4
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(anchor, info, { CFrame = CFrame.new(at + Vector3.new(0, FLOAT_RISE, 0)) })
		:Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	task.delay(seconds, function()
		anchor:Destroy()
	end)
end

local function setHp(puppet: Puppet, hp: number, dealt: number)
	if puppet.hpMax == nil then
		puppet.hpMax = math.max(hp + math.max(dealt, 0), hp, 1)
	end
	local hpMax = puppet.hpMax :: number
	puppet.hpMax = math.max(hpMax, hp)
	local ratio = math.clamp(hp / (puppet.hpMax :: number), 0, 1)
	puppet.fill.Size = UDim2.fromScale(ratio, 1)
	puppet.fill.BackgroundColor3 = if ratio > 0.5
		then Theme.colors.green
		elseif ratio > 0.25 then Theme.colors.gold
		else Theme.colors.red
	puppet.hpLabel.Text = tostring(hp)
end

local function lunge(actor: Puppet, target: Puppet?, seconds: number)
	if target == nil or seconds <= 0 then
		return
	end
	local home = actor.part.CFrame
	local toward = home.Position:Lerp(target.part.Position, 0.35)
	local half = TweenInfo.new(seconds / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local out = TweenService:Create(actor.part, half, { CFrame = CFrame.new(toward) })
	out:Play()
	task.delay(seconds / 2, function()
		TweenService:Create(actor.part, half, { CFrame = home }):Play()
	end)
end

local function playStep(step: PlaybackPlan.Step, mySide: string)
	local actor = puppets[step.actorCell]
	lastMegaGauge = step.gauges.mega
	if step.kind == "Mega" then
		ensureBanner():show(
			`MEGA COMBO {step.combo or ""}`,
			Theme.colors.purple,
			step.durationSeconds
		)
	end
	if actor then
		lunge(actor, puppets[step.targetCells[1]], math.min(step.durationSeconds, 0.6))
	end
	for index, cell in step.targetCells do
		local target = puppets[cell]
		local value = step.values[index] or 0
		if target then
			local color = if value < 0
				then Theme.colors.green
				elseif step.crits[index] then Theme.colors.gold
				else Theme.colors.red
			local text = if value < 0
				then `+{-value}`
				elseif value > 0 then `-{value}`
				else step.kind
			if step.crits[index] and value > 0 then
				text ..= " CRIT"
			end
			floatText(
				target.part.Position + Vector3.new(0, target.part.Size.Y / 2, 0),
				text,
				color,
				0.9
			)
		end
	end
	for _, status in step.statuses.applied do
		local target = puppets[step.targetCells[1] or step.actorCell]
		if target then
			floatText(target.part.Position + Vector3.new(0, 1, 0), status, Theme.colors.purple, 0.9)
		end
	end
	for cell, hp in step.hpAfter do
		local puppet = puppets[cell]
		if puppet then
			local index = table.find(step.targetCells, cell)
			setHp(puppet, hp, if index then (step.values[index] or 0) else 0)
		end
	end
	for _, cell in step.kos do
		local puppet = puppets[cell]
		if puppet and puppet.alive then
			puppet.alive = false
			local info = TweenInfo.new(0.4)
			TweenService
				:Create(puppet.part, info, { Transparency = 1, Size = puppet.part.Size * 0.3 })
				:Play()
			local gui = puppet.part:FindFirstChild("Status")
			if gui then
				gui:Destroy()
			end
			floatText(
				puppet.part.Position,
				if string.sub(cell, 1, 1) == mySide then "K.O." else "K.O. !",
				Theme.colors.cream,
				1
			)
		end
	end
end

local function showResult(payload: Types.CombatLogPayload)
	local winner = payload.result.winner
	local text = if winner == "draw"
		then "MANCHE NULLE"
		elseif winner == payload.side then "MANCHE GAGNEE"
		else "MANCHE PERDUE"
	local mine = payload.playerDamage[if payload.side == "A" then 1 else 2] or 0
	local theirs = payload.playerDamage[if payload.side == "A" then 2 else 1] or 0
	local color = if winner == "draw"
		then Theme.colors.gold
		elseif winner == payload.side then Theme.colors.green
		else Theme.colors.red
	ensureBanner():show(
		`{text}\ndegats joueur : vous {mine}, adversaire {theirs}`,
		color,
		RESULT_SECONDS
	)
end

function CombatPlayback.start()
	ensureFolder()
end

function CombatPlayback.setStepHook(hook: StepHook?)
	stepHook = hook
end

function CombatPlayback.lastMegaGauge(): number
	return lastMegaGauge
end

-- Retire les Parts du combat precedent (appele au retour en Preparation).
function CombatPlayback.clear()
	generation += 1
	for _, puppet in puppets do
		puppet.part:Destroy()
	end
	table.clear(puppets)
	if folder then
		folder:ClearAllChildren()
	end
	lastMegaGauge = 0
end

-- Construit le plan et le joue en arriere-plan ; retourne le plan pour la timeline du HUD.
function CombatPlayback.play(payload: Types.CombatLogPayload): PlaybackPlan.Plan
	CombatPlayback.clear()
	local plan = PlaybackPlan.build(Config, payload)
	spawnTeam("A", payload.teams.A)
	spawnTeam("B", payload.teams.B)
	generation += 1
	local myGeneration = generation
	task.spawn(function()
		for index, step in plan do
			if generation ~= myGeneration then
				return
			end
			if stepHook then
				stepHook(plan, index)
			end
			playStep(step, payload.side)
			task.wait(step.durationSeconds)
		end
		if generation == myGeneration then
			showResult(payload)
		end
	end)
	return plan
end

function CombatPlayback.isPlaying(): boolean
	return next(puppets) ~= nil
end

return CombatPlayback
