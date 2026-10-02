--!strict
-- Chargeur de modules src/shared pour les scripts Lune hors du runner de tests (tests/run.luau).
-- Meme shim `require` / `script` que le runner : l'arbre Rojo est imite pour que `require(script.Parent.X)`
-- fonctionne hors de Roblox. Usage : local Config = require("./Loader").loadShared("Config")

local fs = require("@lune/fs")
local luau = require("@lune/luau")

type Node = { __path: string, __isDir: boolean, Parent: Node?, Name: string }

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

local function makeNode(path: string, parent: Node?): Node
	local name = string.match(path, "([^/]+)$") or path
	name = string.gsub(name, "%.luau$", "")
	local node = { __path = path, __isDir = isDir[path] == true, Parent = parent, Name = name }
	return setmetatable(node, {
		__index = function(self: Node, key: string): Node
			local base = self.__path
			for _, candidate in { `{base}/{key}.luau`, `{base}/{key}` } do
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
	local env = setmetatable({
		script = node,
		require = function(target: Node): any
			return loadModule(target)
		end,
	}, { __index = getfenv(0) :: any })
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = env :: any })
	local result = chunk()
	moduleCache[file] = result
	return result
end

local function pathRoot(path: string): Node
	local parent = string.match(path, "^(.*)/[^/]+$")
	return makeNode(path, if parent then pathRoot(parent) else nil)
end

local Loader = {}

-- `name` accepte un chemin "Dossier/Module" (ex. "Combat/CombatSim").
function Loader.loadShared(name: string): any
	local node = pathRoot("src/shared")
	for part in string.gmatch(name, "[^/]+") do
		node = node[part]
	end
	return loadModule(node)
end

return Loader
