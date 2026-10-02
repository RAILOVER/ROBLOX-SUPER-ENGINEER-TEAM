--!strict
-- Plan de lecture d'un combat (T-0012) : transforme le journal d'actions (CombatLogPayload.result.actionLog,
-- docs/architecture/combat.md section 3) en etapes d'animation datees. Module pur (aucun service Roblox, config
-- injectee) : teste sous Lune par tests/unit/PlaybackPlan.spec.luau. Le client ne calcule rien : les PV, degats,
-- K.O. et jauges sont recopies du journal ; seul le minutage est decide ici.
--
-- Minutage (M-C-04, cible 20 a 35 s par combat alors que les combats M1 font 51,9 actions en moyenne) :
--   1. duree de base par type d'action (BASE_SECONDS), bornee par Config.Combat.pvpActionAnimationMaxSeconds
--      (0,8 s) ; un Mega Combo dure MEGA_SECONDS (2,5 s) quoi qu'il arrive ;
--   2. une action repetitive (meme type que l'etape precedente, sans critique, sans K.O., sans statut pose) est
--      lue a REPEAT_FACTOR de sa duree de base ;
--   3. a partir de l'action `suddenDeathAfterActions` + 1 (mort subite, 41 et plus), toutes les actions hors Mega
--      sont lues a SUDDEN_DEATH_FACTOR ;
--   4. plancher MIN_SECONDS pour que chaque etape reste perceptible.

local Types = require(script.Parent.Parent.Types.Combat)
local DuelTypes = require(script.Parent.Parent.Types.Duel)

type ActionEntry = Types.ActionEntry
type ActionKind = Types.ActionKind
type CombatConfig = Types.CombatConfig
type CombatLogPayload = DuelTypes.CombatLogPayload

export type Step = {
	t: number,
	kind: ActionKind,
	actor: string, -- "slug.A1"
	actorCell: string, -- "A1"
	actorSlug: string,
	targetCells: { string },
	values: { number }, -- > 0 degats, < 0 soins, 0 buff
	crits: { boolean },
	statuses: { applied: { string }, removed: { string } },
	ticks: { string },
	hpAfter: { [string]: number },
	kos: { string },
	gauges: { energy: number, mega: number },
	skillId: string?,
	combo: string?,
	partner: string?,
	startSeconds: number,
	durationSeconds: number,
}

export type Plan = { Step }

local PlaybackPlan = {}

PlaybackPlan.MEGA_SECONDS = 2.5
PlaybackPlan.MIN_SECONDS = 0.15
PlaybackPlan.REPEAT_FACTOR = 0.7
PlaybackPlan.SUDDEN_DEATH_FACTOR = 0.5
PlaybackPlan.BASE_SECONDS = table.freeze({
	Attack = 0.6,
	Skill = 0.8,
	Duo = 0.8,
	Guard = 0.35,
	Skip = 0.2,
	Mega = 2.5,
} :: { [string]: number })

-- "banano.A3" -> "banano", "A3"
function PlaybackPlan.splitActor(actor: string): (string, string)
	local slug, cell = string.match(actor, "^(.-)%.([AB]%d)$")
	if slug == nil or cell == nil then
		return actor, ""
	end
	return slug, cell
end

local function isRepetitive(entry: ActionEntry, previous: Step?): boolean
	if previous == nil or previous.kind ~= entry.action then
		return false
	end
	if #entry.kos > 0 or #entry.statuses.applied > 0 then
		return false
	end
	for _, crit in entry.crits do
		if crit then
			return false
		end
	end
	return true
end

function PlaybackPlan.durationFor(config: CombatConfig, entry: ActionEntry, previous: Step?): number
	if entry.action == "Mega" then
		return PlaybackPlan.MEGA_SECONDS
	end
	local maxSeconds = config.Combat.pvpActionAnimationMaxSeconds
	local seconds = math.min(PlaybackPlan.BASE_SECONDS[entry.action] or maxSeconds, maxSeconds)
	if isRepetitive(entry, previous) then
		seconds *= PlaybackPlan.REPEAT_FACTOR
	end
	if entry.t > config.Combat.suddenDeathAfterActions then
		seconds *= PlaybackPlan.SUDDEN_DEATH_FACTOR
	end
	return math.max(PlaybackPlan.MIN_SECONDS, seconds)
end

function PlaybackPlan.fromLog(config: CombatConfig, log: { ActionEntry }): Plan
	local plan: Plan = {}
	local clock = 0
	local previous: Step? = nil
	for _, entry in log do
		local slug, cell = PlaybackPlan.splitActor(entry.actor)
		local duration = PlaybackPlan.durationFor(config, entry, previous)
		local step: Step = {
			t = entry.t,
			kind = entry.action,
			actor = entry.actor,
			actorCell = cell,
			actorSlug = slug,
			targetCells = table.clone(entry.targets),
			values = table.clone(entry.values),
			crits = table.clone(entry.crits),
			statuses = {
				applied = table.clone(entry.statuses.applied),
				removed = table.clone(entry.statuses.removed),
			},
			ticks = table.clone(entry.ticks),
			hpAfter = table.clone(entry.hp),
			kos = table.clone(entry.kos),
			gauges = { energy = entry.gauges.energy, mega = entry.gauges.mega },
			skillId = entry.skillId,
			combo = entry.combo,
			partner = entry.partner,
			startSeconds = clock,
			durationSeconds = duration,
		}
		table.insert(plan, step)
		clock += duration
		previous = step
	end
	return plan
end

function PlaybackPlan.build(config: CombatConfig, payload: CombatLogPayload): Plan
	return PlaybackPlan.fromLog(config, payload.result.actionLog)
end

function PlaybackPlan.totalSeconds(plan: Plan): number
	local total = 0
	for _, step in plan do
		total += step.durationSeconds
	end
	return total
end

-- Derniers PV connus par case, dans l'ordre du plan (la derniere etape qui cite une case fait foi).
function PlaybackPlan.finalHp(plan: Plan): { [string]: number }
	local hp: { [string]: number } = {}
	for _, step in plan do
		for cell, value in step.hpAfter do
			hp[cell] = value
		end
	end
	return hp
end

-- Les `count` prochains acteurs a partir de l'etape `fromIndex` (timeline des 10 prochaines actions, brief 11.2).
function PlaybackPlan.upcoming(plan: Plan, fromIndex: number, count: number): { Step }
	local out: { Step } = {}
	for index = fromIndex, math.min(#plan, fromIndex + count - 1) do
		table.insert(out, plan[index])
	end
	return out
end

-- Indice de l'etape en cours a l'instant `seconds` (1 au debut, #plan + 1 une fois le plan termine).
function PlaybackPlan.indexAt(plan: Plan, seconds: number): number
	for index, step in plan do
		if seconds < step.startSeconds + step.durationSeconds then
			return index
		end
	end
	return #plan + 1
end

return table.freeze(PlaybackPlan)
