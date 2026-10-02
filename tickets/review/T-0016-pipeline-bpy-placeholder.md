---
id: T-0016
title: Pipeline bpy de bout en bout sur 1 unite placeholder (export FBX + rapport)
role: 06-tech-artist-3d
phase: P1-greybox
status: review
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
blender -b --python tools/blender/gen_placeholder_unit.py -- --slug tralalero-tralala --out assets/meshes/source/ --preview
blender -b assets/meshes/source/tralalero-tralala.blend --python tools/blender/validate_mesh.py -- --budgets art/budgets/budgets.yaml --report assets/meshes/reports/tralalero-tralala.json
blender -b --python tools/blender/inspect_fbx.py -- assets/meshes/export/tralalero-tralala/tralalero-tralala.fbx
python3 tools/check_textures.py
python3 tools/check_repo.py
```

Resultats du 2026-10-01 : 340 tris, 0 ngon, 1 materiau, 2.261 x 6.443 x 5.0 unites, 2 os, 3 actions (40, 24, 20 images a
24 fps), `validate_mesh.py` 1/1 PASS, FBX de 94 412 octets relu avec les 3 prises. Detail dans
`docs/reports/pipeline-fbx-2026-10-01.md`.

## Non verifie

- Import dans Roblox Studio (echelle en studs, pivot, axes, skinning, lecture des animations, materiau) : aucun agent n'a
  Studio sur Linux. Ticket HUMAN_ACTION `T-0020` ouvert avec la checklist.
- Convention d'echelle appliquee par le 3D Importer de Roblox (1 unite FBX = 1 stud ou conversion depuis les cm) : le mesh
  est modelise a 1 unite = 1 stud, hauteur 5.0, mais la hauteur en studs n'est connue qu'apres import.
- Noms des prises d'animation tels que Studio les affiche (Blender relit `RIG_TralaleroTralala|RIG_TralaleroTralala|Idle`).
- Verdict du Directeur artistique sur le rendu 3/4 (`tralalero-tralala_preview.png`) : placeholder greybox, pas un asset.
