---
id: T-0013
title: Arene greybox Spiaggia Tralala en Parts (script de construction)
role: 08-level-designer
phase: P1-greybox
status: in-progress
type: feature
priority: P1
depends_on: [T-0009]
spec: design/brief/BATTLEROT.md
acceptance:
  - "src/server/World/ArenaBuilder.luau construit l'arene 1 en Parts : plateau 2x4 par camp, 3 plans de decor, zone camera, spawn"
  - "layout.json de l'arene (positions des cases, camera) dans design/levels/arena-01/ et lu par le builder"
  - "moins de 300 Parts, StreamingEnabled respecte, aucune texture"
  - "tools/lint.sh passe; python3 tools/check_repo.py passe"
---

## Contexte

Brief §15.5 et §17.6. En greybox, l'arene est generee par code (reproductible via Rojo) plutot que posee a la main dans
Studio, pour que les agents puissent la versionner.

## Travail attendu

- `src/server/World/ArenaBuilder.luau`, `design/levels/arena-01/layout.json`, note de flow et camera.

## Hors perimetre

Kit modulaire Blender, eclairage final, 7 autres arenes.

## Verification

```bash
tools/lint.sh
python3 tools/check_repo.py
```

## Non verifie

A remplir a la livraison (capture Studio = HUMAN_ACTION).
