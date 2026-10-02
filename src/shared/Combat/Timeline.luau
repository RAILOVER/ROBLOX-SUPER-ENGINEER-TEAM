--!strict
-- Timeline et initiative (R-M1-04 a R-M1-09). Chaque unite avance de sa VIT effective par tick et agit a
-- timelineThreshold. La prevision (R-M1-09) rejoue les ticks sur une copie sans effet de bord.

local Types = require(script.Parent.Parent.Types.Combat)
local Formulas = require(script.Parent.Formulas)
local Status = require(script.Parent.Status)

type State = Types.State
type Unit = Types.Unit
type Side = Types.Side
type PreviewEntry = Types.PreviewEntry

local Timeline = {}

local MAX_TICKS_WITHOUT_ACTION = 100000

-- Ordre fixe de tirage et de depart : equipe A cases 0 a 7 puis equipe B (R-M1-04).
function Timeline.orderedUnits(state: State): { Unit }
	local units = table.clone(state.units)
	table.sort(units, function(a: Unit, b: Unit): boolean
		if a.side ~= b.side then
			return a.side == "A"
		end
		return a.cell < b.cell
	end)
	return units
end

function Timeline.init(state: State)
	local combat = state.config.Combat
	for _, unit in Timeline.orderedUnits(state) do
		unit.timeline = state.rng:NextInteger(0, combat.timelineStartRandomMax)
			+ combat.timelineStartVitMult * unit.stats.VIT
	end
end

function Timeline.effectiveVit(state: State, unit: Unit): number
	return Formulas.effectiveVit(unit.stats.VIT, Status.vitMultipliers(state.config, unit))
end

function Timeline.canAdvance(unit: Unit): boolean
	return unit.alive and not Status.has(unit, "HorsCombat")
end

-- R-M1-05 : un tick.
function Timeline.tick(state: State)
	state.ticks += 1
	for _, unit in state.units do
		if Timeline.canAdvance(unit) then
			unit.timeline += Timeline.effectiveVit(state, unit)
		end
	end
end

-- R-M1-06 : VIT la plus haute, puis le camp qui n'a pas agi en dernier, puis la case la plus basse.
local function before(state: State, a: Unit, b: Unit, lastSide: Side?): boolean
	local vitA, vitB = Timeline.effectiveVit(state, a), Timeline.effectiveVit(state, b)
	if vitA ~= vitB then
		return vitA > vitB
	end
	if a.side ~= b.side then
		local preferred: Side = if lastSide == "A" then "B" else "A"
		return a.side == preferred
	end
	return a.cell < b.cell
end

function Timeline.pick(state: State, ready: { Unit }, lastSide: Side?): Unit?
	local best: Unit? = nil
	for _, unit in ready do
		if best == nil or before(state, unit, best, lastSide) then
			best = unit
		end
	end
	return best
end

local function readyUnits(state: State, timelines: { [number]: number }): { Unit }
	local ready: { Unit } = {}
	local threshold = state.config.Combat.timelineThreshold
	for _, unit in state.units do
		if Timeline.canAdvance(unit) and timelines[unit.id] >= threshold then
			table.insert(ready, unit)
		end
	end
	return ready
end

local function liveTimelines(state: State): { [number]: number }
	local map: { [number]: number } = {}
	for _, unit in state.units do
		map[unit.id] = unit.timeline
	end
	return map
end

-- Tick jusqu'a ce qu'une unite atteigne le seuil, puis retourne celle qui agit.
function Timeline.nextActor(state: State): Unit
	for _ = 1, MAX_TICKS_WITHOUT_ACTION do
		local ready = readyUnits(state, liveTimelines(state))
		local actor = Timeline.pick(state, ready, state.lastActedSide)
		if actor then
			return actor
		end
		Timeline.tick(state)
	end
	error("Timeline.nextActor : aucune unite ne peut agir")
end

-- R-M1-07 : remise a 0, ou a 30 % du seuil apres une Garde.
function Timeline.afterAction(state: State, unit: Unit, guarded: boolean)
	local combat = state.config.Combat
	unit.timeline = if guarded
		then math.floor(combat.guardTimelineAdvance * combat.timelineThreshold)
		else 0
	state.lastActedSide = unit.side
end

-- R-M1-09 : les n prochains acteurs, sans effet de bord (VIT et statuts supposes constants).
function Timeline.preview(state: State, n: number): { PreviewEntry }
	local timelines = liveTimelines(state)
	local lastSide: Side? = state.lastActedSide
	local out: { PreviewEntry } = {}
	local ticks = 0
	while #out < n and ticks < MAX_TICKS_WITHOUT_ACTION do
		local actor = Timeline.pick(state, readyUnits(state, timelines), lastSide)
		if actor then
			table.insert(out, { side = actor.side, cell = actor.cell, slug = actor.slug })
			timelines[actor.id] = 0
			lastSide = actor.side
		else
			ticks += 1
			for _, unit in state.units do
				if Timeline.canAdvance(unit) then
					timelines[unit.id] += Timeline.effectiveVit(state, unit)
				end
			end
		end
	end
	return out
end

return Timeline
