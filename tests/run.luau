--!strict
-- Runner de tests Lune (decision T-0005). Usage : lune run tests/run.luau [filtre]
-- Charge les modules Luau du depot avec un shim de `require` et de `script` qui imite l'arbre Rojo
-- (default.project.json) pour que `require(script.Parent.X)` fonctionne hors de Roblox.
-- API des specs : describe / it / expect (sous-ensemble compatible TestEZ) exposee en globals du spec.
-- Les specs qui ont besoin du moteur Roblox (DataStore, Remotes, Instances) tournent dans Studio avec TestEZ.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

type Node = { __path: string, __isDir: boolean, Parent: Node?, Name: string }

-- Index du systeme de fichiers construit une fois (les fonctions fs yieldent et ne peuvent pas etre
-- appelees depuis un metamethod).
local isFile: { [string]: boolean } = {}
local isDir: { [string]: boolean } = {}
local function indexTree(dir: string)
	isDir[dir] = true
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			indexTree(path)
		else
			isFile[path] = true
		end
	end
end
indexTree("src")

local moduleCache: { [string]: any } = {}
local sources: { [string]: string } = {}

local function makeNode(path: string, parent: Node?): Node
	local name = string.match(path, "([^/]+)$") or path
	name = string.gsub(name, "%.luau$", "")
	local node = { __path = path, __isDir = isDir[path] == true, Parent = parent, Name = name }
	return setmetatable(node, {
		__index = function(self: Node, key: string): Node
			local base = self.__path
			local candidates = { `{base}/{key}.luau`, `{base}/{key}` }
			for _, candidate in candidates do
				if isFile[candidate] or isDir[candidate] then
					return makeNode(candidate, self)
				end
			end
			error(`module introuvable : {key} sous {base}`)
		end,
	}) :: any
end

local function loadModule(node: Node): any
	local file = node.__isDir and `{node.__path}/init.luau` or node.__path
	if moduleCache[file] ~= nil then
		return moduleCache[file]
	end
	local source = sources[file]
	if source == nil then
		source = fs.readFile(file)
		sources[file] = source
	end
	local env = setmetatable({
		script = node,
		require = function(target: Node): any
			return loadModule(target)
		end,
	}, { __index = getfenv(0) :: any })
	local chunk = luau.load(source, { debugName = file, environment = env :: any })
	local result = chunk()
	moduleCache[file] = result
	return result
end

-- Arbre Rojo minimal : ReplicatedStorage.Shared -> src/shared, ServerScriptService.Server -> src/server
-- La chaine de parents est construite pour que `script.Parent.Parent` fonctionne depuis un sous-dossier.
local function pathRoot(path: string): Node
	local parent = string.match(path, "^(.*)/[^/]+$")
	return makeNode(path, if parent then pathRoot(parent) else nil)
end

-- `name` accepte un chemin "Dossier/Module" pour charger un module d'un sous-dossier avec ses parents.
local function walk(root: Node, name: string): Node
	local node = root
	for part in string.gmatch(name, "[^/]+") do
		node = node[part]
	end
	return node
end

local passed, failed = 0, 0
local failures: { string } = {}
local prefix: { string } = {}

local function expect(value: any)
	local negate = false
	local api = {}
	api.never = api
	local function check(ok: boolean, message: string)
		if negate then
			ok = not ok
		end
		if not ok then
			error(message, 3)
		end
	end
	function api.toBe(expected: any)
		check(value == expected, `attendu {tostring(expected)}, obtenu {tostring(value)}`)
	end
	function api.toEqual(expected: any)
		check(value == expected, `attendu {tostring(expected)}, obtenu {tostring(value)}`)
	end
	function api.toBeTruthy()
		check(value and true or false, `attendu truthy, obtenu {tostring(value)}`)
	end
	function api.toBeNil()
		check(value == nil, `attendu nil, obtenu {tostring(value)}`)
	end
	function api.toBeCloseTo(expected: number, precision: number?)
		local eps = 10 ^ -(precision or 2) / 2
		check(math.abs(value - expected) < eps, `attendu ~{expected}, obtenu {tostring(value)}`)
	end
	function api.toBeGreaterThan(expected: number)
		check(value > expected, `attendu > {expected}, obtenu {tostring(value)}`)
	end
	function api.toBeGreaterThanOrEqual(expected: number)
		check(value >= expected, `attendu >= {expected}, obtenu {tostring(value)}`)
	end
	function api.toBeLessThanOrEqual(expected: number)
		check(value <= expected, `attendu <= {expected}, obtenu {tostring(value)}`)
	end
	function api.toThrow()
		local ok = not pcall(value)
		check(ok, "attendu une erreur")
	end
	return setmetatable(api, {
		__index = function(_, key)
			if key == "never" then
				negate = true
				return api
			end
			return nil
		end,
	})
end

local function describe(name: string, body: () -> ())
	table.insert(prefix, name)
	local ok, err = pcall(body)
	if not ok then
		failed += 1
		table.insert(failures, `{table.concat(prefix, " > ")} : erreur de describe : {err}`)
	end
	table.remove(prefix)
end

local function it(name: string, body: () -> ())
	local full = `{table.concat(prefix, " > ")} > {name}`
	local ok, err = pcall(body)
	if ok then
		passed += 1
	else
		failed += 1
		table.insert(failures, `{full} : {err}`)
	end
end

local filter = process.args[1]
local specs: { string } = {}
local function collect(dir: string)
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			collect(path)
		elseif
			string.match(entry, "%.spec%.luau$")
			and (filter == nil or string.find(path, filter, 1, true))
		then
			table.insert(specs, path)
		end
	end
end
collect("tests")
table.sort(specs)

local startedAt = os.clock()
for _, spec in specs do
	local specStart = os.clock()
	local env = setmetatable({
		describe = describe,
		it = it,
		expect = expect,
		loadShared = function(name: string): any
			return loadModule(walk(pathRoot("src/shared"), name))
		end,
		loadServer = function(name: string): any
			return loadModule(walk(pathRoot("src/server"), name))
		end,
	}, { __index = getfenv(0) :: any })
	local chunk = luau.load(fs.readFile(spec), { debugName = spec, environment = env :: any })
	local ok, err = pcall(chunk)
	if not ok then
		failed += 1
		table.insert(failures, `{spec} : {err}`)
	end
	if process.env.LUNE_TEST_TIMER ~= nil then
		print(`  {spec} : {string.format("%.2f", os.clock() - specStart)} s`)
	end
end

print(
	`{#specs} spec(s), {passed} test(s) OK, {failed} echec(s), {string.format(
		"%.2f",
		os.clock() - startedAt
	)} s`
)
for _, failure in failures do
	print(`  ECHEC {failure}`)
end
process.exit(if failed == 0 then 0 else 1)
