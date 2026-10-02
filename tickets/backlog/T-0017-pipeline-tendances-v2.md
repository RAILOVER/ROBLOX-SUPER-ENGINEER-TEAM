---
id: T-0017
title: Pipeline de tendances v2 (sources a cle optionnelles, rapport saisonnier)
role: 10-analyste-liveops
phase: P1-greybox
status: backlog
type: feature
priority: P2
depends_on: [T-0008]
spec: design/brief/BATTLEROT.md
acceptance:
  - "tools/trends/fetch_trends.py accepte --wiki-lang fr et une source supplementaire activee par variable d'environnement (YouTube ou Giphy), sans cle commitee"
  - "score de tendance ecrit dans le rapport (vues normalisees + multi-sources + recence) et documente"
  - "docs/reports/trends-<date>.md produit pour la saison suivante avec comparaison a la v1"
---

## Contexte

Brief §7.5. La v1 n'utilise que Wikipedia et Imgflip. Les sources a cle ne sont activees que si l'humain fournit une cle.

## Travail attendu

Voir acceptance.

## Hors perimetre

Toute modification de `src/shared/Config/Roster/`.

## Verification

```bash
python3 tools/trends/fetch_trends.py --years 2026 --days 30 --out /tmp/t.md
```

## Non verifie

A remplir a la livraison.
