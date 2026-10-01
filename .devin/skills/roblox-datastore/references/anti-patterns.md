# DataStore anti-patterns & data-loss root causes

The concrete mistakes that cause real player data loss in shipped Roblox games.
The `PlayerDataManager` template + ProfileStore prevent all of these — this list
is why each guardrail exists, and what to check when reviewing existing code.

## The root causes (ranked by how often they wipe players)

1. **Two servers writing the same key (no session locking).** Teleports, fast
   rejoin (leave server A, join server B before A saves), and crash overlap let
   two servers load + write the same key. Result: clobbering (stale overwrite) or
   item **duplication**. This is the #1 cause. → ProfileStore session locking makes
   it structurally impossible; a server only writes while it holds the lock.

2. **Overwriting good data after a failed load.** Load `pcall` fails, code proceeds
   with a default/empty table, then autosave writes that empty table over the real
   save. **Rule: if load fails, KICK the player.** Never let them play on defaults
   over a real save. → `PlayerDataManager` kicks on `profile == nil`.

3. **Not checking `pcall` success.** Treating the result as valid data when
   `success` was `false`.

4. **Using `SetAsync` for player data.** Blind overwrite, no atomicity. Use
   `UpdateAsync` (reads current value, lets you merge or abort by returning nil).
   → ProfileStore uses UpdateAsync internally.

5. **No `BindToClose`.** Roblox force-restarts every server on each game update.
   Without a shutdown flush, all progress since the last autosave is lost every
   update. `PlayerRemoving` is NOT reliable at shutdown. → ProfileStore hooks
   BindToClose internally.

6. **Sequential saves in `BindToClose` exceeding the 30s limit.** Later players
   never save. → ProfileStore ends all sessions in parallel.

7. **No retry/backoff.** A transient rate-limit or outage becomes permanent loss.
   → ProfileStore retries with exponential backoff.

8. **Bursting writes / ignoring throttling.** Saving on every currency change
   instead of a debounced autosave overflows the 30-request queue (error codes
   301–306) and drops writes. → Mutate `Profile.Data` in memory; let autosave
   (300s) + leave-save persist. **Do not lower the autosave interval thinking it
   is safer — it is counterproductive.**

9. **Saving partial/corrupt state.** Saving mid-transaction (item removed but
   currency not yet added), or storing NaN (`0/0`), negative currency, etc. Apply
   the whole transaction to `Profile.Data` before yielding; clamp/validate values.

10. **Studio-only testing.** Studio uses a mock store and does NOT exercise the
    real shutdown/lock-handoff path. Validate persistence on a **published** server.

## Values that silently break DataStore serialization

`Profile.Data` is JSON-encoded. These drop or throw:

- Numeric tables with gaps (`{[1]=a, [3]=c}`).
- Mixed tables (some numeric keys, some string keys) — only numeric-indexed data saves.
- Keys that are not numbers or strings.
- Roblox Instances, `userdata` (Vector3/Color3/CFrame — serialize first), functions.

## Hard limits to design against

- Value size ≤ 4 MB per key after JSON encode. A runaway inventory table hits this
  and then **every save fails**. Cap inventory size.
- Key name ≤ 50 chars.
- `UpdateAsync` bills both the read AND write budget (matters only if hand-rolling).
- Request budgets are per-minute and scale with player count; each throttle queue
  holds only 30 requests before failing.

## Schema-growth rule (the "I keep adding economy variables" problem)

- **Only ADD keys** to `PROFILE_TEMPLATE`. `profile:Reconcile()` backfills them for
  existing players on next load, using the template default, without touching keys
  the player already has. New defaults must be sensible "zero" values (`0`, `1` for
  multipliers, `{}` for collections) because existing players silently receive them.
- **Never rename or repurpose an existing key** — it silently corrupts old saves.
  For structural changes, add a `DataVersion` integer and run an explicit one-time
  migration keyed off it.

## Library choice (2024–2026 consensus)

- **ProfileStore** — current default (loleris/MadStudio). Successor to ProfileService;
  300s autosave + MessagingService lock handoff. What large games (e.g. Grow a Garden)
  use. **Use this.**
- **ProfileService** — still solid but in maintenance; use its successor for new work.
- **DataStore2** — legacy; does not do true session locking. Don't start new work on it.
- **Raw DataStoreService** — only for leaderboards/global data (with OrderedDataStore),
  never as a hand-rolled foundation for per-player economy data.
