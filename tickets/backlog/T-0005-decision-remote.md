---
id: T-0005
title: Choisir le depot GitHub distant et le harnais de tests
role: 01-producteur
phase: P0-preparation
status: backlog
type: arbitrage
priority: P0
depends_on: []
acceptance:
  - "repo distant cree et accessible par Devin"
  - "runner de tests choisi (Jest Lua ou TestEZ), ticket T-0005 passe en done"
---

## Contexte

Phase P0: preparation de l'equipe avant toute creation de jeu. Ticket retroactif documentant ce qui a ete livre.

## Travail attendu

Choisir le depot GitHub distant et le harnais de tests.

## Hors perimetre

Tout contenu de jeu (genre, GDD, assets, greybox).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

Voir docs/reviews/P0-2026-10-01.md.
