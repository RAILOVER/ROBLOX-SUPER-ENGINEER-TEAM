---
id: T-0009
title: GDD v1 BATTLEROT et specs testables du duel minimal M1
role: 02-game-designer
phase: P1-greybox
status: backlog
type: spec
priority: P0
depends_on: [T-0006]
spec: design/brief/BATTLEROT.md
acceptance:
  - "design/gdd/BATTLEROT.md existe et renvoie au brief section par section (pas de copie), avec les decisions ouvertes listees"
  - "design/specs/M1-duel-minimal.md : 10 unites L0 choisies (slugs), 4 synergies, 1 combo, criteres chiffres (duree de duel 7 a 10 min, 8 a 11 manches)"
  - "design/specs/M1-combat-tour-par-tour.md : ordre d'initiative, 5 actions, 13 statuts, formules §11.5 ecrites comme pseudo-code testable"
  - "chaque critere de spec est formule 'le joueur ... en moins de N s' ou avec une valeur numerique"
  - "python3 tools/check_repo.py a 0 erreur"
---

## Contexte

Le brief §6 a §13 est la base. Le Game Designer ne recopie pas : il choisit le sous-ensemble M1 et ecrit ce que le QA pourra
mesurer. Les 10 unites M1 doivent permettre les 4 synergies et le combo C05 (couple Tentafruit) ou C01.

## Travail attendu

- `design/gdd/BATTLEROT.md` (index vivant).
- `design/specs/M1-duel-minimal.md`, `design/specs/M1-combat-tour-par-tour.md`.
- Mise a jour de `src/shared/Config/*` uniquement si une valeur du brief est incoherente (ticket d'impact sinon).

## Hors perimetre

Histoire (chapitres), oeufs, ranked, monetisation : M2+.

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

A remplir a la livraison.
