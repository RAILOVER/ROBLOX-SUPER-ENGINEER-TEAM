---
id: T-0014
title: Bible de style BATTLEROT v1 et references des 10 unites M1
role: 03-directeur-artistique
phase: P1-greybox
status: backlog
type: spec
priority: P1
depends_on: [T-0009]
spec: design/brief/BATTLEROT.md
acceptance:
  - "art/style-bible/BATTLEROT.md : palette (10 couleurs max avec hex), proportions, niveau de detail, grille de validation vision avec seuils"
  - "art/refs/<slug>/REFS.md pour les 10 unites M1 : 3 liens de reference canonique + traits signature + note de moderation (R7)"
  - "art/prompts/ : gabarits portrait de carte, oeuf, arene, avec variables"
  - "aucune image generee ni asset final commite"
---

## Contexte

Brief §15 et R10. La bible precede tout asset; en greybox on ne produit que des documents.

## Travail attendu

Voir acceptance. Les liens de reference sont des URL publiques, pas des copies d'images dans le depot.

## Hors perimetre

Validation d'assets (aucun asset en M1).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

A remplir a la livraison.
