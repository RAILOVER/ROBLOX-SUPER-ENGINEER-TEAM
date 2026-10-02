# Protocole de test de lisibilite a 64 px (pilier 3)

Role : 07-artiste-2d. Ticket T-0018. Source : brief §1.2 pilier 3 ("lisible en 64 px sur un telephone"), §15.3 (silhouette en
noir pur, vignette de 64 px), fiche Agent 3 (methode de validation, etape 1). A appliquer en **M2** sur les portraits finaux des
16 unites de l'Arene 1 (11 Communes + 4 Rares + Tralalero Tralala, brief §21). En P1 et M1 : aucun portrait final, ce document
fixe seulement la mesure. Il peut etre repete en M1 sur les placeholders greybox pour roder la procedure, sans valeur de gate.

## 1. Ce qu'on mesure

| Mesure | Definition | Cible |
|---|---|---|
| Taux d'identification d'un portrait | lecteurs qui nomment la bonne unite / 5 lecteurs | **>= 80 %** (4 lecteurs sur 5) |
| Taux du lot | portraits qui atteignent 80 % / portraits testes | >= 80 % au 1er passage, 100 % apres correction |
| Temps de reponse median | temps entre la fin de l'exposition et la reponse | indicatif, pas de seuil |
| Confusions | pour chaque erreur, l'unite choisie a la place de la bonne | 0 paire confondue par 2 lecteurs ou plus |
| Silhouette (secondaire) | meme test avec le portrait en noir pur `#1A1A2E` sur creme `#FFF8E7` | indicatif, rapporte sans seuil en M2 |

Un portrait sous 80 % repart chez 03-directeur-artistique avec la matrice de confusion : la correction est chiffree ("yeux 20 %
plus grands", "contour +2 px"), jamais "fais mieux". Un portrait est teste au maximum 2 fois ; au 3e echec, c'est le brief de
stylisation de l'unite (`art/refs/<slug>/`) qui est revu, pas le portrait.

## 2. Conditions

- **5 lecteurs**, dont 3 sur telephone et 2 qui n'ont jamais vu le jeu (meme regle que `docs/playtest-humain.md`). Les agents ne
  sont pas lecteurs : un modele de vision peut faire un pre-test, il ne remplace pas la mesure.
- Affichage **64 x 64 px reels** (aucun zoom), sur fond `#FFF8E7`, dans le cadre `ui_timeline_slot_ally` si le kit UI existe
  (`art/prompts/ui-kit.md`), sinon sans cadre. Telephone tenu a environ 30 cm, luminosite 100 %.
- **Exposition 3 secondes**, puis la vignette est remplacee par un carre gris `#8A9AA9`.
- Reponse : le lecteur choisit dans la **liste des noms du lot teste** (16 noms en M2, ordre alphabetique fixe), 10 secondes
  maximum, 1 seule reponse, pas de retour en arriere. Niveau du hasard : 1 / 16 = 6 %.
- Ordre des portraits **tire au sort par lecteur** avec une graine notee dans le rapport (meme principe que le CombatSim :
  rejouable).
- Chaque lecteur voit chaque portrait **1 seule fois**. 16 portraits x 3 s + reponses = moins de 5 minutes par lecteur.
- Les 5 lecteurs voient les memes fichiers (meme commit, SHA note dans le rapport).

## 3. Preparation des vignettes (commandes executees sur des images de test, non commitees)

ImageMagick 6 est present sur la machine de preparation (`/usr/bin/convert`). Depuis un portrait source 512 x 512 :

```bash
# reduction a 64 px, filtre Lanczos (meme rendu que la reduction d'un ImageLabel en ScaleType Fit)
convert portrait_{slug}.png -filter Lanczos -resize 64x64 test_{slug}_64.png

# silhouette noir pur pour la mesure secondaire (garde l'alpha, remplit tout en #1A1A2E)
convert portrait_{slug}.png -fill "#1A1A2E" -colorize 100 -resize 64x64 test_{slug}_sil.png

# planche de controle pour le Directeur artistique (5 colonnes, fond creme, 16 px entre les vignettes)
montage test_*_64.png -tile 5x -geometry 64x64+16+16 -background "#FFF8E7" sheet_64.png
```

Verification faite sur 10 images de test generees (disques de couleur) : `identify` retourne `64x64` pour chaque vignette et
`480x192` pour la planche 5 x 2. Les vignettes servent au test sur telephone ; la planche sert a la revue DA, pas a la mesure.

Les vignettes et la planche vont dans un dossier hors depot ou dans la PR en piece jointe, jamais dans `assets/` (aucune image
generee commitee avant M2, et les vignettes de test ne sont pas des assets).

## 4. Deroule d'une session

1. Preparer les 16 vignettes 64 px et le fichier de reponses (modele section 5). Noter le SHA du commit des portraits.
2. Pour chaque lecteur : tirer l'ordre avec la graine, afficher chaque vignette 3 s, masquer, enregistrer la reponse et le temps.
3. Aucune aide, aucune relance. Si le lecteur ne repond pas en 10 s, la reponse est `aucune` (comptee fausse).
4. Repeter avec les 16 silhouettes (mesure secondaire), apres une pause de 2 minutes, meme ordre inverse.
5. Remplir le tableau de resultats et la matrice de confusion, calculer les taux, ecrire le verdict par portrait.

## 5. Modele de fichier de reponses (CSV, 1 ligne par exposition)

```
lecteur,appareil,graine,slug_affiche,slug_repondu,temps_s,mode
L1,android_bas_de_gamme,20261001,tim-cheese,tim-cheese,1.8,portrait
L1,android_bas_de_gamme,20261001,trippi-troppi,bananita-dolfinita,4.2,portrait
```

`mode` vaut `portrait` ou `silhouette`. Les slugs sont ceux de `src/shared/Config/Roster/`. Le fichier CSV est joint a la PR
du rapport M2 (`docs/reports/legibilite-64px-M2-<date>.md`), avec le SHA des portraits et la liste des lecteurs anonymisee.

## 6. Modele de tableau de resultats

| slug | Rarete | Identifie (sur 5) | Taux | Temps median (s) | Confondu avec | Silhouette (sur 5) | Verdict |
|---|---|---|---|---|---|---|---|
| tim-cheese | Commune | 5 | 100 % | 1.8 | : | 4 | ACCEPTE |
| trippi-troppi | Commune | 3 | 60 % | 3.1 | bananita-dolfinita x2 | 2 | A CORRIGER : ... |

Ligne de synthese : portraits testes, portraits >= 80 %, taux du lot, nombre de paires confondues par 2 lecteurs ou plus.

Les valeurs ci-dessus sont des exemples de format, pas des mesures : aucun portrait n'existe en P1.

## 7. Decision

| Resultat | Action |
|---|---|
| Portrait >= 80 %, 0 confusion repetee | ACCEPTE pour la lisibilite ; passe a la grille de la bible (coherence, traits signature, conformite) |
| Portrait < 80 % ou 1 paire confondue par 2 lecteurs ou plus | A CORRIGER : ticket pour 03-directeur-artistique et 06-tech-artist-3d avec la matrice de confusion et une correction chiffree |
| Lot < 80 % au 1er passage | la gate M2 "validation DA" ne peut pas etre franchie ; le Producteur ouvre un ticket par portrait en echec |
| Silhouette basse mais portrait >= 80 % | rapporte, pas bloquant en M2 ; devient un critere de la bible si le DA le decide |

## 8. Ce que ce protocole ne couvre pas

- La lisibilite des **icones** (32 px) et des **cadres** est testee avec le meme protocole en changeant la taille, voir
  `art/prompts/icons.md` section Livraison M2. Elle n'est pas comptee dans le taux du lot.
- La lisibilite **en mouvement** (combat, timeline qui defile) n'est pas mesuree ici : c'est le playtest humain de fin de
  phase (`docs/playtest-humain.md`).
- Aucun test sur appareil n'a ete fait en P1 : il n'y a pas de portrait et pas de Roblox Studio sur la machine des agents.
