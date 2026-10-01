---
name: level-design-fundamentals
description: Flow, pacing, legibility, landmarks, and wordless guidance for modular-kit levels, with greybox-first steps and perf-aware assembly. Use when planning or assembling a zone.
sources: [original]
---

# Level design fundamentals

## When to Load

`08-level-designer` before planning a zone; `02` when writing a level spec; `09` when measuring a zone.

## Quick Reference

### Structure of a zone (Kishotenketsu)

1. **Intro, safe**: teach the one new element with no pressure (10 to 20 % of the path).
2. **Development**: combine it with known elements.
3. **Twist**: the element behaves differently or combines unexpectedly.
4. **Conclusion**: a payoff that uses everything, then a clean exit (sale point, checkpoint).

### Wordless guidance (the invisible hand)

- Light: brighter where the player should go; one accent color reserved for interactive things.
- Lines: edges of kit pieces, paths, railings all point to the next objective.
- Landmarks: one tall unique silhouette visible from most of the zone; never two that look alike.
- Rewards as breadcrumbs: coins or pickups along the intended route, denser near the twist.
- Negative space: dead ends are short, visible as dead ends from 10 m, and hold a small reward.

### Fairness

Deaths and failures must read as the player's fault: hazards telegraphed 1 s ahead, no off-screen damage, checkpoints every 60 to 90 s of play on mobile.

### Pacing numbers

| Metric | Target |
|--------|--------|
| Critical path time | spec value, measured in playtest, within 20 % |
| Time between rewards | under 30 s early, under 90 s later |
| Encounters / choices per minute | 1 to 3 |
| Spawn to first visible objective | under 3 s |

### Modular assembly

- Grid: kits snap on a 1 m / 2 m module (3.571 / 7.142 studs). Decide once in the asset sheet.
- Build the zone by code (Luau or bpy layout script) so it is versioned and reproducible.
- Count after each batch: parts visible, shadow lights, draw calls, against `budgets.yaml`.
- StreamingEnabled is on: anything the player must see from spawn lives inside the streaming radius or is a persistent model.

### Greybox first

Colors mean function (floor, wall, interactive, danger). Play the greybox with humans. Only after the flow passes the playtest, swap modules for kit pieces one batch at a time and re-measure.
