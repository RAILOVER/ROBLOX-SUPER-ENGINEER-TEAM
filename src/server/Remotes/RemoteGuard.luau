--!strict
-- Garde-fou standard pour tout RemoteEvent / RemoteFunction (voir agents/04-dev-serveur/ROLE.md).
-- 1. valide le type et les bornes de chaque argument, 2. applique un cooldown par joueur,
-- 3. compte les requetes suspectes sans jamais punir un seul paquet malforme.

local RemoteGuard = {}

type Validator = (value: unknown) -> boolean

local lastCall: { [Player]: { [string]: number } } = {}
local strikes: { [Player]: number } = {}

local STRIKE_THRESHOLD = 20

local function isFiniteNumber(value: unknown): boolean
	return typeof(value) == "number" and value == value and math.abs(value) ~= math.huge
end

function RemoteGuard.integerBetween(min: number, max: number): Validator
	return function(value: unknown): boolean
		return isFiniteNumber(value)
			and (value :: number) % 1 == 0
			and (value :: number) >= min
			and (value :: number) <= max
	end
end

function RemoteGuard.stringMax(maxLength: number): Validator
	return function(value: unknown): boolean
		if typeof(value) ~= "string" then
			return false
		end
		local length = utf8.len(value :: string)
		return length ~= nil and length <= maxLength
	end
end

function RemoteGuard.oneOf(allowed: { string }): Validator
	local set: { [string]: boolean } = {}
	for _, key in allowed do
		set[key] = true
	end
	return function(value: unknown): boolean
		return typeof(value) == "string" and set[value :: string] == true
	end
end

function RemoteGuard.cooldown(player: Player, key: string, seconds: number): boolean
	local now = os.clock()
	local calls = lastCall[player]
	if calls == nil then
		calls = {}
		lastCall[player] = calls
	end
	local previous = calls[key]
	if previous ~= nil and now - previous < seconds then
		return false
	end
	calls[key] = now
	return true
end

function RemoteGuard.strike(player: Player, reason: string): ()
	strikes[player] = (strikes[player] or 0) + 1
	if strikes[player] == STRIKE_THRESHOLD then
		warn(
			string.format(
				"[RemoteGuard] %d a atteint %d requetes invalides, derniere: %s",
				player.UserId,
				STRIKE_THRESHOLD,
				reason
			)
		)
	end
end

function RemoteGuard.forget(player: Player): ()
	lastCall[player] = nil
	strikes[player] = nil
end

-- Verifie une liste d'arguments contre une liste de validateurs. Retourne false au premier echec.
function RemoteGuard.check(
	player: Player,
	args: { unknown },
	validators: { Validator },
	label: string
): boolean
	for index, validator in validators do
		if not validator(args[index]) then
			RemoteGuard.strike(player, label .. " arg" .. tostring(index))
			return false
		end
	end
	return true
end

return RemoteGuard
