--!strict
-- Index des modules monde purs (geometrie, aucun type Roblox). Charge sous Lune par loadShared("World").

local World = {
	ArenaGeometry = require(script.ArenaGeometry),
}

return table.freeze(World)
