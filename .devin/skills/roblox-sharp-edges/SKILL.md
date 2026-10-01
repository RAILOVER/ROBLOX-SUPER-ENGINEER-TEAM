---
name: roblox-sharp-edges
description: Twelve production footguns in Roblox games (data loss, client trust, receipts, leaks, floods, mobile part counts). Read once per role, re-read before any release gate.
sources: [original, https://create.roblox.com/docs]
---

# Roblox sharp edges

## When to Load

Before writing a remote, a DataStore, a receipt handler, or approving a PR that touches them. Each item names the symptom, the cause, and the fix the team uses.

## Quick Reference

| ID | Severity | Edge | Fix in this repo |
|----|----------|------|------------------|
| SE-1 | Critical | Two servers write the same player profile (teleport, rejoin) and one overwrites the other | Session lock (ProfileStore or equivalent), `UpdateAsync`, never raw `SetAsync` for profiles |
| SE-2 | Critical | Currency or stats held in a replicated Value object or sent by the client | Server-owned profile table; client only displays what the server returns (`ShopService.luau`) |
| SE-3 | Critical | `ProcessReceipt` grants before persisting, or returns `PurchaseGranted` on error | Persist first, return `NotProcessedYet` on any failure, dedupe on `PurchaseId` |
| SE-4 | High | Connections never disconnected; memory grows for hours | Maid/Janitor per object, `:Once()`, `Destroying` hook; QA watches memory 10 min |
| SE-5 | High | Remote flooded at 100+ req/s, heartbeat climbs | `RemoteGuard.cooldown` per player per remote; QA flood test |
| SE-6 | High | `BindToClose` work exceeds 30 s and saves are cut | Save on meaningful change; `BindToClose` only flushes pending profiles in parallel |
| SE-7 | Medium | 50k parts in view on a phone | `max_parts_visible` budget, StreamingEnabled, modular kits with LODs |
| SE-8 | Medium | A ModuleScript yields at top level (WaitForChild without timeout) and freezes startup | No yields in module top level; bounded `WaitForChild(name, 10)` and nil handling |
| SE-9 | Medium | `#t` on a table with nil gaps gives a wrong length; `nil` inside a remote payload truncates it | Dictionaries for sparse data; validate field by field |
| SE-10 | Low | `wait()`, `spawn()`, `delay()` throttle and hide errors | `task.wait/spawn/delay/defer`; `check_repo.py` rejects the legacy globals |
| SE-11 | Medium | "Infinite yield possible" warnings ignored | Treat as a bug: missing instance or wrong Rojo path |
| SE-12 | Low | Luau string patterns are not regex (`%d`, no alternation) | Use `string.match` with Luau patterns, test them in Lune |

Extra edges seen often:
- NaN passes `<` and `>` checks: validate `x == x` first.
- `GetAsync` serves a 4 s cache: verify writes with `UseCache = false`.
- `PromptProductPurchaseFinished` is not a purchase confirmation; only the receipt handler is.
- Studio writes to production DataStores unless store names are scoped by environment.
