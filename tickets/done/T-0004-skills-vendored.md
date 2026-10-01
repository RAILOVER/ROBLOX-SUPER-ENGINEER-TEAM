---
id: T-0004
title: Bibliotheque .devin/skills avec licences verifiees
role: 01-producteur
phase: P0-preparation
status: done
type: spec
priority: P0
depends_on: []
acceptance:
  - "INDEX.md liste source et licence de chaque skill"
  - "aucun skill sans LICENSE upstream ou marque original"
---

## Contexte

Phase P0: preparation de l'equipe avant toute creation de jeu. Ticket retroactif documentant ce qui a ete livre.

## Travail attendu

Bibliotheque .devin/skills avec licences verifiees.

## Hors perimetre

Tout contenu de jeu (genre, GDD, assets, greybox).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

Voir docs/reviews/P0-2026-10-01.md.
