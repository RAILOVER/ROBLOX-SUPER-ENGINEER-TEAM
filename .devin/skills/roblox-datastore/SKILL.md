---
name: roblox-datastore
description: Set up or review safe player data persistence for a Roblox game so players never lose progress. Use when writing, reviewing, or debugging DataStore / save / load code, adding leaderstats or economy variables that must persist, or investigating data loss, item duplication, or "my save got wiped" reports. Builds on ProfileStore with session locking, autosave, BindToClose, and Reconcile.
---

# Roblox DataStore (safe player persistence)

Per-player data that never gets lost, built on **ProfileStore** (loleris/MadStudio) —
the current community-standard save library. It gives you session locking (the #1
fix for data loss and item dupe), 300s autosave, retry/backoff, and BindToClose flush
out of the box. Rolling your own correctly is strictly more code and more risk, so the
library **is** the "simple but safe" answer.

**This skill is driven through the Roblox Studio MCP** (`execute_luau`,
`start_stop_play`, `get_console_output`). Everything below was verified live in a
Studio playtest, not copied from a README.

Paths in this doc are dot-notation Studio paths; file references are relative to this
skill directory.

## When this triggers

Writing/reviewing any save-load code, adding persistent economy variables (coins,
gems, luck, multipliers, rebirths, inventory), or debugging data loss / duplication.

## Step 1 — Install ProfileStore

Fetches the module straight into `ServerScriptService` (no manual copy-paste). Run via
`execute_luau` with `datamodel_type: "Edit"`:

```lua
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
HttpService.HttpEnabled = true
local url = "https://raw.githubusercontent.com/MadStudioRoblox/ProfileStore/main/ProfileStore.luau"
local ok, body = pcall(function() return HttpService:GetAsync(url, true) end)
if not ok then return "FETCH_FAILED: " .. tostring(body) end
local existing = ServerScriptService:FindFirstChild("ProfileStore")
if existing then existing:Destroy() end
local mod = Instance.new("ModuleScript")
mod.Name = "ProfileStore"
mod.Source = body
mod.Parent = ServerScriptService
return ("INSTALLED ProfileStore | bytes=%d"):format(#body)
```

Expected: `INSTALLED ProfileStore | bytes=64654` (~2243 lines). If the game uses Rojo,
instead vendor `ProfileStore.luau` into the project and sync.

## Step 2 — Add the data manager

Create `ServerScriptService.PlayerDataManager` (ModuleScript) from
[references/PlayerDataManager.luau](references/PlayerDataManager.luau) — copy its
source verbatim (use `multi_edit` with `className: "ModuleScript"`). It contains the
`PROFILE_TEMPLATE` (all persisted economy variables), the session-load flow, and the
guardrails. Game code then does, server-side only:

```lua
local PlayerData = require(game.ServerScriptService.PlayerDataManager)
local profile = PlayerData:Get(player)      -- yields until loaded; nil if player left
if profile then
    profile.Data.Coins += 100                -- mutate in memory; autosave persists it
end
```

**Server-authoritative:** the client sends actions ("I collected a coin"), never state
("I now have 500 coins"). Only the server writes `Profile.Data`.

## Step 3 — Adding economy variables later (the key feature)

This is the fix for "I keep adding variables and it breaks old players." **Only add
keys to `PROFILE_TEMPLATE`**, then `profile:Reconcile()` (already called on load)
backfills them for existing players — no wipe, no migration script.

- New defaults must be sensible zeros: `0`, `1` for multipliers, `{}` for collections.
- **Never rename/repurpose an existing key.** For structural changes, bump `DataVersion`
  and migrate explicitly.

See [references/anti-patterns.md](references/anti-patterns.md) for the full data-loss
checklist to apply when reviewing existing code.

## Verify (agent path)

Two checks, both runnable through the MCP. **Run them after any change to the data layer.**

### A. Reconcile proof (no API access needed — uses ProfileStore's mock store)

Proves new keys backfill while existing values are preserved. `execute_luau`,
`datamodel_type: "Edit"`:

```lua
local ProfileStore = require(game.ServerScriptService.ProfileStore)
local store = ProfileStore.New("ReconcileProof", {
    DataVersion = 1, Coins = 0, Gems = 0, Luck = 1,
    LuckMultiplier = 1, IncomeMultiplier = 1, Rebirths = 0, Inventory = {}, Mutations = {},
})
local profile = store.Mock:StartSessionAsync("player_1")
profile.Data.Coins = 500          -- returning player's existing value
profile.Data.LuckMultiplier = nil -- simulate keys that predate this player's save
profile.Data.Gems = nil
profile:Reconcile()
local pass = profile.Data.Coins == 500 and profile.Data.LuckMultiplier == 1 and profile.Data.Gems == 0
profile:EndSession()
return pass and "PASS: backfilled new keys, preserved Coins=500" or "FAIL"
```

Expected: `PASS: backfilled new keys, preserved Coins=500`.

### B. Live session playtest

`start_stop_play {is_start:true}`, then `get_console_output`. A correct load prints:

```
[ProfileStore]: Roblox API services unavailable - data will not be saved
[PlayerData] Loaded <name> | Coins=0 LuckMult=1 v1
```

The first line is expected in Studio (see Gotchas). No red errors = session flow,
template application, and reconcile all working. `start_stop_play {is_start:false}` after.

To exercise economy writes, drop a temporary server Script that calls
`PlayerData:Get(player)` and increments `profile.Data.Coins` in a loop, then read the
console — coins should climb. Delete the temp script afterward.

## Gotchas

- **Studio never saves and never exercises the real shutdown/lock path.** ProfileStore
  auto-uses a mock store when "Studio Access to API Services" is off (and even when on,
  BindToClose behaves differently than a live server). The console line
  `Roblox API services unavailable - data will not be saved` is normal in Studio.
  **Real persistence, session-lock handoff, and BindToClose can only be validated on a
  published server:** join, earn currency, shut the server down via a forced update,
  rejoin, confirm it stuck.
- **If load fails, kick — never fall back to defaults.** Playing on a default table
  over a real save is how autosave silently wipes a player. The template already does this.
- **`OnSessionEnd` must kick.** It fires when another server steals the lock; the player
  is now on stale data.
- **Don't lower the 300s autosave** thinking it's safer — it burns request budget and
  worsens throttling. The lock + leave-save + BindToClose already guarantee the final
  state lands.
- **Mutate in memory only.** Never `SetAsync`/`UpdateAsync` on every currency change.
- **Cap `Inventory`.** A value >4 MB after JSON encode makes *every* save fail.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `FETCH_FAILED` on install | Studio blocked the HTTP request, or offline. Enable `HttpService.HttpEnabled`, or vendor `ProfileStore.luau` manually. |
| `Roblox API services unavailable` | Expected in Studio (mock mode). To test real saving, publish and test in-game, or enable Studio API access in Game Settings > Security. |
| Player kicked "data could not be loaded" | `StartSessionAsync` returned nil — real DataStore failure or lock contention. Check `ProfileStore.OnError`; retry by rejoining. This is the guardrail working, not a bug. |
| Data resets every server restart | Missing/short-circuited BindToClose, or you're testing in Studio. Verify on a live server. |
| Two players' data mixing / dupes | Session locking bypassed (custom save path writing the same key). Route ALL writes through `PlayerDataManager`. |
