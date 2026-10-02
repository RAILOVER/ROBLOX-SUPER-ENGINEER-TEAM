--!strict
-- Types du combat au tour par tour (spec design/specs/M1-combat-tour-par-tour.md, T-0010).
-- Module pur : aucune donnee mutable, aucun type Roblox. La config est injectee dans CombatSim.simulate.

export type CombatConfig = typeof(require(script.Parent.Parent.Config))
export type Side = "A" | "B"
export type Winner = "A" | "B" | "draw"
export type Tactic = "Agressif" | "Equilibre" | "Prudent"
export type ActionKind = "Attack" | "Skill" | "Guard" | "Duo" | "Mega" | "Skip"
export type StatName = "HP" | "ATQ" | "MAG" | "DEF" | "RES" | "VIT"

-- Entree de simulate : une unite posee sur le plateau. row 1 = ligne avant, row 2 = ligne arriere, col 1 a 4.
export type UnitInstance = {
	slug: string,
	stars: number?,
	row: number,
	col: number,
	tactic: Tactic?,
}

export type SkillTarget = "enemy" | "enemyBackline" | "enemies" | "self" | "allyLowestHp" | "allies"
export type SkillDef = {
	skillId: string,
	cost: number,
	power: number,
	effectId: string,
	params: { [string]: number },
	target: SkillTarget,
}

export type StatusDef = {
	kind: string,
	turns: number?,
	breaksOnDamage: boolean?,
	bossImmune: boolean?,
	VIT: number?,
	hpMaxPerTurn: number?,
	maxStacks: number?,
	damageTaken: number?,
}

export type StatusInstance = {
	name: string,
	kind: string,
	turns: number?,
	stacks: number,
	shield: number,
	thornsPct: number,
	appliedAt: number,
}

export type Stats = { HP: number, ATQ: number, MAG: number, DEF: number, RES: number, VIT: number }

export type Unit = {
	id: number,
	slug: string,
	side: Side,
	cell: number,
	row: number,
	col: number,
	class: string,
	range: string,
	stars: number,
	tactic: Tactic,
	stats: Stats,
	hpMax: number,
	hp: number,
	energy: number,
	timeline: number,
	skillCost: number,
	critChance: number,
	critMultiplier: number,
	statuses: { StatusInstance },
	guarding: boolean,
	alive: boolean,
	controlImmunity: number,
	damageDealt: number,
	healingDone: number,
	skill: SkillDef,
	duoPartners: { string },
	synergyMember: boolean,
	isBoss: boolean,
}

export type EffectRef = {
	source: string,
	effectId: string,
	params: { [string]: number },
	members: { [number]: boolean },
}

export type TeamState = {
	side: Side,
	units: { Unit },
	mega: number,
	megaUsed: { [string]: number },
	activeSynergies: { [string]: number },
	effects: { EffectRef },
	focusCell: number?,
	focusTurnsLeft: number,
	focusOrdersUsed: number,
	damageFromEnemy: { [number]: number },
	roundActed: { [number]: boolean },
	rounds: number,
}

export type ActionEntry = {
	t: number,
	actor: string,
	action: ActionKind,
	skillId: string?,
	combo: string?,
	partner: string?,
	targets: { string },
	values: { number },
	crits: { boolean },
	statuses: { applied: { string }, removed: { string } },
	ticks: { string },
	gauges: { energy: number, mega: number },
	hp: { [string]: number },
	kos: { string },
}

export type Rng = {
	NextInteger: (self: Rng, min: number, max: number) -> number,
	NextNumber: (self: Rng, min: number?, max: number?) -> number,
	Clone: (self: Rng) -> Rng,
}

export type Options = { autoMega: boolean?, tentafruitEnabled: boolean? }

export type State = {
	seed: number,
	config: CombatConfig,
	options: Options,
	rng: Rng,
	teams: { A: TeamState, B: TeamState },
	units: { Unit },
	actions: number,
	ticks: number,
	lastActedSide: Side?,
	log: { ActionEntry },
	currentEntry: ActionEntry?,
	hitThisAction: { [number]: boolean },
	winner: Winner?,
	unimplemented: { string },
}

export type PreviewEntry = { side: Side, cell: number, slug: string }

export type CombatResult = {
	winner: Winner,
	turns: number,
	actions: number,
	actionLog: { ActionEntry },
	version: number,
	mvp: string?,
	unimplemented: { string },
}

return {}
