---
id: T-0013
title: Arene greybox Spiaggia Tralala en Parts (script de construction)
role: 08-level-designer
phase: P1-greybox
status: review
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

- Rendu dans Roblox Studio (aucun Studio sur la VM Linux de l'agent) : cadrage reel des 3 cameras en paysage
  mobile, lisibilite bleu / orange a l'ecran, decor qui ne cache aucune case. HUMAN_ACTION : suivre la
  section "Ce que l'humain doit verifier dans Studio" de `design/levels/arena-01/README.md` et joindre une
  capture (emulateur 19.5:9 et 16:9) a la PR.
- `ArenaBuilder.build` (Instances Roblox : Part, SpawnLocation, Model.ModelStreamingMode) n'est pas execute
  sous Lune ; seuls lint, luau-lsp strict et les tests de la partie pure (`ArenaGeometry`) le couvrent. Le
  comptage de 82 Parts est calcule depuis le layout, pas mesure dans Studio.
- Comportement StreamingEnabled en conditions reelles (Model Persistent) : a verifier sur un vrai appareil
  mobile, pas seulement dans l'emulateur Studio.
