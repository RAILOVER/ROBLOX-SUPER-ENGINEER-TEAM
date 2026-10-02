# Gabarits de prompts BATTLEROT (v1.0)

Gabarits verrouilles par le Directeur artistique (03). Les Artistes 2D (07) et 3D (06) ne modifient que
les variables entre accolades; le reste du texte est fixe. Convention de variables du ticket T-0014:
`{slug}`, `{famille}`, `{rarete}`, `{palette}` (accolades, et non chevrons comme dans `TEMPLATE.md`;
la convention accolades s'applique a tous les gabarits BATTLEROT).

Phase P1: aucune image n'est generee ni commitee. Ces gabarits servent a partir de P2, apres validation
de la bible `art/style-bible/BATTLEROT.md` et des fiches `art/refs/<slug>/REFS.md`.

## Variables

| Variable | Valeur attendue | Source |
|----------|-----------------|--------|
| `{slug}` | slug exact du roster, ex: `tralalero-tralala` | `src/shared/Config/Roster/` |
| `{nom}` | nom affiche, ex: `Tralalero Tralala` | `src/shared/Config/Roster/` |
| `{famille}` | 1 famille parmi Mare, Cielo, Caffe, Giungla, Frutta, Macchina, Cosmo, Sahur, Tentafruit (la premiere listee si l'unite en a 2) | `src/shared/Config/Synergies.luau` |
| `{accent_famille}` | hex de l'accent de famille (bible 2.2), ex: `#2EC4F1` | bible 2.2 |
| `{rarete}` | Commune, Rare, Epique, Legendaire ou Champion | `src/shared/Config/Rarities.luau` |
| `{couleur_rarete}` | hex de la rarete (bible 2.1), `arc-en-ciel` pour Legendaire | `Rarities.luau` |
| `{palette}` | 10 hex de la palette maitresse separes par des espaces: `#1A1A2E #FFF8E7 #2E7CF6 #1B3F8F #FFC93C #F28C28 #3DDC5C #FF4D4D #A44CF2 #8FA6C1` | bible 2.1 |
| `{couleurs_perso}` | 2 a 4 hex de la fiche `REFS.md` | `art/refs/{slug}/REFS.md` |
| `{traits}` | les 3 a 4 traits signature de la fiche, separes par des virgules | `art/refs/{slug}/REFS.md` |
| `{pose}` | pose signature en 1 phrase | `art/refs/{slug}/REFS.md` |
| `{arene}` | nom de l'arene (bible section 6) | brief 15.5 |
| `{heure}` | lumiere de l'arene (bible section 6), ex: `midi, soleil franc` | bible section 6 |

Regles communes a tous les gabarits (bible sections 9 et 10):
- 4 generations minimum par prompt; on garde celle qui passe la grille V01 a V16, pas la plus jolie.
- Le verdict (`ACCEPTE` ou `REFUSE: Vxx`) est ecrit dans la PR avec le prompt rempli.
- Aucune image generee n'est commitee avant la phase P2 et un ticket d'asset valide.

## Gabarit 1: portrait de carte

Sortie: 768 x 1024 px (ratio 3:4), fond uni couleur `{accent_famille}`, personnage occupant 80 % de la
hauteur, vue de 3/4, regard vers la camera. Le cadre de rarete, le cout, les icones et le texte sont
ajoutes par l'UI (bible section 7), jamais dans l'image.

```
portrait de carte de {nom} ({slug}), personnage BATTLEROT, famille {famille}, rarete {rarete},
style jouet cartoon low poly stylise, formes rondes, 8 volumes maximum, couleurs plates,
ombrage en 2 tons, contour fonce #1A1A2E, grands yeux ronds,
traits signature exageres de 20 a 30 %: {traits},
pose signature: {pose},
couleurs du personnage {couleurs_perso}, palette {palette}, 1 seul accent {accent_famille} sur le fond,
vue de 3/4, eclairage cartoon 3 points (principal, contre-jour, appoint), fond uni {accent_famille},
personnage centre occupant 80 % de la hauteur, silhouette lisible a 64 px,
pas de texte, pas de logo, pas de marque, pas de watermark, pas de cadre,
pas de photo realiste, pas de texture photo, pas de gore, pas de contenu suggestif, pas de symbole
religieux ou politique, pas de personne reelle, pas d'asset d'un jeu existant,
768x1024
```

Verification: V01 a V07, V12 a V14, V16. Test supplementaire: reduction a 64 x 85 px, au moins 3 des 4
traits de `{traits}` identifiables.

## Gabarit 2: oeuf

Sortie: 1024 x 1024 px, fond transparent, oeuf centre occupant 70 % de la hauteur, marge de 10 %.
L'oeuf porte la couleur de la famille et le halo de la meilleure rarete qu'il contient (brief 15.7).
3 etats de fissure sont produits avec le meme prompt en changeant `{fissure}` (0, 1, 2, 3).

```
oeuf de BATTLEROT, famille {famille}, meilleure rarete contenue {rarete},
style jouet cartoon low poly stylise, oeuf lisse et rond (hauteur = 1,3 x largeur), aretes biseautees,
coquille couleur {accent_famille} avec 1 motif plat (taches ou anneaux) en version assombrie de 25 %,
reflet peint 1 pastille #FFF8E7, contour fonce #1A1A2E,
halo couleur {couleur_rarete} autour de l'oeuf (aucun halo si Commune ou Rare),
etat de fissure {fissure} sur 3 (0 = intact, 3 = pret a eclore), fissures en zigzag epaisses,
4 couleurs plates maximum plus la couleur de rarete, palette {palette},
vue de 3/4 legerement en plongee, eclairage cartoon neutre, fond transparent, centre, marge 10 %,
lisible a 64 px,
pas de texte, pas de logo, pas de watermark, pas de photo realiste, pas de texture photo,
pas de gore, pas de contenu suggestif, pas de symbole religieux ou politique, pas d'asset d'un jeu existant,
1024x1024
```

Verification: V01 a V04, V09, V11, V12, V13, V16. Les 4 etats de fissure se distinguent entre eux a 64 px
(question au modele de vision: "quel etat de fissure, de 0 a 3 ?", 4 bonnes reponses sur 4).

## Gabarit 3: arene

Sortie: 1920 x 1080 px, concept de decor pour l'Artiste 3D (06) et le Level designer (08). Le plateau
de combat reste vide au centre (50 a 60 % de la largeur). Les unites ne sont pas dans l'image.

```
concept d'arene BATTLEROT "{arene}", decor cartoon low poly stylise, famille dominante {famille},
plateau de combat central vide et degage occupant 55 % de la largeur, camera de 3/4 inclinee de 32 degres,
decor en 3 plans: premier plan props detailles, second plan en 3 couleurs plates, fond en 2 couleurs,
saturation du decor reduite de 15 % derriere le plateau, aucun element au-dessus du plateau,
lumiere: {heure}, ombres douces, 2 effets maximum (bloom leger, saturation +15 %),
props signature de l'arene ronds et biseautes, 3 a 5 elements animes suggeres (vagues, palmiers, lanternes),
accent de famille {accent_famille} sur 15 % des pixels maximum, palette {palette},
pas de texte, pas de logo, pas de marque, pas de drapeau, pas de watermark,
pas de photo realiste, pas de texture photo, pas de gore, pas de contenu suggestif,
pas de symbole religieux ou politique, pas de personne reelle, pas d'asset d'un jeu existant,
1920x1080
```

Verification: V01, V03, V04, V11, V13, V14, V15, V16. Test supplementaire: un carre P10 `#8FA6C1` de
5 studs pose au centre du plateau garde un contraste L* >= 30 avec le decor derriere lui.

## Exemple rempli (non execute, pour lecture seule)

Gabarit 1 avec `{slug}` = `tralalero-tralala`, `{famille}` = `Mare`, `{rarete}` = `Champion`,
`{accent_famille}` = `#2EC4F1`, `{traits}` = `requin gris-bleu, 3 pattes en baskets bleues sans logo,
nageoire dorsale, gueule ouverte a dents arrondies`, `{pose}` = `course sur 3 pattes, nageoire au vent`.
Aucune image n'a ete generee a partir de cet exemple en P1.
