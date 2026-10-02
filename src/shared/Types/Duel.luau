--!strict
-- Types du duel TFT (spec design/specs/M1-duel-minimal.md, T-0011). Contrat partage serveur / client (T-0012).
-- Module pur : aucune donnee mutable, aucun type Roblox. Les payloads des remotes sont decrits en section 3.

local Combat = require(script.Parent.Combat)

export type Tactic = Combat.Tactic
export type Side = Combat.Side
export type CombatResult = Combat.CombatResult
export type UnitInstance = Combat.UnitInstance

-- 1. Etat serveur -------------------------------------------------------------------------------------------

export type Phase = "Lobby" | "Preparation" | "Combat" | "Resultat" | "Fin"
export type SeatKind = "human" | "bot" | "ghost"
export type RoundOutcome = "win" | "loss" | "draw"

-- Une unite possedee par un siege. row / col = 0 quand elle est sur le banc.
export type OwnedUnit = {
	instanceId: string,
	slug: string,
	stars: number,
	tactic: Tactic,
	row: number,
	col: number,
}

export type ShopSlot = { slug: string, cost: number, sold: boolean }

export type Seat = {
	seatIndex: number,
	kind: SeatKind,
	userId: number,
	displayName: string,
	hp: number,
	gold: number,
	level: number,
	xp: number,
	streak: number,
	lastOutcome: RoundOutcome?,
	ready: boolean,
	bench: { OwnedUnit },
	board: { OwnedUnit },
	shop: { ShopSlot },
	pool: { [string]: number },
	rng: Combat.Rng, -- tirages de la boutique de ce siege (serveur uniquement)
	nextUnitId: number,
	roundsWon: number,
	invalidRequests: number,
}

export type CombatRecord = {
	seatIndex: number, -- siege qui lit ce journal (PvE : 1 journal par siege, PvP : le meme pour les 2)
	side: Side, -- camp de ce siege dans le journal
	teams: { A: { UnitInstance }, B: { UnitInstance } },
	result: CombatResult,
	damage: { number }, -- degats au joueur par siege (index 1 et 2) decides par ce combat
	outcome: RoundOutcome, -- resultat du point de vue de `seatIndex`
}

export type State = {
	seed: number,
	phase: Phase,
	round: number,
	timerSeconds: number,
	seats: { Seat },
	deck: { string },
	combats: { CombatRecord },
	hpBeforeRound: { number },
	winnerSeat: number?, -- nil en cours de duel ou nul
	endReason: ("hp" | "forfeit" | "draw")?,
	combatSeed: number,
}

-- 2. Vue client (DuelState.toClientView) ---------------------------------------------------------------------

export type SeatView = {
	seatIndex: number,
	kind: SeatKind,
	displayName: string,
	hp: number,
	level: number,
	streak: number,
	ready: boolean,
	boardCount: number,
}

export type OwnSeatView = SeatView & {
	gold: number,
	xp: number,
	xpToNext: number,
	nextIncome: number,
	bench: { OwnedUnit },
	board: { OwnedUnit },
	shop: { ShopSlot },
}

export type OpponentSeatView = SeatView & {
	board: { OwnedUnit }, -- vide avant la phase Combat (D-M1-11)
}

export type ClientView = {
	phase: Phase,
	round: number,
	isPve: boolean,
	timerSeconds: number,
	seatIndex: number,
	me: OwnSeatView,
	opponent: OpponentSeatView,
	lastOutcome: RoundOutcome?,
}

-- 3. Payloads des remotes (voir src/shared/Remotes/DuelRemotes.luau) ----------------------------------------

-- serveur -> client "CombatLog"
export type CombatLogPayload = {
	round: number,
	isPve: boolean,
	side: Side,
	teams: { A: { UnitInstance }, B: { UnitInstance } },
	result: CombatResult,
	playerDamage: { number }, -- index 1 = siege 1, index 2 = siege 2
}

-- serveur -> client "DuelEnded"
export type DuelEndedPayload = {
	rounds: number,
	winnerSeat: number?,
	youWon: boolean,
	hp: { number },
	reason: "hp" | "forfeit" | "draw",
}

export type ActionResult = { ok: boolean, reason: string? }

return {}
