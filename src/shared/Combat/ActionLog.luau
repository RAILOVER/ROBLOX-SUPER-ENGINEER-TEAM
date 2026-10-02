--!strict
-- Journal des actions (R-M1-60, version 1) : creation des entrees, identifiants de case et serialisation
-- deterministe (cles triees) utilisee par le test de determinisme M-C-01. Format documente dans
-- docs/architecture/combat.md.

local Types = require(script.Parent.Parent.Types.Combat)

type ActionEntry = Types.ActionEntry
type ActionKind = Types.ActionKind
type Unit = Types.Unit

local ActionLog = {}

ActionLog.VERSION = 1

-- "A3" : camp + case (ligne avant colonne 1 = 0 ... ligne arriere colonne 4 = 7).
function ActionLog.caseOf(unit: Unit): string
	return `{unit.side}{unit.cell}`
end

-- "banano.A3" : slug + case, identifiant d'acteur du journal.
function ActionLog.actorOf(unit: Unit): string
	return `{unit.slug}.{unit.side}{unit.cell}`
end

function ActionLog.newEntry(t: number, actor: Unit, action: ActionKind): ActionEntry
	return {
		t = t,
		actor = ActionLog.actorOf(actor),
		action = action,
		targets = {},
		values = {},
		crits = {},
		statuses = { applied = {}, removed = {} },
		ticks = {},
		gauges = { energy = actor.energy, mega = 0 },
		hp = {},
		kos = {},
	}
end

local function serializeValue(value: any, out: { string })
	local kind = typeof(value)
	if kind == "table" then
		local keys: { any } = {}
		for key in value do
			table.insert(keys, key)
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		table.insert(out, "{")
		for i, key in keys do
			if i > 1 then
				table.insert(out, ",")
			end
			table.insert(out, tostring(key))
			table.insert(out, "=")
			serializeValue(value[key], out)
		end
		table.insert(out, "}")
	elseif kind == "number" then
		table.insert(out, string.format("%.6g", value))
	else
		table.insert(out, tostring(value))
	end
end

-- Serialisation canonique d'un journal (ou de toute table) : deux journaux egaux donnent la meme chaine.
function ActionLog.serialize(log: { ActionEntry }): string
	local out: { string } = {}
	serializeValue(log, out)
	return table.concat(out)
end

return ActionLog
