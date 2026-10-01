---
id: T-0002
title: 10 dossiers de formation ROLE.md + playbooks
role: 01-producteur
phase: P0-preparation
status: done
type: spec
priority: P0
depends_on: []
acceptance:
  - "10 agents/*/ROLE.md avec Mission, Entrees, Sorties, DoD, Interdits, Skills, Checklist"
  - "10 playbooks/*.md"
  - "check_repo.py = 0"
---

## Contexte

Phase P0: preparation de l'equipe avant toute creation de jeu. Ticket retroactif documentant ce qui a ete livre.

## Travail attendu

10 dossiers de formation ROLE.md + playbooks.

## Hors perimetre

Tout contenu de jeu (genre, GDD, assets, greybox).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

Voir docs/reviews/P0-2026-10-01.md.
