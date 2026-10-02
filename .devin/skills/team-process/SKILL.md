---
name: team-process
description: How this 10-agent team splits work into one-role tickets, runs phases with human gates, arbitrates conflicts, and reviews milestones. Use when creating tickets, changing phase, or resolving a conflict between roles.
sources: [original]
---

# Team process

## When to Load

Producer tasks: writing tickets, planning a phase, arbitrating, writing a milestone review. Other roles load it to understand what a well-formed ticket looks like.

## Quick Reference

### Ticket decomposition

- Start from a spec in `design/specs/`. No spec: first ticket goes to `02-game-designer`.
- One spec usually yields: server (04), client (05), tests (09). One asset yields: mesh (06) or texture (07), then integration (08), then visual verdict (03).
- Size: one agent session, one PR, under 400 changed lines. Split anything bigger.
- Write `acceptance:` before `Travail attendu`. Each item names its proof (script output, test name, screenshot, dashboard capture).
- `depends_on` must be `done` before a ticket moves to `in-progress`.

### Phase gates (see PROCESS.md)

P0 preparation -> P1 greybox -> P2 vertical slice -> P3 alpha -> P4 soft launch -> P5 live ops.
A gate opens only with a human playtest documented in `docs/reviews/<phase>-<date>.md` with numbers against the thresholds in `docs/playtest-humain.md`.

### Arbitration order

1. Player data integrity and security. 2. Existing testable spec. 3. Technical budget (`art/budgets/budgets.yaml`). 4. Style bible. 5. Lowest cost of change.
Decision is written in the `type: arbitrage` ticket with the rejected option and the reason.

### Milestone review template (`docs/reviews/`)

```
# <Phase> review <date>
Build: <commit>  Testers: <n> (<mobile n>)  Duration: <min>
Measures: continue@10min <x%> | first reward median <s> | Q1..Q5 means | fps mobile <n>
Verdict: PASS / FAIL vs thresholds
Decisions: phase change yes/no; tickets opened: T-xxxx ...
Not verified: ...
```

### Anti-patterns

- Tickets with two roles. Tickets without a proof per acceptance item. "Make it fun" tickets.
- Changing phase because the team is bored. Skipping the human playtest.
- Letting a script failure be argued away in a PR comment instead of fixing the asset or opening a budgets ticket.
