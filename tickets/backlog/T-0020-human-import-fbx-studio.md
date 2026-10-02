---
id: T-0020
title: HUMAN_ACTION importer le FBX placeholder tralalero-tralala dans Studio et valider echelle, pivot, animations, materiau
role: 01-producteur
phase: P1-greybox
status: backlog
type: arbitrage
priority: P1
depends_on: [T-0016, T-0019]
spec: docs/reports/pipeline-fbx-2026-10-01.md
acceptance:
  - "FBX assets/meshes/export/tralalero-tralala/tralalero-tralala.fbx importe par le 3D Importer de Studio sans erreur (capture de la fenetre d'import)"
  - "hauteur mesuree dans Studio notee dans ce ticket : attendu 5 studs, tolerance 10 %, sinon le facteur a appliquer est note"
  - "les 3 animations (Idle, Attack, Hit) s'affichent dans l'Animation Editor et se lisent (capture ou valeur de duree lue)"
  - "reglages d'import retenus consignes dans docs/reports/pipeline-fbx-2026-10-01.md section 6, puis repris par le Tech artist 3D dans gen_placeholder_unit.py"
---

## Contexte

T-0016 a prouve la chaine `bpy -> FBX -> rapport` sans interface (`docs/reports/pipeline-fbx-2026-10-01.md`). Seul l'humain a
Roblox Studio : c'est le test d'import du brief §17.1 (echelle, axes, skinning, animation), qui verrouille les reglages
d'export avant toute production de personnages.

## Travail attendu (humain)

Checklist a cocher dans Studio, en notant chaque valeur mesuree :

1. Echelle : importer le FBX (Avatar ou Home, bouton Import 3D). Verifier la hauteur du MeshPart : attendu 5.0 studs
   (le FBX est modelise a 1 unite = 1 stud, 2.261 x 6.443 x 5.0). Si la hauteur lue vaut 500 ou 0.05, noter le facteur et
   le reglage "unite" du 3D Importer qui corrige.
2. Axes et pivot : les pieds doivent toucher le sol (pivot a z = 0 du mesh, origine du personnage) et le museau pointer vers
   le -Z du modele (face avant). Noter toute rotation de 90 degres a corriger.
3. Rig : l'import doit creer un Model avec 2 os (`Root`, `Body`) et un mesh skinne (`CHAR_TralaleroTralala`). Verifier
   que l'option "Rig type" ou "Rig scale" ne force pas un R15.
4. Animations : ouvrir l'Animation Editor, importer les animations du FBX. Attendu 3 prises (Idle 40 images, Attack 24,
   Hit 20, a 24 images par seconde, soit 1.67 s, 1.0 s, 0.83 s). Noter les noms affiches par Studio et si la lecture
   deforme le mesh (le corps s'incline, les baskets restent au sol).
5. Materiau : 1 seul SurfaceAppearance ou couleur de MeshPart (`M_TralaleroTralala`, gris-bleu). Aucune texture attendue.
6. Coller 2 captures dans ce ticket : fenetre d'import avec les reglages, Animation Editor avec les 3 prises.

## Hors perimetre

Modelisation finale, textures, Mega Combos, publication.

## Verification

Captures et valeurs collees dans ce ticket, puis `python3 tools/check_repo.py` (0 erreur) a la mise a jour de la doc.

## Non verifie

Sans objet (ticket humain).
