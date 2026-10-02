--!strict
-- Harnais de simulation QA (T-0015). Usage :
--   lune run tests/sim/run_duels.luau [N=10000] [seed=20261002] [--m1] [--out=chemin.csv]
-- Simule N combats CombatSim avec des equipes aleatoires (2 a 8 unites, meme taille des 2 cotes, etoiles 1 a 3,
-- tactiques variees) tirees du roster L0, ou des 10 unites M1 avec placements realistes en mode --m1. Chaque paire d'equipes est jouee dans
-- les 2 sens avec la meme seed (neutralise l'avantage d'initiative du camp A dans les taux par unite).
-- Blocs de mesure supplementaires : N/10 combats miroir (meme equipe des 2 cotes, avantage du camp A) et N/20
-- equipes miroir par duel de tactiques (Agressif, Equilibre, Prudent, dans les 2 sens).
-- Ecrit tests/sim/out/duels-<date>[-m1].csv et imprime un resume Markdown. Ne modifie aucune valeur de Config.

local fs = require("@lune/fs")
local process = require("@lune/process")
local datetime = require("@lune/datetime")
local Loader = require("./Loader")
local Teams = require("./Teams")
local Stats = require("./Stats")

local Config = Loader.loadShared("Config")
local CombatSim = Loader.loadShared("Combat/CombatSim")
local Rng = Loader.loadShared("Combat/Rng")

type Unit = Teams.Unit

local count = 10000
local masterSeed = 20261002
local m1 = false
local outPath: string? = nil
local positional = 0
for _, arg in process.args do
	if arg == "--m1" then
		m1 = true
	elseif string.sub(arg, 1, 6) == "--out=" then
		outPath = string.sub(arg, 7)
	else
		positional += 1
		local value = tonumber(arg)
		assert(value, `argument inattendu : {arg}`)
		if positional == 1 then
			count = value
		elseif positional == 2 then
			masterSeed = value
		end
	end
end

local slugs: { string } = table.clone(if m1 then Config.Skills.m1Slugs else Config.Roster.slugs)
table.sort(slugs)
local rng = Rng.new(masterSeed)
local MAX_SEED = 2 ^ 31 - 1

local function synergiesOf(state: any, side: string): { string }
	local out: { string } = {}
	for name, tier in state.teams[side].activeSynergies do
		table.insert(out, `{name}:{tier}`)
	end
	table.sort(out)
	return out
end

type Outcome = { result: any?, synA: { string }, synB: { string }, ms: number, err: string? }

local function runOne(seed: number, teamA: { Unit }, teamB: { Unit }): Outcome
	local started = os.clock()
	local okState, state = pcall(CombatSim.newState, seed, teamA, teamB, Config)
	if not okState then
		return { synA = {}, synB = {}, ms = 0, err = tostring(state) }
	end
	local synA, synB = synergiesOf(state, "A"), synergiesOf(state, "B")
	local ok, result = pcall(CombatSim.simulate, seed, teamA, teamB, Config)
	local ms = (os.clock() - started) * 1000
	if not ok then
		return { synA = synA, synB = synB, ms = ms, err = tostring(result) }
	end
	return { result = result, synA = synA, synB = synB, ms = ms }
end

local csv: { string } = {
	"seed,winner,actions,ticks,duration_ms,synergiesA,synergiesB,unitsA,unitsB,mvp,unimplemented",
}

local function csvRow(seed: number, teamA: { Unit }, teamB: { Unit }, o: Outcome)
	local r = o.result
	table.insert(
		csv,
		table.concat({
			tostring(seed),
			if r then r.winner else "error",
			if r then tostring(r.actions) else "",
			if r then tostring(r.turns) else "",
			string.format("%.3f", o.ms),
			table.concat(o.synA, ";"),
			table.concat(o.synB, ";"),
			Teams.describe(teamA),
			Teams.describe(teamB),
			if r then (r.mvp or "") else "",
			if r then table.concat(Stats.listOf(r.unimplemented), ";") else "",
		}, ",")
	)
end

local main = Stats.new()
local started = os.clock()

local function play(
	stats: Stats.Stats,
	seed: number,
	teamA: { Unit },
	teamB: { Unit },
	toCsv: boolean
): Outcome
	local o = runOne(seed, teamA, teamB)
	if o.result then
		stats:record(Config, o.result, teamA, teamB, o.synA, o.synB, o.ms)
	else
		stats:recordError(seed, o.err or "?")
	end
	if toCsv then
		csvRow(seed, teamA, teamB, o)
	end
	return o
end

-- Bloc principal : N combats = N/2 paires jouees dans les 2 sens (meme seed). Les 2 equipes d'une paire ont la
-- meme taille (2 a 8) : sinon le taux par unite mesure surtout l'avantage numerique (8 contre 2 gagne 84 %).
local played = 0
while played < count do
	local seed = rng:NextInteger(1, MAX_SEED)
	local size = rng:NextInteger(Teams.MIN_SIZE, Teams.MAX_SIZE)
	local teamA = Teams.random(Config, rng, slugs, m1, size)
	local teamB = Teams.random(Config, rng, slugs, m1, size)
	play(main, seed, teamA, teamB, true)
	played += 1
	if played < count then
		play(main, seed, teamB, teamA, true)
		played += 1
	end
end

-- Bloc miroir : meme equipe des 2 cotes, mesure l'avantage d'initiative du camp A.
local mirror = Stats.new()
local mirrorCount = math.max(1, count // 10)
for _ = 1, mirrorCount do
	local team = Teams.random(Config, rng, slugs, m1)
	play(mirror, rng:NextInteger(1, MAX_SEED), team, Teams.withTactic(team, team[1].tactic), false)
end

-- Bloc tactiques : meme equipe des 2 cotes, tactique X contre Y, dans les 2 sens (R-M1-54 generalise).
local tacticCount = math.max(1, count // 20)
local tacticStats = Stats.new()
local tacticLines = {
	"| duel (meme equipe, 2 sens) | combats | victoires 1re | victoires 2e | nuls | % 1re | % 2e | fenetre 35 a 65 |",
	"|---|---|---|---|---|---|---|---|",
}
local function tally(o: Outcome, aTactic: string, bTactic: string, wins: { [string]: number })
	local r = o.result
	if r == nil or r.winner == "draw" then
		wins.draw += 1
	else
		local tactic = if r.winner == "A" then aTactic else bTactic
		wins[tactic] += 1
	end
end
for i = 1, #Teams.TACTICS do
	for j = i + 1, #Teams.TACTICS do
		local x, y = Teams.TACTICS[i], Teams.TACTICS[j]
		local wins: { [string]: number } = { [x] = 0, [y] = 0, draw = 0 }
		for _ = 1, tacticCount do
			local team = Teams.random(Config, rng, slugs, m1)
			local seed = rng:NextInteger(1, MAX_SEED)
			local tx, ty = Teams.withTactic(team, x), Teams.withTactic(team, y)
			tally(play(tacticStats, seed, tx, ty, false), x, y, wins)
			tally(play(tacticStats, seed, ty, tx, false), y, x, wins)
		end
		local n = 2 * tacticCount
		local px, py = wins[x] / n * 100, wins[y] / n * 100
		local inWindow = px >= 35 and px <= 65 and py >= 35 and py <= 65
		table.insert(
			tacticLines,
			`| {x} contre {y} | {n} | {wins[x]} | {wins[y]} | {wins.draw} | {string.format(
				"%.1f",
				px
			)} | {string.format("%.1f", py)} | {if inWindow then "ok" else "HORS"} |`
		)
	end
end

local elapsed = os.clock() - started

-- Ecriture du CSV.
local date = datetime.now():formatUniversalTime("%Y-%m-%d")
local path = outPath or `tests/sim/out/duels-{date}{if m1 then "-m1" else ""}.csv`
local dir = string.match(path, "^(.*)/[^/]+$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
fs.writeFile(path, table.concat(csv, "\n") .. "\n")

-- Resume console (Markdown).
local out: { string } = {}
local function section(title: string, lines: { string })
	table.insert(out, "")
	table.insert(out, `### {title}`)
	table.insert(out, "")
	for _, line in lines do
		table.insert(out, line)
	end
end
table.insert(
	out,
	`## Harnais T-0015 : {count} combats {if m1
		then "M1 (10 unites, placements D-M1-29)"
		else "L0 (42 unites, cases aleatoires)"}, seed maitre {masterSeed}, {date}`
)
section("Resume (bloc principal, chaque paire jouee dans les 2 sens)", main:summaryLines(Config))
table.insert(
	out,
	`- total simule (principal + miroir + tactiques) : {main.total + mirror.total + tacticStats.total} combats en {string.format(
		"%.2f",
		elapsed
	)} s ; CSV : {path} ({#csv - 1} lignes)`
)
section("Avantage du camp A au miroir (meme equipe, memes tactiques)", {
	`- {mirror.total} combats : camp A {mirror.winsA} ({string.format(
		"%.1f",
		mirror.winsA / math.max(1, mirror.total) * 100
	)} %), camp B {mirror.winsB} ({string.format(
		"%.1f",
		mirror.winsB / math.max(1, mirror.total) * 100
	)} %), nuls {mirror.draws} ({string.format(
		"%.1f",
		mirror.draws / math.max(1, mirror.total) * 100
	)} %)`,
})
section("Tactiques au miroir (R-M1-54 generalise)", tacticLines)
section(
	"Taux de victoire par unite (fenetre 40 a 60 %)",
	Stats.table(main.units, "unite", { 40, 60 })
)
section("Par classe", Stats.table(main.classes, "classe"))
section("Par nombre d'etoiles", Stats.table(main.stars, "etoiles"))
section("Par tactique (par unite, bloc principal)", Stats.table(main.tactics, "tactique"))
section("Par taille d'equipe", Stats.table(main.sizes, "unites"))
section(
	"Par synergie active (seuil 65 %)",
	Stats.table(main.synergies, "synergie:palier", { 0, 65 })
)
section("Distribution des actions", main:histogramLines())
section("Effets non implementes rencontres", main:unimplementedLines())
if #main.errors > 0 then
	section("Erreurs", main.errors)
end
print(table.concat(out, "\n"))
