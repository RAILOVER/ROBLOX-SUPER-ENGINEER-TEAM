---
id: T-0015
title: Harnais de simulation QA (10 000 duels) et revue de CombatSim
role: 09-qa-reviewer
phase: P1-greybox
status: review
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

## Livre

- `tests/sim/run_duels.luau` (+ `Loader.luau`, `Teams.luau`, `Stats.luau`) : `lune run tests/sim/run_duels.luau [N] [seed] [--m1] [--out=...]`,
  paires jouees dans les 2 sens, blocs miroir et tactiques, CSV + resume Markdown. Echantillon
  `tests/sim/out/duels-sample-1000-m1.csv` ; le reste de `tests/sim/out/` est ignore par git.
- `docs/reports/balance-M1-2026-10-02.md` : 2 passes de 14 000 combats (M1 et L0), 0 erreur.
- `docs/reviews/T-0010.md` : verdict VALIDE, 3 FIX non bloquants regroupes dans T-0027.
- `tests/unit/CombatEdgeCases.spec.luau` : 12 tests de cas limites.
- Tickets ouverts : T-0025 (rythme : duree, nuls, Mega), T-0026 (fenetres L0), T-0027 (robustesse des entrees,
  04-dev-serveur). Tactiques et competences M1 : chiffres ajoutes a T-0024 et T-0023 via la PR, pas de doublon.

## Hors perimetre

Tests d'exploit des remotes (ticket apres T-0011), perf mobile (M2).

## Verification

```bash
lune run tests/sim/run_duels.luau 10000 20261002
lune run tests/sim/run_duels.luau 10000 20261002 --m1
lune run tests/run.luau
python3 tools/check_repo.py
tools/lint.sh
```

## Non verifie

- Roblox Studio : aucun test TestEZ ni rendu possible sous Linux ; le determinisme Lune contre Roblox (`Random`)
  reste a confirmer dans Studio avec `CombatDeterminism.spec.luau`.
- Duree animee : M-C-04 est estimee (`actions x 0,8 s + 2,5 s par Mega`), pas mesuree sur un client.
- Equipes construites par des joueurs (synergies visees) : le harnais tire des equipes aleatoires.
- Perf mobile et exploits des remotes : hors perimetre.
