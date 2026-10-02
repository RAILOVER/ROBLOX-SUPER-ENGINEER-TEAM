# Gabarits de prompts 2D : icones

Role : 07-artiste-2d. Ticket T-0018. Source : brief §8, §11.3, §11.6, §13.1, §15.2, §18.1. Valeurs chiffrees :
`src/shared/Config/Rarities.luau` (`icon` = forme), `src/shared/Config/Synergies.luau` (familles, classes, sous-roles),
`src/shared/Config/Combat.luau` (`statuses`, 13 statuts). Formats : `art/budgets/budgets.yaml` > textures
(`icon_sizes_px: [512]`), verifies par `python3 tools/check_textures.py`.

Statut : gabarits P1 (greybox). Aucune image generee en P1. **A aligner sur la bible** `art/style-bible/BATTLEROT.md` (T-0014)
des qu'elle est livree : `{palette}` prend les hex de la bible.

## Variables

| Variable | Valeurs possibles | D'ou elle vient |
|---|---|---|
| `{slug}` | identifiant anglais de l'icone, en CamelCase dans le nom de fichier (ex : `FamilyGiungla`, `StatusBrulure`) | tableau d'inventaire ci-dessous |
| `{famille}` | Mare, Cielo, Caffe, Giungla, Frutta, Macchina, Cosmo, Sahur, Tentafruit, ou `none` | `Synergies` de kind `family` |
| `{rarete}` | Commune, Rare, Epique, Legendaire, Champion, ou `none` | `Rarities.order` |
| `{palette}` | 2 a 3 hex : couleur dominante (90 % de l'icone), 1 accent, contour `#1A1A2E` | tableau par categorie, puis bible |

Regle d'une icone : **1 couleur dominante, 1 accent, 1 contour**. Pas de degrade, pas d'ombre portee. Elle est lue a 32 px dans
le panneau de synergies et a 24 px au-dessus des tetes (statuts) : la silhouette fait tout le travail.

## Inventaire (brief §18.1) et nommage

Fichier : `assets/ui/Icon_{slug}.png`, **512 x 512 px** carre, transparent (impose par `check_textures.py` pour le prefixe
`Icon_`). Le client la reduit (ImageLabel ScaleType Fit).

| Categorie | Nombre | `{slug}` | `{palette}` dominante | Source du nom |
|---|---|---|---|---|
| Familles | 9 | `FamilyMare`, `FamilyCielo`, `FamilyCaffe`, `FamilyGiungla`, `FamilyFrutta`, `FamilyMacchina`, `FamilyCosmo`, `FamilySahur`, `FamilyTentafruit` | accent de famille (brief §15.2) | `Synergies` kind family |
| Sous-roles Tentafruit | 3 | `SubroleCouple`, `SubroleTentation`, `SubrolePresentatrice` | `#FF7AC6` | `Synergies` kind subrole |
| Classes | 7 | `ClassColosse`, `ClassGuerrier`, `ClassAssassin`, `ClassArtilleur`, `ClassSoigneur`, `ClassMage`, `ClassSprinteur` | `#FFF8E7` sur contour | `Synergies` kind class |
| Raretes | 5 | `RarityCommune`, `RarityRare`, `RarityEpique`, `RarityLegendaire`, `RarityChampion` | couleur de rarete (`Rarities.color`) | `Rarities` |
| Monnaies et ressources | 6 + 2 | `CurrencyGold`, `CurrencyGem`, `CurrencyEnergy`, `CurrencyCrown`, `CurrencyTrophy`, `CurrencyLeaguePoint`, puis `ResourceWildcard`, `ResourceCoachXp` | or `#FFC93C`, gemme `#A44CF2`, energie `#3DDC5C`, couronne `#FFC93C`, trophee `#FF8A00`, ligue `#2E7CF6` | brief §13.1 |
| Statuts | 13 | `StatusEtourdi`, `StatusEndormi`, `StatusCharme`, `StatusHorsCombat`, `StatusRalenti`, `StatusEnracine`, `StatusBrulure`, `StatusSaignement`, `StatusExpose`, `StatusBouclier`, `StatusProvocation`, `StatusInvisible`, `StatusEpines` | controle `#A44CF2`, debuff `#FF4D4D`, dot `#FF8A00`, buff `#2E7CF6` (`kind` de `Combat.statuses`) | `Combat.statuses` |
| Actions de combat | 5 + 1 | `ActionAttack`, `ActionSkill`, `ActionGuard`, `ActionDuo`, `ActionMegaCombo`, `ActionTactic` (prereglage §11.7) | `#FFF8E7` sur contour | brief §11.3 (5) ; la 6e de §18.1 est le prereglage tactique, a confirmer par 02-game-designer |
| Onglets | 5 | `TabBattle`, `TabCollection`, `TabShop`, `TabStory`, `TabRanked` | `#FFF8E7` sur contour | brief §15.6 ; liste a confirmer par 02-game-designer |

Total M3 : 9 + 3 + 7 + 5 + 8 + 13 + 6 + 5 = 56 icones. M2 (duel minimal + Arene 1) : les 4 familles et classes des 10 unites M1,
5 raretes, `CurrencyGold`, les statuts et actions utilises par les 10 unites, soit 25 a 30 icones selon
`design/specs/M1-duel-minimal.md` (T-0009).

## Symboles imposes (silhouette unique par icone, aucune icone ne doit se confondre avec une autre a 32 px)

| Icone | Symbole |
|---|---|
| FamilyMare | 1 vague |
| FamilyCielo | 1 nuage avec 2 ailes |
| FamilyCaffe | 1 tasse vue de cote avec 1 volute de vapeur |
| FamilyGiungla | 1 feuille large |
| FamilyFrutta | 1 tranche d'agrume |
| FamilyMacchina | 1 engrenage a 6 dents |
| FamilyCosmo | 1 planete avec 1 anneau |
| FamilySahur | 1 tambour vu de face |
| FamilyTentafruit | 1 coeur avec 1 petite etoile |
| SubroleCouple | 2 coeurs lies |
| SubroleTentation | 1 oeil qui cligne |
| SubrolePresentatrice | 1 micro |
| RarityCommune a RarityChampion | la forme de `Rarities.icon` : rond, losange, etoile 5 branches, hexagone, couronne 3 pointes |
| ClassColosse | 1 bouclier large |
| ClassGuerrier | 1 epee |
| ClassAssassin | 1 dague et 1 trainee |
| ClassArtilleur | 1 bombe cartoon a meche |
| ClassSoigneur | 1 croix arrondie dans 1 cercle |
| ClassMage | 1 baguette avec 1 etoile |
| ClassSprinteur | 1 chaussure avec 2 traits de vitesse |
| Statuts de controle | Etourdi 3 etoiles en cercle, Endormi 1 Z, Charme 1 coeur barre, HorsCombat 1 porte ouverte |
| Statuts de debuff et dot | Ralenti 1 escargot, Enracine 2 racines, Brulure 1 flamme, Saignement 1 goutte, Expose 1 cible |
| Statuts de buff | Bouclier 1 bouclier, Provocation 1 point d'exclamation dans 1 bulle, Invisible 1 oeil barre, Epines 3 pointes |
| Actions | Attack 1 epee, Skill 1 etoile 4 branches, Guard 1 bouclier, Duo 2 cercles lies, MegaCombo 1 eclair dans 1 etoile, Tactic 1 curseur a 3 positions |
| Monnaies | Gold 1 piece, Gem 1 gemme taillee, Energy 1 eclair, Crown 1 couronne pleine, Trophy 1 coupe, LeaguePoint 1 chevron, Wildcard 1 carte avec 1 etoile, CoachXp 1 sifflet |

Un chiffre ou une lettre n'est jamais dessine dans l'icone (le "Z" d'Endormi est un symbole de BD, pas un texte : a valider
par le Directeur artistique, sinon remplacer par 1 bulle de sommeil).

## Lignes communes (ne pas modifier hors variables)

```
[STYLE]     : flat cartoon game icon, thick rounded shapes, bold dark outline #1A1A2E, saturated colors,
              soft 2-tone shading, 1 glossy highlight, high readability at small size
[NEGATIFS]  : no text, no letters, no numbers, no logo, no watermark, no Clash Royale icon, no Supercell or Riot
              asset, no real person, no realistic photo, no gore, no suggestive content, no drop shadow
```

## Gabarit I1 : icone de synergie (famille, sous-role, classe)

```
[SUJET]        : flat icon of {symbole impose} for the {famille} family (or class / subrole), single symbol
[STYLE]        : (ligne commune)
[PALETTE]      : {palette}
[COMPOSITION]  : centered, 10 % margin, silhouette readable at 64 px, fills 80 % of the canvas
[FOND]         : transparent
[NEGATIFS]     : (ligne commune) + no character, no face
[FORMAT]       : 512x512 png
```

Exemple rempli (unite L0 `tim-cheese`, famille Giungla, classe Sprinteur, rarete Commune : ses 3 icones de carte) :

```
Icon_FamilyGiungla.png
[SUJET]        : flat icon of one large leaf for the Giungla family, single symbol
[PALETTE]      : #3CB44B #9BE88C #1A1A2E
[COMPOSITION]  : centered, 10 % margin, silhouette readable at 64 px, fills 80 % of the canvas
[FOND]         : transparent
[FORMAT]       : 512x512 png

Icon_ClassSprinteur.png
[SUJET]        : flat icon of one shoe with 2 speed lines for the Sprinteur class, single symbol
[PALETTE]      : #FFF8E7 #2E7CF6 #1A1A2E
[COMPOSITION]  : centered, 10 % margin, silhouette readable at 64 px, fills 80 % of the canvas
[FOND]         : transparent
[FORMAT]       : 512x512 png
```

## Gabarit I2 : icone de rarete

```
[SUJET]        : flat icon of one {forme de Rarities.icon} shape for the {rarete} rarity, single symbol
[STYLE]        : (ligne commune)
[PALETTE]      : {palette}
[COMPOSITION]  : centered, 10 % margin, fills 80 % of the canvas, symmetrical
[FOND]         : transparent
[NEGATIFS]     : (ligne commune)
[FORMAT]       : 512x512 png
```

Exemple rempli (`tim-cheese`, Commune) :

```
Icon_RarityCommune.png
[SUJET]        : flat icon of one circle shape for the Commune rarity, single symbol
[PALETTE]      : #8FA6C1 #FFFFFF #1A1A2E
[COMPOSITION]  : centered, 10 % margin, fills 80 % of the canvas, symmetrical
[FOND]         : transparent
[FORMAT]       : 512x512 png
```

Legendaire : icone generee blanche `#FFFFFF`, degrade arc-en-ciel applique par le client (meme regle que `cards.md`).

## Gabarit I3 : icone de statut, d'action, de monnaie ou d'onglet

```
[SUJET]        : flat icon of {symbole impose}, single symbol, {famille} = none, {rarete} = none
[STYLE]        : (ligne commune)
[PALETTE]      : {palette}
[COMPOSITION]  : centered, 10 % margin, fills 80 % of the canvas, readable at 24 px over a character head
[FOND]         : transparent
[NEGATIFS]     : (ligne commune) + no character
[FORMAT]       : 512x512 png
```

Exemple rempli (statut Brulure, applique par la competence de plusieurs unites L0 ; oeuf : voir `eggs.md` gabarit E3) :

```
Icon_StatusBrulure.png
[SUJET]        : flat icon of one cartoon flame, single symbol
[PALETTE]      : #FF8A00 #FFC93C #1A1A2E
[COMPOSITION]  : centered, 10 % margin, fills 80 % of the canvas, readable at 24 px over a character head
[FOND]         : transparent
[FORMAT]       : 512x512 png
```

## Formats cibles

| Element | Fichier | Taille | Fond | Nombre M3 |
|---|---|---|---|---|
| Toute icone | `assets/ui/Icon_{slug}.png` | 512 x 512 | transparent | 56 |

Une seule taille source : le client reduit. Aucune icone en 256 ou 128 dans le depot (`icon_sizes_px: [512]`).

## Livraison M2 (par icone)

1. 4 generations, choisir celle qui passe la grille de la bible.
2. `.json` a cote (prompt, graine, modele, taille, date, ticket).
3. Test de confusion a 32 px : planche de toutes les icones de la categorie reduites a 32 px, 5 lecteurs, chaque icone
   nommee par au moins 4 lecteurs sur 5 (meme protocole que `docs/reports/legibilite-64px.md`, taille 32 au lieu de 64).
4. `python3 tools/check_textures.py` = 0 erreur.
5. Verdict du Directeur artistique dans la PR.
