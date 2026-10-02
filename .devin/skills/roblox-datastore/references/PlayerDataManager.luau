--!strict
--[[
	PlayerDataManager
	-----------------
	Safe per-player persistence built on ProfileStore (session locking + autosave
	+ BindToClose + Reconcile all handled by the library).

	GUARDRAILS (do not remove):
	  * If a session fails to load -> the player is KICKED. Never let a player play
	    on default data over a real save (that is how autosave wipes good data).
	  * OnSessionEnd -> KICK. Fires when another server steals the lock; the player
	    must not keep playing on data now owned elsewhere.
	  * Add new economy variables ONLY to PROFILE_TEMPLATE. profile:Reconcile()
	    fills them in for existing players on next load -- no wipe, no migration.
	  * NEVER rename/repurpose an existing key. For structural changes, bump
	    DataVersion and migrate explicitly.

	Usage (server-side only):
	  local PlayerData = require(game.ServerScriptService.PlayerDataManager)
	  local profile = PlayerData:Get(player)      -- yields until loaded, nil if gone
	  if profile then profile.Data.Coins += 100 end
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.ProfileStore)

-- The single source of truth for every persisted economy variable.
-- Only ADD keys here. Reconcile() safely backfills them for existing players.
local PROFILE_TEMPLATE = {
	DataVersion = 1,       -- bump only for structural migrations, never for new keys
	Coins = 0,
	Gems = 0,
	Luck = 1,              -- multiplicative luck stat (biases roll weights)
	LuckMultiplier = 1,
	IncomeMultiplier = 1,
	Rebirths = 0,
	Inventory = {},        -- keep bounded; a runaway table can hit the 4MB cap
	Mutations = {},
}

local PlayerStore = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)

local PlayerData = {}
PlayerData.Profiles = {} :: { [Player]: any }

local function onPlayerAdded(player: Player)
	-- Cancel aborts the (possibly lock-contended) load if the player leaves first.
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Load genuinely failed (not just player leaving) -> do NOT run on defaults.
		player:Kick("Your data could not be loaded. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId) -- GDPR / ownership association
	profile:Reconcile()              -- backfill any newly-added template keys

	profile.OnSessionEnd:Connect(function()
		PlayerData.Profiles[player] = nil
		player:Kick("Your data is now active on another server. Please rejoin.")
	end)

	if player.Parent == Players then
		PlayerData.Profiles[player] = profile
		print(`[PlayerData] Loaded {player.Name} | Coins={profile.Data.Coins} LuckMult={profile.Data.LuckMultiplier} v{profile.Data.DataVersion}`)
	else
		-- Player left during the load yield.
		profile:EndSession()
	end
end

--[[ Yields until the player's profile is ready. Returns nil if they left. ]]
function PlayerData:Get(player: Player)
	while player.Parent == Players and PlayerData.Profiles[player] == nil do
		task.wait()
	end
	return PlayerData.Profiles[player]
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = PlayerData.Profiles[player]
	if profile then
		profile:EndSession() -- flush + release lock on normal leave
	end
end)

return PlayerData
