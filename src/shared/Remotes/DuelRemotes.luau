--!strict
-- Contrat des remotes du duel (T-0011) : noms, sens, schema des arguments, phase autorisee et cooldown.
-- Seul endroit ou ces noms existent : le serveur (DuelService) cree les RemoteEvent a partir de cette table et le
-- client (T-0012) les retrouve sous ReplicatedStorage[DuelRemotes.FOLDER]. Les payloads serveur -> client sont types
-- dans src/shared/Types/Duel.luau (ClientView, CombatLogPayload, DuelEndedPayload).
-- Le client n'envoie que des intentions (index, identifiant, case, tactique) : jamais d'or, de degats, de resultat.

export type ArgSchema =
	{ kind: "integer", min: number, max: number }
	| { kind: "string", max: number, pattern: string?, optional: boolean? }
	| { kind: "oneOf", values: { string } }

export type ClientRemote = {
	args: { ArgSchema },
	phase: string?, -- phase du duel exigee ("Preparation", "Combat") ; nil = pas de contrainte de phase
	needsSeat: boolean, -- le joueur doit occuper un siege d'un duel en cours
}

local TACTICS = { "Agressif", "Equilibre", "Prudent" }
local UNIT_ID: ArgSchema = { kind = "string", max = 12, pattern = "^u%d+$" }
local UNIT_ID_OPTIONAL: ArgSchema =
	{ kind = "string", max = 12, pattern = "^u%d+$", optional = true }

local DuelRemotes = {}

DuelRemotes.FOLDER = "DuelRemotes"
DuelRemotes.COOLDOWN_SECONDS = 0.1

DuelRemotes.clientToServer = {
	JoinDuel = { args = {}, phase = nil, needsSeat = false },
	BuyShopSlot = {
		args = { { kind = "integer", min = 1, max = 5 } },
		phase = "Preparation",
		needsSeat = true,
	},
	Reroll = { args = {}, phase = "Preparation", needsSeat = true },
	BuyXp = { args = {}, phase = "Preparation", needsSeat = true },
	PlaceUnit = {
		args = {
			UNIT_ID,
			{ kind = "integer", min = 1, max = 2 },
			{ kind = "integer", min = 1, max = 4 },
		},
		phase = "Preparation",
		needsSeat = true,
	},
	BenchUnit = { args = { UNIT_ID }, phase = "Preparation", needsSeat = true },
	SellUnit = { args = { UNIT_ID }, phase = "Preparation", needsSeat = true },
	-- SetTactic(tactic, instanceId?) : sans identifiant, la tactique s'applique a toutes les unites du siege.
	SetTactic = {
		args = { { kind = "oneOf", values = TACTICS }, UNIT_ID_OPTIONAL },
		phase = "Preparation",
		needsSeat = true,
	},
	OrderFocus = {
		args = { { kind = "integer", min = 0, max = 7 } },
		phase = "Combat",
		needsSeat = true,
	},
	Ready = { args = {}, phase = "Preparation", needsSeat = true },
} :: { [string]: ClientRemote }

-- Payloads : DuelState -> Types.Duel.ClientView, CombatLog -> CombatLogPayload, DuelEnded -> DuelEndedPayload.
DuelRemotes.serverToClient = { "DuelState", "CombatLog", "DuelEnded" }

DuelRemotes.clientOrder = {
	"JoinDuel",
	"BuyShopSlot",
	"Reroll",
	"BuyXp",
	"PlaceUnit",
	"BenchUnit",
	"SellUnit",
	"SetTactic",
	"OrderFocus",
	"Ready",
}

-- Validation pure d'un argument contre son schema (reutilisee par le serveur, testable sous Lune).
local function isFiniteNumber(value: unknown): boolean
	return typeof(value) == "number" and value == value and math.abs(value :: number) ~= math.huge
end

function DuelRemotes.validateArg(schema: ArgSchema, value: unknown): boolean
	if schema.kind == "integer" then
		return isFiniteNumber(value)
			and (value :: number) % 1 == 0
			and (value :: number) >= schema.min
			and (value :: number) <= schema.max
	elseif schema.kind == "string" then
		if value == nil and schema.optional then
			return true
		end
		if typeof(value) ~= "string" then
			return false
		end
		local text = value :: string
		local length = utf8.len(text)
		if length == nil or length > schema.max then
			return false
		end
		return schema.pattern == nil or string.match(text, schema.pattern :: string) ~= nil
	else
		return typeof(value) == "string" and table.find(schema.values, value :: string) ~= nil
	end
end

function DuelRemotes.validateArgs(name: string, args: { unknown }): boolean
	local remote = DuelRemotes.clientToServer[name]
	if remote == nil then
		return false
	end
	for index, schema in remote.args do
		if not DuelRemotes.validateArg(schema, args[index]) then
			return false
		end
	end
	return true
end

return table.freeze(DuelRemotes)
