# Gabarits de prompts 2D : oeufs

Role : 07-artiste-2d. Ticket T-0018. Source : brief §13.2 a §13.4, §15.7 (storyboard d'ouverture), §18.1. Valeurs chiffrees :
`src/shared/Config/Eggs.luau` (6 oeufs configures : Bois, Argent, Or, Magique, Geant, Epique ; le cycle cite aussi Legendaire).
Formats : `art/budgets/budgets.yaml` > textures, verifies par `python3 tools/check_textures.py`.

Statut : gabarits P1 (greybox). Aucune image generee en P1. **A aligner sur la bible** `art/style-bible/BATTLEROT.md` (T-0014)
des qu'elle est livree : `{palette}` prend les hex de la bible.

## Variables

| Variable | Valeurs possibles | D'ou elle vient |
|---|---|---|
| `{slug}` | `bois`, `argent`, `or`, `magique`, `geant`, `epique`, `legendaire`, `champion`, `couronne`, `aventure` | cle de `Eggs.byName` en minuscules sans accent (brief §13.4 pour les 4 non configures) |
| `{famille}` | non utilise pour les oeufs | un oeuf n'a pas de famille ; la variable reste dans le gabarit pour l'outil de remplissage, valeur `none` |
| `{rarete}` | rarete garantie la plus haute de l'oeuf : Commune, Rare, Epique, Legendaire, Champion | `guarantees` de `Eggs.luau` (Bois et Argent : Commune) |
| `{palette}` | 3 a 4 hex : couleur de coquille, couleur de reflet, accent, contour `#1A1A2E` | tableau ci-dessous, puis bible |

Valeurs provisoires de `{palette}` et visuel (brief §13.4) :

| `{slug}` | `{rarete}` | Visuel du brief | Coquille | Reflet | Accent |
|---|---|---|---|---|---|
| bois | Commune | coquille en bois cartoon | `#B07A45` | `#D9A66B` | `#3CB44B` |
| argent | Commune | argente, reflets bleus | `#C9D3DE` | `#FFFFFF` | `#2EC4F1` |
| or | Rare | dore, brillant | `#FFC93C` | `#FFF1B8` | `#FF8A00` |
| magique | Epique | violet etoile, flotte et tourne | `#A44CF2` | `#D9B3FF` | `#FFC93C` |
| geant | Rare | enorme, deborde de l'ecran | `#FF8A00` | `#FFC93C` | `#FF4D4D` |
| epique | Epique | cristal violet | `#A44CF2` | `#FFFFFF` | `#6C3CE0` |
| legendaire | Legendaire | arc-en-ciel anime (teinte client, image blanche) | `#FFFFFF` | `#FFFFFF` | `#1A1A2E` |
| champion | Champion | or massif avec couronne | `#FFC93C` | `#FFF1B8` | `#1A1A2E` |
| couronne | Rare | bleu royal, couronne en relief | `#2E7CF6` | `#8EC5FF` | `#FFC93C` |
| aventure | Commune | vert feuillage | `#3CB44B` | `#9BE88C` | `#FFC93C` |

## Lignes communes (ne pas modifier hors variables)

```
[STYLE]     : cartoon mobile game UI, thick rounded shapes, bold dark outline #1A1A2E, saturated colors,
              soft 2-tone shading, glossy highlights, playful, high readability at small size
[NEGATIFS]  : no text, no letters, no numbers, no logo, no watermark, no Clash Royale chest or logo,
              no Supercell or Riot asset, no real person, no realistic photo, no gore, no suggestive content
```

## Gabarit E1 : oeuf entier (couveuse, boutique, info-bulle)

Fichier futur : `assets/ui/ui_egg_{slug}_idle.png`. Format : **512 x 512 px**, fond transparent. L'oeuf occupe 80 % de la
hauteur, pose sur une ombre plate. C'est l'image affichee dans les 4 couveuses (brief §13.2) et dans la boutique en gemmes
(§13.6), reduite jusqu'a 96 px : la silhouette doit rester un oeuf a 64 px.

```
[SUJET]        : one single cartoon egg, {visuel du brief}, shell material {slug}, 2 to 3 big highlight shapes,
                 1 flat shadow ellipse under the egg
[STYLE]        : (ligne commune)
[PALETTE]      : {palette}
[COMPOSITION]  : centered, egg height = 80 % of canvas, 10 % margin, 3/4 top view, symmetrical
[FOND]         : transparent
[NEGATIFS]     : (ligne commune) + no character, no face on the egg, no cracks (idle state)
[FORMAT]       : 512x512 png
```

Exemple rempli (`or`, Oeuf d'Or : 8 h d'eclosion, 36 cartes, 130 a 170 or, 1 Rare garantie, source cycle et defi du jour) :

```
[SUJET]        : one single cartoon egg, golden and shiny, shell material polished gold, 2 to 3 big highlight shapes,
                 1 flat shadow ellipse under the egg
[PALETTE]      : #FFC93C #FFF1B8 #FF8A00 #1A1A2E
[COMPOSITION]  : centered, egg height = 80 % of canvas, 10 % margin, 3/4 top view, symmetrical
[FOND]         : transparent
[FORMAT]       : 512x512 png
```

## Gabarit E2 : etats de la coquille (storyboard d'ouverture §15.7)

Fichier futur : `assets/ui/ui_egg_{slug}_sheet.png`. Format : **1024 x 1024 px**, planche **4 x 4** de 16 cases de 256 px,
compatible avec un ImageLabel anime par le client (ou un Flipbook ParticleEmitter 4x4). Ordre des cases : 1 a 4 oeuf qui
tremble (4 amplitudes), 5 a 8 fissures (4 niveaux), 9 a 12 eclatement (4 etapes), 13 a 16 fragments qui retombent.

```
[SUJET]        : sprite sheet of one cartoon egg, {visuel du brief}, 16 frames in a 4x4 grid: 4 frames shaking,
                 4 frames with growing cracks, 4 frames bursting open with light rays, 4 frames of falling shell
                 fragments, same egg, same camera, same scale in every frame
[STYLE]        : (ligne commune)
[PALETTE]      : {palette} + light rays #FFFFFF
[COMPOSITION]  : strict 4x4 grid, each cell 256x256, egg centered in each cell, 16 px inner margin per cell
[FOND]         : transparent
[NEGATIFS]     : (ligne commune) + no character, no card, no coin (the content is added by the client)
[FORMAT]       : 1024x1024 png
```

Exemple rempli (`or`) :

```
[SUJET]        : sprite sheet of one cartoon egg, golden and shiny, 16 frames in a 4x4 grid: 4 frames shaking,
                 4 frames with growing cracks, 4 frames bursting open with light rays, 4 frames of falling shell
                 fragments, same egg, same camera, same scale in every frame
[PALETTE]      : #FFC93C #FFF1B8 #FF8A00 #1A1A2E + light rays #FFFFFF
[COMPOSITION]  : strict 4x4 grid, each cell 256x256, egg centered in each cell, 16 px inner margin per cell
[FOND]         : transparent
[FORMAT]       : 1024x1024 png
```

Post-traitement obligatoire : verifier que chaque case est bien alignee sur la grille de 256 px (decoupe `convert -crop 4x4@`
puis controle visuel), sinon la planche est refusee : le Flipbook ne pardonne pas un decalage.

## Gabarit E3 : icone d'oeuf (liste du cycle, recapitulatif, quetes)

Fichier futur : `assets/ui/Icon_Egg{Slug}.png` (ex : `Icon_EggOr.png`). Format : **512 x 512 px** carre, transparent,
impose par `check_textures.py` pour le prefixe `Icon_` (`icon_sizes_px: [512]`). Marge 10 %, 1 seul reflet, contour epais :
l'icone est lue a 48 px dans la barre de progression du cycle d'oeufs.

```
[SUJET]        : flat icon of one cartoon egg, {visuel du brief}, 1 single highlight, thick outline
[STYLE]        : (ligne commune)
[PALETTE]      : {palette}
[COMPOSITION]  : centered, 10 % margin, silhouette readable at 64 px
[FOND]         : transparent
[NEGATIFS]     : (ligne commune) + no shadow, no cracks
[FORMAT]       : 512x512 png
```

Exemple rempli (`or`) :

```
[SUJET]        : flat icon of one cartoon egg, golden and shiny, 1 single highlight, thick outline
[PALETTE]      : #FFC93C #FFF1B8 #FF8A00 #1A1A2E
[COMPOSITION]  : centered, 10 % margin, silhouette readable at 64 px
[FOND]         : transparent
[FORMAT]       : 512x512 png
```

## Formats cibles

| Element | Fichier | Taille | Fond | Nombre M2 (Arene 1) | Nombre M3 |
|---|---|---|---|---|---|
| Oeuf entier | `ui_egg_{slug}_idle.png` | 512 x 512 | transparent | 3 (bois, argent, or) | 10 |
| Planche d'ouverture | `ui_egg_{slug}_sheet.png` | 1024 x 1024 (4 x 4 de 256) | transparent | 3 | 10 |
| Icone d'oeuf | `Icon_Egg{Slug}.png` | 512 x 512 | transparent | 3 | 10 |

Le compte M2 suit le jalon M2 du brief §21 (ouverture d'oeuf finale, Arene 1) : les oeufs du tutoriel et du debut de cycle.
Le reste arrive en M3 ("tous les oeufs").

## Regles specifiques aux oeufs

- Les probabilites par carte (Commune 76 %, Rare 20 %, Epique 3,6 %, Legendaire 0,35 %, Champion 0,05 %) sont affichees par
  un TextLabel (R8), jamais dans l'image.
- L'oeuf Legendaire est genere blanc : le client applique le degrade arc-en-ciel anime. Meme regle que le cadre Legendaire.
- L'oeuf Geant "deborde de l'ecran" par l'echelle du client (UIScale 1,6), pas par une image plus grande : il reste en 512.
- Livraison M2 par image : 4 generations, `.json` a cote (prompt, graine, modele, taille, date, ticket), `check_textures.py` = 0,
  verdict du Directeur artistique dans la PR.
