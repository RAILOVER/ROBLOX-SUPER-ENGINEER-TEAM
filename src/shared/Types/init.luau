--!strict
-- Types partages client/serveur. Aucune donnee mutable ici: ce module est replique et lisible par le client.

export type Currency = "Coins" | "Gems"

export type PlayerProfile = {
	version: number,
	coins: number,
	gems: number,
	inventory: { [string]: number },
	firstJoinedAt: number,
	lastSeenAt: number,
}

export type RemoteResult<T> = { ok: true, value: T } | { ok: false, reason: string }

return {}
