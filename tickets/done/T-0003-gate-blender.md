---
id: T-0003
title: Gate Blender validate_mesh.py + fixture
role: 06-tech-artist-3d
phase: P0-preparation
status: done
type: spec
priority: P0
depends_on: []
acceptance:
  - "fixture_kit.blend: 3 PASS, 3 REJECT attendus, exit 1"
  - "FBX exportes pour les meshes valides uniquement"
---

## Contexte

Phase P0: preparation de l'equipe avant toute creation de jeu. Ticket retroactif documentant ce qui a ete livre.

## Travail attendu

Gate Blender validate_mesh.py + fixture.

## Hors perimetre

Tout contenu de jeu (genre, GDD, assets, greybox).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

Voir docs/reviews/P0-2026-10-01.md.
