---
id: T-0015
title: Harnais de simulation QA (10 000 duels) et revue de CombatSim
role: 09-qa-reviewer
phase: P1-greybox
status: in-progress
type: audit
priority: P0
depends_on: [T-0010]
spec: design/specs/M1-combat-tour-par-tour.md
acceptance:
  - "tests/sim/run_duels.luau : N duels aleatoires sous Lune, sortie CSV (seed, gagnant, actions, duree, synergies actives)"
  - "docs/reports/balance-M1-<date>.md : taux de victoire par unite et par synergie, duree moyenne, 0 erreur sur 10 000 duels"
  - "revue de code de T-0010 dans docs/reviews/T-0010.md : verdict VALIDE ou A CORRIGER avec liste numerotee"
  - "tout ecart au-dela des cibles du brief §19.3 (unite > 60 % ou < 40 % de victoires) ouvre un ticket pour le Game Designer"
---

## Contexte

R4 : celui qui produit ne valide pas. Le QA mesure, le Game Designer ajuste la config, l'humain juge le fun.

## Travail attendu

Voir acceptance.

## Hors perimetre

Tests d'exploit des remotes (ticket apres T-0011), perf mobile (M2).

## Verification

```bash
lune run tests/sim/run_duels.luau 10000
```

## Non verifie

A remplir a la livraison.
