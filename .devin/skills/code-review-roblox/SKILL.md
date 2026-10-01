---
name: code-review-roblox
description: Review workflow for Luau PRs in this repo: what to execute, what to read, how to phrase findings with a rule and a line, and when to block. Use for every PR in tickets/review.
sources: [original]
---

# Code review (Roblox / Luau)

## When to Load

Every time a PR moves a ticket to `tickets/review/`. The reviewer is `09-qa-reviewer`; authors may self-check with it before opening.

## Quick Reference

### 1. Execute before reading

```bash
git fetch && git checkout <branch>
python3 tools/check_repo.py && tools/lint.sh      # must be 0
# if assets changed:
python3 tools/check_textures.py
blender -b assets/meshes/source/<f>.blend --python tools/blender/validate_mesh.py -- --budgets art/budgets/budgets.yaml --report /tmp/r.json
```
A red script is a `CHANGEMENTS` verdict with the script output pasted; no further reading needed.

### 2. Read in this order

1. The ticket: `acceptance:` list. Each item must have a proof in the PR (output, test, screenshot).
2. The spec cited: each numbered rule must map to a test in `tests/`.
3. Remotes: run `agents/04-dev-serveur/checklists/remote.md` line by line.
4. Data: template version, migration, session lock, `BindToClose`, environment-scoped store name.
5. Client: no authority, bounded `WaitForChild`, connections cleaned, mobile screenshots present.
6. Shared: no secrets, no mutable authoritative state.

### 3. Write findings

Format: `file:line` + the rule broken (checklist item, spec rule, budget key) + what would pass.
Bad: "this looks unsafe". Good: "ShopService.luau:41 reads `price` from the remote argument; checklist remote.md item 5; read `Economy.items[itemId].price`".

Severity: **BLOCK** (security, data loss, failed script, missing test for a rule), **FIX** (DoD item missing), **NIT** (optional, never blocks).

### 4. Verdict

`APPROUVE` or `CHANGEMENTS`, followed by: what was executed, what was not verified (Studio, device, live DataStore), and the list of BLOCK/FIX items. Approval without execution is forbidden.
