---
id: T-0018
title: Gabarits de prompts 2D (cartes, oeufs, icones) et grille de lisibilite 64 px
role: 07-artiste-2d
phase: P1-greybox
status: in-progress
type: spec
priority: P2
depends_on: [T-0014]
spec: design/brief/BATTLEROT.md
acceptance:
  - "art/prompts/cards.md, eggs.md, icons.md : gabarits avec variables {slug, famille, rarete, palette}"
  - "docs/reports/legibilite-64px.md : protocole de test de lisibilite (portrait reduit a 64 px, 5 lecteurs) a appliquer en M2"
  - "aucune image generee commitee en P1"
---

## Contexte

Brief §18 et pilier 3 (lisible en 64 px). En greybox, seulement des gabarits et des protocoles.

## Travail attendu

Voir acceptance.

## Hors perimetre

Generation d'images (M2).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

A remplir a la livraison.
