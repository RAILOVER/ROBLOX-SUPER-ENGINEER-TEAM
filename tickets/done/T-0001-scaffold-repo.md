---
id: T-0001
title: Scaffold du repo d'equipe (Rojo, lint, budgets, tickets)
role: 01-producteur
phase: P0-preparation
status: done
type: spec
priority: P0
depends_on: []
acceptance:
  - "default.project.json lu par rojo sourcemap"
  - "tools/lint.sh = 0 sur src/"
  - "art/budgets/budgets.yaml lu par validate_mesh.py et check_textures.py"
---

## Contexte

Phase P0: preparation de l'equipe avant toute creation de jeu. Ticket retroactif documentant ce qui a ete livre.

## Travail attendu

Scaffold du repo d'equipe (Rojo, lint, budgets, tickets).

## Hors perimetre

Tout contenu de jeu (genre, GDD, assets, greybox).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

Voir docs/reviews/P0-2026-10-01.md.
