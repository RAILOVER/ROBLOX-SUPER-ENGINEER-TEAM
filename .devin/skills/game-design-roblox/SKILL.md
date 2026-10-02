---
name: game-design-roblox
description: Roblox-specific design heuristics for genre choice, first-session structure, session length, social fallbacks, and what the platform's audience rewards. Use when writing a GDD or a testable spec.
sources: [original, https://create.roblox.com/docs/production]
---

# Game design for Roblox

## When to Load

When drafting `design/gdd/` or a `design/specs/` file. Pair with `roblox-game-design` (structure), `roblox-player-psychology` (first minute, rewards) and `roblox-growth-design` (metrics).

## Quick Reference

### Genres that fit a code-generated low-poly pipeline

| Genre | Core loop | Why it fits | Watch out |
|-------|-----------|-------------|-----------|
| Simulator / incremental | collect, sell, upgrade | modular props, numbers-driven, economy-heavy | grind perception, needs strong juice |
| Tycoon | buy droppers, expand plot | kits of modular pieces, clear progression | solo by default, add social layer |
| Obby / platformer | run, jump, checkpoint | pure Parts, greybox is the final art | low monetization unless skips/skins |
| Tower defense / wave survival | place, upgrade, survive | grid-based kits, bot playtests easy | balancing cost, late-game perf |
| Minigames hub | short rounds, votes | each round is a small spec | needs 6+ players, matchmaking |

Avoid for this pipeline: organic character-driven games, realistic open worlds, anything needing hand-animated creatures.

### First session (mobile, one hand, 3 minutes)

- 0 to 10 s: the player is already doing the core verb. No menu, no text.
- Under 30 s: first reward, visible and audible (spec: median < 30 s, p90 < 60 s).
- Under 120 s: first choice (upgrade A or B) and first "return trigger" (something that grows while away).
- Under 10 min: a goal the player can name. Measure with a 10-minute "continue or stop" question in playtest.

### Sessions and retention

- Target session 8 to 15 minutes; design a clean exit point every 5 minutes (sale, checkpoint, wave end).
- D1 drivers: understood loop + stability + first payoff. D7 drivers: progression visibility + return triggers. D30: social comparison, events.
- Every multiplayer mechanic needs a 1-player fallback; servers are often half empty at launch.

### Spec writing rules

1. One observable behavior per spec, one number, one instrument (Funnel step, Custom event, server timer).
2. Edge cases always listed: leave, disconnect, cheat, AFK, mobile.
3. Numbers live in a table copied to `src/shared/Config/`; the server reads the same table.
4. Never specify art; specify function and legibility ("interactive objects read at 30 m").

### Economy guardrails

Every source has a sink; prices scale with the power curve; paid random items require `PolicyService` checks and a deterministic alternative; no fake scarcity.
