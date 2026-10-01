---
id: T-0000
title: Titre court et actionnable
role: 04-dev-serveur
phase: P1-greybox
status: backlog
type: feature            # feature | bug | asset | spec | arbitrage | audit
priority: P1             # P0 bloquant, P1 important, P2 normal, P3 plus tard
depends_on: []           # liste d'ids
spec: design/specs/xxx.md   # spec testable d'origine, si applicable
acceptance:
  - "Critere 1 verifiable par script/test/capture"
  - "Critere 2 ..."
---

## Contexte

Pourquoi ce ticket existe, en 3 lignes maximum. Lien vers la spec ou le rapport d'origine.

## Travail attendu

Liste concrete de ce qui doit etre produit (fichiers, modules, assets).

## Hors perimetre

Ce que ce ticket ne fait PAS, pour eviter la derive.

## Verification

Commandes a executer et resultat attendu. Exemple:

```bash
tools/lint.sh                      # 0 erreur
python3 tools/check_repo.py        # 0 erreur
```

## Non verifie

A remplir par l'agent a la livraison: ce qui n'a pas pu etre teste et pourquoi.
