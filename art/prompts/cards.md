# Gabarits de prompts 2D : cartes (cadres, fonds de famille, dos)

Role : 07-artiste-2d. Ticket T-0018. Source : brief §7.1, §15.2, §15.4, §18.2. Valeurs chiffrees : `src/shared/Config/Rarities.luau`,
`src/shared/Config/Roster/`. Formats : `art/budgets/budgets.yaml` > textures (puissance de 2, 1024 px max, PNG), verifies par
`python3 tools/check_textures.py`.

Statut : gabarits P1 (greybox). Aucune image generee en P1. Generation en M2 seulement, apres verdict du Directeur artistique
sur le gabarit. **A aligner sur la bible** `art/style-bible/BATTLEROT.md` (T-0014) des qu'elle est livree : la variable
`{palette}` prend alors les hex de la bible, et la ligne STYLE est remplacee par la phrase de direction de la bible.

## Regle de base : les portraits ne sont pas generes en 2D

Brief §5 (Agent 7) et §15.4 : le portrait du personnage est **rendu depuis Blender** par 06-tech-artist-3d (vue de 3/4,
eclairage cartoon). L'Artiste 2D produit tout ce qui est autour : cadre de rarete, fond de famille, dos de carte. Un prompt
de ce fichier ne contient donc jamais la description d'un personnage.

## Variables

| Variable | Valeurs possibles | D'ou elle vient |
|---|---|---|
| `{slug}` | slug du Roster (ex : `tim-cheese`, `fraisio`) | cles de `src/shared/Config/Roster/L0*.luau` |
| `{famille}` | Mare, Cielo, Caffe, Giungla, Frutta, Macchina, Cosmo, Sahur, Tentafruit | `families[1]` de l'unite (1re famille si 2) |
| `{rarete}` | Commune, Rare, Epique, Legendaire, Champion | `rarity` de l'unite, ordre dans `Rarities.order` |
| `{palette}` | 3 a 5 hex, dans l'ordre : couleur de rarete, accent de famille, creme `#FFF8E7`, contour `#1A1A2E` | tableau ci-dessous, puis bible |

Valeurs provisoires de `{palette}` (brief §15.2 et `Rarities.luau`), a remplacer par la bible :

| Rarete | Hex | Forme d'icone (`Rarities.icon`) | Famille | Accent |
|---|---|---|---|---|
| Commune | `#8FA6C1` | circle (rond) | Mare | `#2EC4F1` |
| Rare | `#F28C28` | diamond (losange) | Cielo | `#8EC5FF` |
| Epique | `#A44CF2` | star (etoile) | Caffe | `#8B5A3C` |
| Legendaire | `RAINBOW` (degrade anime, voir note) | hexagon (hexagone) | Giungla | `#3CB44B` |
| Champion | `#FFC93C` | crown (couronne) | Frutta | `#FF5E7E` |
| | | | Macchina | `#8A9AA9` |
| | | | Cosmo | `#6C3CE0` |
| | | | Sahur | `#FF9F43` |
| | | | Tentafruit | `#FF7AC6` |

Note Legendaire : le degrade arc-en-ciel est anime par le client (UIGradient + rotation), pas peint dans l'image. Le cadre
Legendaire est genere en **blanc neutre** `#FFFFFF` avec le contour `#1A1A2E`, et le client applique la teinte.

## Lignes communes a tous les gabarits (ne pas modifier hors variables)

```
[STYLE]     : cartoon mobile game UI, thick rounded shapes, bold dark outline #1A1A2E, saturated colors,
              soft 2-tone shading, glossy highlights, playful, high readability at small size
[NEGATIFS]  : no text, no letters, no numbers, no logo, no watermark, no Clash Royale logo or card frame,
              no Supercell or Riot asset, no real person, no realistic photo, no gore, no suggestive content
```

## Gabarit C1 : cadre de rarete

Fichier futur : `assets/ui/ui_card_frame_{rarete}.png` (5 fichiers). Format : **512 x 1024 px**, fond transparent, fenetre
portrait transparente de 448 x 448 px centree en haut (marge 32 px), bandeau bas de 1024 - 32 - 448 = 544 px pour les
icones de familles et de classe, la barre de niveau et la barre d'exemplaires (toutes ajoutees par le client, jamais peintes).

```
[SUJET]        : empty trading card frame for rarity {rarete}, ornament shape = {forme de Rarities.icon} repeated on the
                 4 corners, bevelled border 24 px, small badge zone top-left (empty circle 96 px) for the gold cost
[STYLE]        : (ligne commune)
[PALETTE]      : {palette}
[COMPOSITION]  : centered, portrait window fully transparent 448x448 at top with 32 px margin, lower band plain
                 and flat for UI overlays, symmetrical
[FOND]         : transparent
[NEGATIFS]     : (ligne commune)
[FORMAT]       : 512x1024 png
```

Exemple rempli (unite L0 `tim-cheese`, Tim Cheese, Commune, Giungla) :

```
[SUJET]        : empty trading card frame for rarity Commune, ornament shape = circle repeated on the 4 corners,
                 bevelled border 24 px, small badge zone top-left (empty circle 96 px) for the gold cost
[PALETTE]      : #8FA6C1 #3CB44B #FFF8E7 #1A1A2E
[COMPOSITION]  : centered, portrait window fully transparent 448x448 at top with 32 px margin, lower band plain
                 and flat for UI overlays, symmetrical
[FOND]         : transparent
[FORMAT]       : 512x1024 png
```

Le meme cadre Commune sert aux 11 Communes du lot L0 : le cadre depend de `{rarete}`, pas de `{slug}`.

## Gabarit C2 : fond de famille (derriere le portrait)

Fichier futur : `assets/ui/ui_card_bg_{famille}.png` (9 fichiers). Format : **512 x 512 px**, opaque. Place sous le rendu
Blender du portrait. Regle brief §15.5 appliquee a la carte : saturation reduite de 15 % et contraste faible pour que le
portrait reste lisible a 64 px (voir `docs/reports/legibilite-64px.md`).

```
[SUJET]        : soft background pattern for the {famille} family: {motif de famille, tableau ci-dessous}, 3 to 5 large
                 shapes maximum, no small detail under 32 px
[STYLE]        : (ligne commune) + low contrast, desaturated by 15 %, radial vignette lighter at center
[PALETTE]      : {palette} (accent de famille dominant, 80 % des pixels)
[COMPOSITION]  : centered, empty lighter zone of 256x256 at center for the character
[FOND]         : plain, opaque
[NEGATIFS]     : (ligne commune) + no character, no face, no silhouette
[FORMAT]       : 512x512 png
```

| Famille | Motif |
|---|---|
| Mare | vagues et bulles |
| Cielo | nuages et trainees de condensation |
| Caffe | mousse de lait et grains de cafe |
| Giungla | feuilles larges et lianes |
| Frutta | tranches de fruits stylisees |
| Macchina | engrenages et rivets arrondis |
| Cosmo | anneaux de planete et etoiles |
| Sahur | lanternes et ciel d'aube bleu-violet vers orange |
| Tentafruit | coeurs, projecteurs de plateau, guirlandes |

Exemple rempli (`tim-cheese`, famille Giungla) :

```
[SUJET]        : soft background pattern for the Giungla family: large leaves and vines, 3 to 5 large shapes
                 maximum, no small detail under 32 px
[PALETTE]      : #3CB44B #8FA6C1 #FFF8E7 #1A1A2E (green dominant, 80 % of pixels)
[COMPOSITION]  : centered, empty lighter zone of 256x256 at center for the character
[FOND]         : plain, opaque
[FORMAT]       : 512x512 png
```

## Gabarit C3 : dos de carte

Fichier futur : `assets/ui/ui_card_back_default.png` (1 fichier en M2, variantes cosmetiques plus tard, brief §13.6).
Format : **512 x 1024 px**, opaque.

```
[SUJET]        : back of a trading card, one big abstract egg shape at center surrounded by 4 to 6 fruit and wave
                 shapes, bevelled border 24 px
[STYLE]        : (ligne commune)
[PALETTE]      : #2E7CF6 #1B3F8F #FFC93C #FFF8E7 #1A1A2E (bleu UI dominant)
[COMPOSITION]  : centered, symmetrical, pattern readable at 64 px wide
[FOND]         : plain, opaque
[NEGATIFS]     : (ligne commune) + no character
[FORMAT]       : 512x1024 png
```

Exemple rempli : identique au gabarit (aucune variable d'unite : le dos est commun a tout le lot L0).

## Formats cibles

| Element | Fichier | Taille | Fond | Nombre M2 |
|---|---|---|---|---|
| Cadre de rarete | `ui_card_frame_{rarete}.png` | 512 x 1024 | transparent | 5 |
| Fond de famille | `ui_card_bg_{famille}.png` | 512 x 512 | opaque | 9 |
| Dos de carte | `ui_card_back_default.png` | 512 x 1024 | opaque | 1 |

Toutes les dimensions sont des puissances de 2 et <= 1024 (`budgets.yaml` > textures). `check_textures.py` accepte ces
noms dans `assets/ui/` (pas de prefixe `Icon_`, `Thumbnail_` ou `GameIcon_`, donc seule la taille max de 1024 est verifiee).

## Livraison M2 (par image)

1. 4 generations minimum, choisir celle qui passe la grille de la bible, pas la plus belle.
2. Fichier `.json` a cote : prompt complet, graine, modele, taille, date, ticket (brief §18.3).
3. Detourage alpha propre, verification de la fenetre transparente (448 x 448 pour C1).
4. `python3 tools/check_textures.py` = 0 erreur.
5. Test de lisibilite 64 px avec un portrait greybox dans le cadre (`docs/reports/legibilite-64px.md`).
6. Verdict du Directeur artistique dans la PR.
