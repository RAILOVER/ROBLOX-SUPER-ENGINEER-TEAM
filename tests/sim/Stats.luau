--!strict
-- Agregats du harnais QA : taux de victoire par unite, classe, etoiles, tactique et synergie (une unite ou une
-- synergie "gagne" quand son camp gagne ; les nuls sont comptes a part), distribution des actions, durees,
-- erreurs, Mega Combos, effets non implementes. Sortie Markdown pour la console et le rapport.

local Stats = {}
Stats.__index = Stats

export type Bucket = { n: number, wins: number, losses: number, draws: number }
type Map = { [string]: Bucket }
type Unit = { slug: string, row: number, col: number, stars: number, tactic: string }

export type Stats = typeof(setmetatable(
	{} :: {
		units: Map,
		classes: Map,
		stars: Map,
		tactics: Map,
		synergies: Map,
		sizes: Map,
		histogram: { [number]: number },
		unimplemented: { [string]: number },
		errors: { string },
		total: number,
		draws: number,
		winsA: number,
		winsB: number,
		totalActions: number,
		maxActions: number,
		totalMs: number,
		maxMs: number,
		animSeconds: number,
		megaCombats: number,
		megaActions: number,
		megaValues: number,
		allValues: number,
	},
	Stats
))

function Stats.new(): Stats
	return setmetatable({
		units = {},
		classes = {},
		stars = {},
		tactics = {},
		synergies = {},
		sizes = {},
		histogram = {},
		unimplemented = {},
		errors = {},
		total = 0,
		draws = 0,
		winsA = 0,
		winsB = 0,
		totalActions = 0,
		maxActions = 0,
		totalMs = 0,
		maxMs = 0,
		animSeconds = 0,
		megaCombats = 0,
		megaActions = 0,
		megaValues = 0,
		allValues = 0,
	}, Stats)
end

local function bump(map: Map, key: string, outcome: string)
	local bucket = map[key]
	if bucket == nil then
		bucket = { n = 0, wins = 0, losses = 0, draws = 0 }
		map[key] = bucket
	end
	bucket.n += 1
	if outcome == "win" then
		bucket.wins += 1
	elseif outcome == "loss" then
		bucket.losses += 1
	else
		bucket.draws += 1
	end
end

local function outcomeFor(winner: string, side: string): string
	if winner == "draw" then
		return "draw"
	end
	return if winner == side then "win" else "loss"
end

-- Liste triee des cles d'un tableau (tableau-liste ou ensemble) : forme stable pour le CSV.
function Stats.listOf(value: any): { string }
	local out: { string } = {}
	if type(value) ~= "table" then
		return out
	end
	if #value > 0 then
		for _, item in value do
			table.insert(out, tostring(item))
		end
	else
		for key in value do
			table.insert(out, tostring(key))
		end
	end
	table.sort(out)
	return out
end

local function recordSide(
	self: Stats,
	config: any,
	team: { Unit },
	synergies: { string },
	outcome: string
)
	for _, unit in team do
		bump(self.units, unit.slug, outcome)
		bump(self.classes, config.Roster.units[unit.slug].class, outcome)
		bump(self.stars, tostring(unit.stars), outcome)
		bump(self.tactics, unit.tactic, outcome)
	end
	bump(self.sizes, tostring(#team), outcome)
	for _, synergy in synergies do
		bump(self.synergies, synergy, outcome)
	end
end

function Stats.record(
	self: Stats,
	config: any,
	result: any,
	teamA: { Unit },
	teamB: { Unit },
	synA: { string },
	synB: { string },
	ms: number
)
	self.total += 1
	if result.winner == "draw" then
		self.draws += 1
	elseif result.winner == "A" then
		self.winsA += 1
	else
		self.winsB += 1
	end
	recordSide(self, config, teamA, synA, outcomeFor(result.winner, "A"))
	recordSide(self, config, teamB, synB, outcomeFor(result.winner, "B"))
	self.totalActions += result.actions
	self.maxActions = math.max(self.maxActions, result.actions)
	self.histogram[result.actions] = (self.histogram[result.actions] or 0) + 1
	self.totalMs += ms
	self.maxMs = math.max(self.maxMs, ms)
	local megas = 0
	for _, entry in result.actionLog do
		local sum = 0
		for _, v in entry.values do
			sum += math.abs(v)
		end
		self.allValues += sum
		if entry.action == "Mega" then
			megas += 1
			self.megaValues += sum
		end
	end
	self.megaActions += megas
	if megas > 0 then
		self.megaCombats += 1
	end
	self.animSeconds += result.actions * config.Combat.pvpActionAnimationMaxSeconds + 2.5 * megas
	for _, key in Stats.listOf(result.unimplemented) do
		self.unimplemented[key] = (self.unimplemented[key] or 0) + 1
	end
end

function Stats.recordError(self: Stats, seed: number, message: string)
	table.insert(self.errors, `seed {seed} : {message}`)
end

local function pct(num: number, den: number): string
	if den == 0 then
		return "n/a"
	end
	return string.format("%.1f", num / den * 100)
end

local function decidedRate(b: Bucket): number
	return b.wins / math.max(1, b.wins + b.losses)
end

local function sortedRows(map: Map): { { key: string, bucket: Bucket } }
	local rows = {}
	for key, bucket in map do
		table.insert(rows, { key = key, bucket = bucket })
	end
	table.sort(rows, function(a, b)
		local ra, rb = decidedRate(a.bucket), decidedRate(b.bucket)
		return if ra ~= rb then ra > rb else a.key < b.key
	end)
	return rows
end

-- Tableau Markdown d'un agregat ; `window` = { min, max } en % pour marquer les lignes hors fenetre.
-- "% victoires" = victoires / combats ; "% hors nuls" = victoires / (victoires + defaites) : c'est ce taux qui est
-- compare a la fenetre, pour ne pas compter les nuls comme des defaites.
function Stats.table(map: Map, label: string, window: { number }?): { string }
	local lines = {
		`| {label} | combats | victoires | defaites | nuls | % victoires | % hors nuls | fenetre |`,
		"|---|---|---|---|---|---|---|---|",
	}
	for _, row in sortedRows(map) do
		local b = row.bucket
		local rate = decidedRate(b) * 100
		local flag = ""
		if window then
			flag = if rate < window[1] or rate > window[2] then "HORS" else "ok"
		end
		table.insert(
			lines,
			`| {row.key} | {b.n} | {b.wins} | {b.losses} | {b.draws} | {pct(b.wins, b.n)} | {pct(
				b.wins,
				b.wins + b.losses
			)} | {flag} |`
		)
	end
	return lines
end

function Stats.histogramLines(self: Stats): { string }
	local lines = { "| actions | combats | % |", "|---|---|---|" }
	local edges = { 10, 20, 30, 40, 50, 59, 60 }
	local low = 1
	for _, high in edges do
		local count = 0
		for actions = low, high do
			count += self.histogram[actions] or 0
		end
		local label = if low == high then tostring(low) else `{low} a {high}`
		table.insert(lines, `| {label} | {count} | {pct(count, self.total)} |`)
		low = high + 1
	end
	return lines
end

function Stats.summaryLines(self: Stats, config: any): { string }
	local n = math.max(1, self.total)
	local lines = {
		`- combats : {self.total} ; erreurs : {#self.errors}`,
		`- camp A : {self.winsA} ({pct(self.winsA, self.total)} %) ; camp B : {self.winsB} ({pct(
			self.winsB,
			self.total
		)} %) ; nuls : {self.draws} ({pct(self.draws, self.total)} %, cible M-C-03 < 2 %)`,
		`- actions : moyenne {string.format("%.1f", self.totalActions / n)} ; max {self.maxActions} (plafond {config.Combat.drawAfterActions})`,
		`- duree animee estimee (M-C-04) : {string.format("%.1f", self.animSeconds / n)} s en moyenne (cible 20 a 35 s)`,
		`- Mega Combos : {pct(self.megaCombats, self.total)} % des combats en ont au moins 1 (cible 60 a 80 %) ; {string.format(
			"%.2f",
			self.megaActions / n
		)} Mega par combat ; part des valeurs (degats, soins, boucliers) des Mega : {pct(
			self.megaValues,
			self.allValues
		)} % (cible <= 20 %)`,
		`- calcul : {string.format("%.2f", self.totalMs / 1000)} s au total ; {string.format(
			"%.2f",
			self.totalMs / n
		)} ms par combat ; max {string.format("%.1f", self.maxMs)} ms`,
	}
	return lines
end

function Stats.unimplementedLines(self: Stats): { string }
	local lines = { "| effet non implemente | combats |", "|---|---|" }
	local keys = Stats.listOf(self.unimplemented)
	for _, key in keys do
		table.insert(lines, `| {key} | {self.unimplemented[key]} |`)
	end
	if #keys == 0 then
		table.insert(lines, "| aucun | 0 |")
	end
	return lines
end

return Stats
