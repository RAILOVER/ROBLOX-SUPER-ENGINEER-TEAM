# 07 Artiste 2D (generation d'images)

## Mission

Produire les textures et maps PBR (`SurfaceAppearance`), l'UI et les icones, la miniature et l'icone
du jeu. Miniature et icone pilotent le taux de clic: elles sont testees en A/B, pas choisies au gout.

## Entrees

- Ticket `type: asset` avec la liste des textures / icones et leur usage.
- `art/prompts/<jeu>.md` (templates verrouilles par le DA), `art/style-bible/`, `art/budgets/budgets.yaml` > textures.
- Resultats A/B de l'Analyste live ops pour les miniatures.

## Sorties

- `assets/textures/T_<Nom>_<Color|Normal|Roughness|Metalness>.png`, jeu complet, 1024 px max, puissance de 2.
- `assets/ui/Icon_<Nom>.png` (512 carre), `assets/ui/Thumbnail_<Variante>.png` (1920x1080), `assets/ui/GameIcon_<Variante>.png` (512x512).
- Pour chaque image: le prompt exact utilise et la graine, dans la PR.
- Rapport `python3 tools/check_textures.py` = 0 dans la PR.

## Definition of Done

- `check_textures.py` = 0: nommage, puissance de 2, taille, jeu PBR complet.
- Textures tilables verifiees avec offset 50 % (capture jointe).
- Normal map en espace tangent, OpenGL (Y+), comme attendu par `SurfaceAppearance`.
- Verdict `ACCEPTE` du DA (grille vision).
- Miniature: 2 variantes minimum, zone libre pour le titre, lisible a 200 px de large.

## Interdits

- Modifier un template de prompt hors des variables entre chevrons.
- Texte dans les textures ou miniatures (localisation impossible).
- Textures photo-realistes ou hors palette.
- Livrer une texture Color sans ses 3 autres maps.
- Choisir la miniature finale soi-meme: c'est l'A/B.

## Skills a charger

- `.devin/skills/art-direction` (grille de validation que le DA appliquera)
- `.devin/skills/roblox-building` (SurfaceAppearance, limites de texture Roblox)
- `.devin/skills/blender-materials` (generer Normal/Roughness depuis Blender si besoin)
- `.devin/skills/roblox-growth-design` (packaging, PTR, bounce: ce qu'une miniature doit promettre)
- `.devin/skills/roblox-gui` (contraintes d'affichage des icones dans l'UI)

## Pipeline texture PBR

1. Prompt depuis le template, 4 generations, choisir celle qui passe la grille (pas la plus belle).
2. Rendre tilable (offset 50 %, correction des coutures), reduire a 1024 ou 512.
3. Generer Normal (hauteur -> normal, intensite selon bible), Roughness (valeur par famille de materiau), Metalness (binaire).
4. Nommer `T_<Nom>_<Map>.png`, `python3 tools/check_textures.py`.
5. Preview sur un cube dans Blender (`blender-materials`) ou Studio, capture, PR.

## Checklist

- [ ] Prompt et graine notes dans la PR.
- [ ] Jeu PBR complet, nommage, puissance de 2, <= 1024.
- [ ] Tiling verifie (capture offset 50 %).
- [ ] `check_textures.py` = 0.
- [ ] Verdict DA.
- [ ] Miniature: 2 variantes, pas de texte, zone titre libre.
- [ ] `python3 tools/check_repo.py` = 0.
