--!strict
-- Mesure R-M1-54 (T-0024) : combats miroir entre tactiques sur des equipes M1 identiques.
-- Inactif par defaut (0 test) pour ne pas ralentir `lune run tests/run.luau`. Usage :
--   COMBAT_SIM_MIRROR=2000 lune run tests/run.luau sim/MirrorTactics
--   COMBAT_OVERRIDES="tactics.Prudent.guardBelowHp=0.25;guardTimelineAdvance=0.5" pour essayer des valeurs de
--   Config.Combat sans modifier le fichier (chemins pointes, separes par ";").

local process = require("@lune/process")
local Config = loadShared("Config")
local CombatSim = loadShared("Combat/CombatSim")

local COUNT = tonumber(process.env.COMBAT_SIM_MIRROR)

type Team = { { slug: string, row: number, col: number, tactic: string } }

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		out[k] = deepCopy(v)
	end
	return out
end

local function applyOverrides(combat: any, spec: string)
	for assignment in string.gmatch(spec, "[^;]+") do
		local path, raw = string.match(assignment, "^%s*([%w%.]+)%s*=%s*([%w%.%-]+)%s*$")
		assert(path and raw, `override invalide : {assignment}`)
		local node = combat
		local keys = {}
		for key in string.gmatch(path :: string, "[^%.]+") do
			table.insert(keys, key)
		end
		for i = 1, #keys - 1 do
			node = node[keys[i]]
			assert(type(node) == "table", `chemin inconnu : {path}`)
		end
		local last = keys[#keys]
		assert(node[last] ~= nil, `cle inconnue : {path}`)
		node[last] = tonumber(raw) or raw
	end
end

local function patchedConfig(): any
	local overrides = process.env.COMBAT_OVERRIDES
	if overrides == nil or overrides == "" then
		return Config
	end
	local combat = deepCopy(Config.Combat)
	applyOverrides(combat, overrides)
	return setmetatable({ Combat = combat }, { __index = Config })
end

local COMPOSITIONS: { { name: string, cells: { { slug: string, row: number, col: number } } } } = {
	{
		name = "T1 (test R-M1-54)",
		cells = {
			{ slug = "banano", row = 1, col = 2 },
			{ slug = "bananella", row = 2, col = 2 },
			{ slug = "glorbo-fruttodrillo", row = 1, col = 3 },
			{ slug = "pomita", row = 2, col = 3 },
			{ slug = "tim-cheese", row = 2, col = 1 },
		},
	},
	{
		name = "T2 (Couple pomme + Mare)",
		cells = {
			{ slug = "pomito", row = 1, col = 2 },
			{ slug = "boneca-ambalabu", row = 1, col = 3 },
			{ slug = "trippi-troppi", row = 1, col = 1 },
			{ slug = "pomita", row = 2, col = 2 },
			{ slug = "ta-ta-ta-ta-sahur", row = 2, col = 3 },
		},
	},
}

local MATCHUPS = {
	{ "Agressif", "Prudent" },
	{ "Agressif", "Agressif" },
	{ "Agressif", "Equilibre" },
	{ "Equilibre", "Prudent" },
	{ "Prudent", "Prudent" },
}

local function team(cells, tactic: string): Team
	local out: Team = {}
	for _, cell in cells do
		table.insert(out, { slug = cell.slug, row = cell.row, col = cell.col, tactic = tactic })
	end
	return out
end

-- Les camps sont alternes : seed impair = tactique 1 en A, seed pair = tactique 1 en B.
local function measure(config: any, cells, tacticX: string, tacticY: string, count: number)
	local winsX, winsY, draws, actions = 0, 0, 0, 0
	for seed = 1, count do
		local xIsA = seed % 2 == 1
		local a = team(cells, if xIsA then tacticX else tacticY)
		local b = team(cells, if xIsA then tacticY else tacticX)
		local result = CombatSim.simulate(seed, a, b, config)
		actions += result.actions
		if result.winner == "draw" then
			draws += 1
		elseif (result.winner == "A") == xIsA then
			winsX += 1
		else
			winsY += 1
		end
	end
	return winsX, winsY, draws, actions / count
end

if COUNT ~= nil then
	describe("R-M1-54 : miroir des tactiques (T-0024)", function()
		local config = patchedConfig()
		print(`  COMBAT_OVERRIDES = {process.env.COMBAT_OVERRIDES or "(aucun)"}`)
		for _, composition in COMPOSITIONS do
			for _, matchup in MATCHUPS do
				local x, y = matchup[1], matchup[2]
				it(`{composition.name} : {x} contre {y} sur {COUNT} combats`, function()
					local winsX, winsY, draws, meanActions =
						measure(config, composition.cells, x, y, COUNT)
					print(
						`  {composition.name} {x} {string.format("%.1f", 100 * winsX / COUNT)} % / {y} {string.format(
							"%.1f",
							100 * winsY / COUNT
						)} % / nuls {string.format("%.1f", 100 * draws / COUNT)} % ; actions moyennes {string.format(
							"%.1f",
							meanActions
						)}`
					)
					expect(winsX + winsY + draws).toBe(COUNT)
				end)
			end
		end
	end)
end
