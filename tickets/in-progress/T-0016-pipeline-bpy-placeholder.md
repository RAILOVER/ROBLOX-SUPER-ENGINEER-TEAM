---
id: T-0016
title: Pipeline bpy de bout en bout sur 1 unite placeholder (export FBX + rapport)
role: 06-tech-artist-3d
phase: P1-greybox
status: in-progress
type: feature
priority: P1
depends_on: [T-0014]
spec: design/brief/BATTLEROT.md
acceptance:
  - "tools/blender/gen_placeholder_unit.py genere un personnage en primitives (corps, tete, 2 traits signature en formes simples) pour 1 slug, rig 1 os racine + 1 os corps, 3 animations (Idle, Attack, Hit)"
  - "export FBX dans assets/meshes/export/<slug>/ et rapport validate_mesh.py vert (budget CHAR 8000 tris, ici < 500)"
  - "docs/reports/pipeline-fbx-<date>.md : commande, duree, tailles, ce qui n'a pas ete verifie"
  - "ticket HUMAN_ACTION ouvert pour l'import dans Studio avec la checklist (echelle, pivot, animations)"
---

## Contexte

Brief §17 : le test d'import Blender vers Roblox est au M0, mais seul l'humain a Studio. L'agent prepare et prouve que la
chaine bpy -> FBX -> rapport tourne headless.

## Travail attendu

Voir acceptance. Executer avec Blender (`blender -b --python ...`), jamais avec le Python systeme.

## Hors perimetre

Modelisation finale, textures, Mega Combos.

## Verification

```bash
blender -b --python tools/blender/gen_placeholder_unit.py -- --slug tralalero-tralala
blender -b assets/meshes/source/tralalero-tralala.blend --python tools/blender/validate_mesh.py -- --budgets art/budgets/budgets.yaml --report assets/meshes/reports/tralalero-tralala.json
```

## Non verifie

A remplir a la livraison.
