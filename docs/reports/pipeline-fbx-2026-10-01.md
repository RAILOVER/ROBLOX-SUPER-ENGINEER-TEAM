# Rapport pipeline bpy vers FBX sur 1 unite placeholder (2026-10-01, T-0016)

Role : Tech artist 3D. Objectif : prouver que la chaine `bpy -> .blend -> FBX -> rapport` tourne sans interface, sur
1 personnage placeholder (`tralalero-tralala`, requin a 3 pattes et 3 baskets, brief §7.2 et §17.1). Rien n'a ete
importe dans Roblox Studio : voir la section 6 et le ticket `tickets/backlog/T-0020-human-import-fbx-studio.md`.

## 1. Environnement

| Element | Valeur |
|---|---|
| Blender | 5.2.1 LTS (hash 9e2066aef7ef), `~/.local/blender/blender`, mode `-b` |
| Machine | Ubuntu, sans GPU dedie, rendu Workbench via le serveur X `:0` |
| Python | celui de Blender (aucun appel au Python systeme pour `bpy`) |
| Branche | `06-tech-artist-3d/T-0016-pipeline-bpy` depuis `devin/1790906273-battlerot-brief-m0` |

## 2. Commandes executees et durees

| Etape | Commande | Duree mesuree |
|---|---|---|
| Generation + export FBX + rendu | `blender -b --python tools/blender/gen_placeholder_unit.py -- --slug tralalero-tralala --out assets/meshes/source/ --preview` | 0.85 s au total (`/usr/bin/time`), dont 0.36 s de script |
| Gate meshes | `blender -b assets/meshes/source/tralalero-tralala.blend --python tools/blender/validate_mesh.py -- --budgets art/budgets/budgets.yaml --report assets/meshes/reports/tralalero-tralala.json` | 0.47 s, code de sortie 0 |
| Relecture du FBX | `blender -b --python tools/blender/inspect_fbx.py -- assets/meshes/export/tralalero-tralala/tralalero-tralala.fbx` | 0.62 s |
| Textures et UI | `python3 tools/check_textures.py` | 0 erreur |
| Coherence du depot | `python3 tools/check_repo.py` | 0 erreur |

Sans `--preview`, le script ne rend pas d'image (0 dependance au serveur X).

## 3. Fichiers produits

| Fichier | Taille | Commit |
|---|---|---|
| `tools/blender/gen_placeholder_unit.py` | script generateur (source de verite) | oui |
| `tools/blender/inspect_fbx.py` | relecture d'un FBX dans une scene vide | oui |
| `assets/meshes/source/tralalero-tralala.blend` | 98 953 octets (compresse par `save_as_mainfile(compress=True)`), sous la limite de 2 Mo | oui |
| `assets/meshes/export/tralalero-tralala/tralalero-tralala.fbx` | 94 412 octets | oui (`git add -f`, `.gitignore` exclut `*.fbx` par defaut) |
| `assets/meshes/export/tralalero-tralala/tralalero-tralala_preview.png` | 112 471 octets, 512 x 512, rendu 3/4 Workbench pour la DA | oui |
| `assets/meshes/reports/tralalero-tralala.json` | 524 octets, sortie de `validate_mesh.py` | oui (`git add -f`, `.gitignore` exclut `reports/*.json`) |

## 4. Mesures sur le mesh et le rig

| Mesure | Valeur | Contrainte |
|---|---|---|
| Nom du mesh | `CHAR_TralaleroTralala` | regex `naming.mesh_regex` de `budgets.yaml` |
| Triangles | 340 | budget CHAR 8 000, cible du ticket moins de 500 |
| Ngons | 0 | max 0 |
| Materiaux | 1 (`M_TralaleroTralala`, gris-bleu plat, roughness 0.8) | max 1 |
| UV | 1 calque, `smart_project(angle_limit=1.15, island_margin=0.02)`, 0 coordonnee hors 0-1 | requis |
| Dimensions (X, Y, Z) | 2.261 x 6.443 x 5.0 unites | 1 unite = 1 stud, hauteur 5 studs (voir section 5) |
| Origine | pieds a z = 0, location (0, 0, 0), rotation 0, scale 1 | transforms appliquees |
| Pieces assemblees | corps, tete, museau, 2 yeux, aileron dorsal, nageoire caudale, 3 pattes, 3 baskets avec semelle (20 primitives jointes) | traits signature : requin + 3 baskets |
| Armature | `RIG_TralaleroTralala`, 2 os : `Root` (0 a 1.6) puis `Body` (1.6 a 4.0), `Body` enfant de `Root` | 1 os racine + 1 os corps |
| Poids | sommets sous z = 1.6 (pattes, baskets) sur `Root`, le reste sur `Body`, poids 1.0 | |
| Actions | `Idle` 1 a 40 (40 images), `Attack` 1 a 24, `Hit` 1 a 20, 24 images par seconde | 3 actions, 20 a 40 images, 24 fps |

Verdict de `validate_mesh.py` :

```
[PASS  ] CHAR_TralaleroTralala                   340 tris  [2.261, 6.443, 5.0]
1/1 meshes valides. Rapport: assets/meshes/reports/tralalero-tralala.json
```

## 5. Export FBX et relecture

Reglages (`export_fbx` dans le script) : `axis_forward="-Z"`, `axis_up="Y"`, `apply_unit_scale=True`,
`apply_scale_options="FBX_SCALE_ALL"`, `bake_space_transform=False` (la doc Blender signale l'option comme cassee avec les
armatures), `object_types={ARMATURE, MESH}`, `add_leaf_bones=False`, `use_armature_deform_only=True`, `bake_anim=True`,
`bake_anim_use_all_actions=True`, `bake_anim_use_nla_strips=False`, `bake_anim_simplify_factor=0.0`, `embed_textures=False`.

Relecture du FBX dans une scene vide (`inspect_fbx.py`) :

| Element relu | Valeur |
|---|---|
| Mesh | `CHAR_TralaleroTralala`, 340 tris, 2.261 x 6.443 x 5.0, 1 materiau, 1 calque UV, groupes `Root` et `Body` |
| Armature | `RIG_TralaleroTralala`, os `Root`, `Body` |
| Prises d'animation | 3 : `RIG_TralaleroTralala|RIG_TralaleroTralala|Attack` (1 a 24), `...|Hit` (1 a 20), `...|Idle` (1 a 40) |
| Skinning | `Attack` image 12 : point le plus avance passe de y = -3.699 a -4.187 (avance de 0.49), sommet a z = 4.439 (inclinaison). `Hit` image 10 : recul a y = -3.493. `Idle` image 20 : sommet a z = 5.025 |

Echelle : le ticket demande 1 unite Blender = 1 stud et un personnage de 5 studs, c'est ce qui est modelise (hauteur 5.0).
`art/budgets/budgets.yaml` documente par ailleurs la convention 1 m = 3.571 studs pour les kits et props. Le gate ne
verifie pas l'echelle (seulement `max_dimension_m: 64`). Quelle convention Roblox applique a l'import (1 unite FBX = 1 stud,
ou conversion cm vers studs) n'est pas verifiee ici : c'est le point 1 de la checklist de T-0020.

Reproductibilite : 2 executions successives donnent 2 FBX de 94 412 octets qui different sur 1 732 octets (horodatage
et chemin du .blend dans l'en-tete FBX) et une relecture identique (340 tris, memes dimensions, memes boites englobantes
par action). Le `.blend` est regenere a chaque execution a partir du `.py`, conformement au ROLE.md.

## 6. Non verifie

- Import dans Roblox Studio (echelle en studs, axes, pivot, skinning, lecture des 3 animations, materiau) : aucun agent n'a
  Studio sur Linux. Ticket HUMAN_ACTION `T-0020`.
- Compatibilite du rig 2 os avec l'Animation Editor de Roblox (nommage des prises `Armature|Stack|Action` apres relecture
  Blender ; Roblox peut afficher un autre nom) : a lire dans Studio.
- Direction du regard : le personnage est modelise face a -Y Blender, ce qui doit donner -Z Roblox avec `axis_forward="-Z"`.
  Non verifie en moteur.
- Couleurs des traits signature (baskets bleues) : 1 seul materiau gris-bleu plat, conformement a `materials.max_per_mesh: 1`
  et a la regle greybox. Les couleurs viendront d'une texture atlas (hors perimetre).
- Aucun test de performance en jeu (1 seul mesh, 340 tris).
