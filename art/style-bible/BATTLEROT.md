# Bible de style: BATTLEROT (v1.0)

Document de reference du Directeur artistique (03). Tout asset (3D, 2D, UI, VFX) est compare a cette
bible par un modele de vision AVANT d'etre accepte (section 10). Les contraintes techniques chiffrees
(triangles, textures, lumieres) vivent dans `art/budgets/budgets.yaml` et sont recopiees ici sans
modification. Sources: `design/brief/BATTLEROT.md` section 15 et regles R6, R7, R10;
`src/shared/Config/Rarities.luau`; `src/shared/Config/Synergies.luau`; `art/refs/<slug>/REFS.md`.

Phase P1 (greybox): aucun asset final n'est produit. Cette bible sert a ecrire les gabarits de prompts
(`art/prompts/BATTLEROT.md`) et les fiches de reference (`art/refs/`). Elle sera appliquee a partir de P2.

## 1. Direction en une phrase

Jouets cartoon satures et ronds: formes simplifiees en 8 volumes maximum, 4 couleurs plates par
personnage, ombrage en 2 tons, contour fonce `#1A1A2E`, traits signature des memes exageres de 20 a 30 %,
lisibles en vignette de 64 px sur telephone.

Ce que l'on traduit: les memes d'origine sont des images IA semi-realistes (voir `art/refs/`). On ne les
copie pas, on en garde 3 a 4 traits signature et on les rend en "jouet vinyle": surfaces lisses, aretes
biseautees, yeux grands, pas de texture photo.

## 2. Palette

### 2.1 Palette maitresse (10 couleurs, limite ferme)

Toute image produite pour BATTLEROT (UI, cartes, oeufs, VFX, decor) utilise ces 10 couleurs plus,
au choix: 1 accent de famille (2.2) et jusqu'a 4 couleurs propres au personnage (2.3).

| Id | Role | Hex | Usage | Interdit pour |
|----|------|-----|-------|---------------|
| P01 | Encre | `#1A1A2E` | contours (inverted hull), `UIStroke`, ombre du texte, pupilles | fonds pleins, grandes surfaces (> 10 % des pixels) |
| P02 | Creme | `#FFF8E7` | fonds de panneaux, blanc des yeux, dents, reflet specular peint | texte sur fond creme |
| P03 | Bleu BATTLEROT | `#2E7CF6` | UI principale, boutons secondaires, chiffres de bouclier | corps de personnage |
| P04 | Bleu nuit | `#1B3F8F` | fond d'ecran UI, ombres portees UI, ciel de nuit (arene 8 debut) | texte |
| P05 | Or | `#FFC93C` | bouton COMBAT, monnaie or, rarete Champion, variante 3 etoiles | decor hors recompense |
| P06 | Orange | `#F28C28` | rarete Rare, bouton d'action secondaire, texte "CRIT!" | corps de personnage hors famille Sahur |
| P07 | Vert | `#3DDC5C` | amelioration possible, chiffres de soin, barre d'exemplaires pleine | alerte |
| P08 | Rouge | `#FF4D4D` | alerte, pastilles de notification, PV < 25 %, degats recus | decor, personnage |
| P09 | Violet | `#A44CF2` | rarete Epique, halo d'oeuf Epique, VFX magie | UI de base |
| P10 | Gris acier | `#8FA6C1` | rarete Commune, UI desactivee, metal des props | texte courant |

Rarete Legendaire (`Rarities.luau` = `RAINBOW`): degrade anime construit uniquement avec P08, P06, P05,
P07, P03, P09 dans cet ordre (6 arrets, rotation de 360 degres en 3,0 s). Aucune couleur hex
supplementaire.

Regles de saturation et de contraste:
- Saturation HSV maximale: 90 %. Valeur HSV minimale pour une couleur de corps: 40 %.
- Jamais `#000000`, jamais `#FFFFFF` (on utilise P01 et P02).
- Contraste texte UI sur son fond: 4,5:1 minimum (WCAG AA), 7:1 pour les chiffres de combat.
- Contraste entre le corps d'une unite et le decor derriere elle: difference de luminance L* >= 30.

### 2.2 Accents de famille (1 seul par asset, 15 % des pixels maximum)

Valeurs du brief 15.2. L'accent sert au fond de carte, a la teinte du contour (P01 melange a 30 % avec
l'accent), a l'icone de synergie et aux particules de synergie. Il ne sert jamais de couleur de corps.

| Famille | Hex | Icone de synergie (forme) |
|---------|-----|---------------------------|
| Mare | `#2EC4F1` | vague |
| Cielo | `#8EC5FF` | nuage |
| Caffe | `#8B5A3C` | tasse |
| Giungla | `#3CB44B` | feuille |
| Frutta | `#FF5E7E` | fruit rond |
| Macchina | `#8A9AA9` | engrenage |
| Cosmo | `#6C3CE0` | etoile a 4 branches |
| Sahur | `#FF9F43` | tambour |
| Tentafruit | `#FF7AC6` | coeur |

Unite a 2 familles: l'accent de la premiere famille listee dans `src/shared/Config/Roster/` est utilise;
la seconde n'apparait que par son icone.

### 2.3 Couleurs propres au personnage (4 maximum)

Chaque `art/refs/<slug>/REFS.md` declare 2 a 4 couleurs dominantes (hex). Elles respectent:
- S entre 35 % et 90 % et V entre 40 % et 95 % pour les couleurs vives;
- S <= 25 % et V entre 30 % et 85 % pour les neutres (bois, pelage gris, metal);
- ton d'ombre = meme teinte a +/- 10 degres, V diminuee de 25 points (ombrage en 2 tons, aucun degrade au-dela du degrade vertical de 10 % de V autorise par le brief 15.3).

Verification: 90 % des pixels d'un rendu (hors fond) tombent a une distance RGB <= 24 (sur 255 par canal,
distance euclidienne) d'une des couleurs declarees: 10 de la palette + 1 accent + 4 propres au personnage.

## 3. Formes et proportions

### 3.1 Echelle

- Reference Roblox: avatar R15 = 5 studs = 1,4 m, donc 1 stud = 0,28 m. Porte = 2,2 m = 7,9 studs. Caisse = 1 m = 3,6 studs.
- Hauteur des unites (brief 15.3), mesuree du sol au point le plus haut hors particules:

| Rarete | Hauteur (studs) | Hauteur (m) |
|--------|-----------------|-------------|
| Commune | 4,5 a 5,5 | 1,26 a 1,54 |
| Rare, Epique | 5,0 a 6,0 | 1,40 a 1,68 |
| Legendaire | 6,0 a 7,0 | 1,68 a 1,96 |
| Champion | 7,0 a 8,0 | 1,96 a 2,24 |
| Boss | x2 de sa rarete | |

- Unites longues (Bombardiro Crocodilo, Bombombini Gusini): la longueur peut atteindre 1,6 x la hauteur; la hauteur reste dans la fourchette.

### 3.2 Proportions du corps

| Type de corps | Exemples M1 | Regle chiffree |
|---------------|-------------|----------------|
| Bipede chibi | fraisio, fraisita, poirita, tung-tung-tung-sahur, ballerina-cappuccina | tete (ou objet-tete) = 35 a 45 % de la hauteur totale (2,2 a 2,9 tetes); jambes = 25 a 35 % |
| Objet anime | chimpanzini-bananini | objet signature (banane) >= 40 % de la hauteur |
| Animal hybride | tralalero-tralala, trippi-troppi | element signature (baskets, tete) >= 30 % de l'aire de la silhouette |
| Vehicule hybride | bombardiro-crocodilo, bombombini-gusini | tete animale = 30 a 40 % de la longueur totale |

Regles communes:
- 8 volumes principaux maximum par personnage (tete, torse, 4 membres, 2 accessoires).
- Yeux: diametre >= 12 % de la hauteur de la tete; 2 yeux visibles en vue de 3/4; pupille P01, blanc P02, reflet P02 de 1 pastille.
- Membres: epaisseur >= 8 % de la hauteur totale (jamais de membre plus fin que 0,4 stud).
- Exageration: chaque trait signature est agrandi de 20 a 30 % par rapport a sa proportion dans la reference canonique (ex: baskets de Tralalero = 45 % de la longueur du corps, contre 35 % environ dans l'image d'origine).
- Rondeurs par defaut; angles vifs reserves aux armes, aux boss et aux accents agressifs (batte, katana, bombes).

### 3.3 Lisibilite a 64 px et a 30 m

- Test de vignette: rendu 64 x 64 px, personnage occupant 80 % de la hauteur (51 px), vue de 3/4, fond P02. Au moins 3 des 4 traits signature de la fiche `REFS.md` identifiables.
- Test de silhouette: meme cadrage, personnage rempli en P01. Le modele de vision nomme la bonne unite parmi les 10 de M1 dans au moins 8 cas sur 10.
- Taille minimale d'un detail modelise: 10 cm (3 px dans la vignette pour une unite de 5 studs) pour Commune, Rare, Epique; 15 cm pour Legendaire et Champion (7 a 8 studs: 1 px = 4,4 cm).
- Props et decor: silhouette lisible a 30 m, aucun detail < 5 cm.
- Biseau de 2 a 5 cm sur toute arete visible; aucune arete vive sauf armes.

## 4. Niveau de detail

### 4.1 Budgets (copie de `art/budgets/budgets.yaml`, ne pas modifier ici)

| Type | Tris max (LOD0) | LOD ratio | Texture max | Materiaux par mesh |
|------|-----------------|-----------|-------------|--------------------|
| CHAR | 8000 | 1.0 / 0.5 / 0.25 / 0.1 | 1024 px | 1 |
| PROP | 1500 | idem | 1024 px | 1 |
| KIT | 800 | idem | 1024 px | 1 |
| ENV | 3000 | idem | 1024 px | 1 |
| VFX | 300 | idem | 1024 px | 1 |
| UI | 200 | idem | 1024 px | 1 |

UV overlap <= 2 %, aucun ngon, 6 lumieres a ombres maximum, cible 45 FPS mobile et 60 FPS desktop.

Cibles de la DA a l'interieur de ces budgets (LOD0): Commune <= 4000 tris, Rare et Epique <= 5000,
Legendaire et Champion <= 8000. Les LOD 2 et 3 (0.25 et 0.1) doivent encore passer le test de silhouette.

### 4.2 Modelise ou texture

| Modelise (geometrie) | Texture (atlas 1024 ou vertex color) |
|----------------------|--------------------------------------|
| yeux (spheres), bouche ouverte, dents | pupilles et reflet (decal plat) |
| accessoires signature (baskets, batte, tutu, micro, helices) | lacets, coutures, grains de fraise (pastilles plates) |
| biseaux, volumes du corps | ombrage en 2 tons, degrade vertical de 10 % |
| fissures de l'oeuf (3 etats) | motifs de l'oeuf (taches, anneaux) |

- Couleurs par asset: personnage 6 plates maximum (4 propres + P01 + P02), prop 4, piece de kit d'arene 5, oeuf 4 + couleur de rarete.
- Bruit et grain: amplitude <= 5 % de V, jamais de texture photo, jamais de normal map sur un personnage.
- Texte dans une texture: interdit (les onomatopees sont des images UI separees, validees une par une).
- Les 42 unites L0 partagent 1 atlas de palette (cellules de couleur plates); les details propres sont peints dans l'atlas 1024 du personnage.

## 5. Materiaux

Roblox: `Material = SmoothPlastic` ou `SurfaceAppearance` avec les valeurs ci-dessous. `Reflectance = 0`
partout. Metalness binaire (0 ou 1). Aucun reflet miroir, aucune transparence hors eau et verre.

| Famille de surface | Roughness | Metalness | Exemples |
|--------------------|-----------|-----------|----------|
| peau de fruit, vinyle, pelage | 0,75 | 0 | fraises, poire, crocodile, requin |
| bois | 0,70 | 0 | Tung Tung Tung Sahur, batte, tambours |
| ceramique, tasse | 0,45 | 0 | Ballerina Cappuccina, fontaine-tasse |
| metal cartoon | 0,40 | 1 | fuselage de Bombardiro, moteurs de Gusini, engrenages Macchina |
| eau, verre, piscine | 0,20 | 0 | arenes 1 et 3, transparence 0,4 maximum |
| VFX | 1,00 (Neon ou particules) | 0 | halos, confettis |

## 6. Lumiere et ambiance

Reglages communs (`Lighting`): `Technology = ShadowMap`, `GlobalShadows = true`, `ShadowSoftness = 0.5`,
`EnvironmentDiffuseScale = 0.5`, `EnvironmentSpecularScale = 0.2`, `ExposureCompensation = 0`.
Post-effets: 2 maximum, toujours les memes: `BloomEffect` (Intensity 0.3, Size 24, Threshold 0.95) et
`ColorCorrectionEffect` (Saturation +0.15, Contrast +0.05, Brightness 0). Aucun `DepthOfField`, aucun
`SunRays` sur mobile. 6 lumieres a ombres maximum par arene (`budgets.yaml`).

| # | Arene (brief 15.5) | ClockTime | Brightness | Atmosphere.Density | Atmosphere.Color | OutdoorAmbient |
|---|--------------------|-----------|------------|--------------------|------------------|----------------|
| 1 | Plage de Tralalero | 12,0 | 2,5 | 0,25 | `#8EC5FF` | `#8EC5FF` |
| 2 | Jungle Bananini | 9,0 | 2,2 | 0,30 | `#3CB44B` a 40 % vers P02 | `#8FA6C1` |
| 3 | Villa de la Tentafruit | 18,5 | 2,0 | 0,30 | `#FF7AC6` | `#F28C28` |
| 4 | Piazza del Caffe | 17,0 | 2,3 | 0,25 | `#FFC93C` a 40 % vers P02 | `#8B5A3C` a 50 % vers P02 |
| 5 | Officina Bombardini | 10,0 | 2,6 | 0,20 | `#8EC5FF` | `#8A9AA9` |
| 6 | Foret de Patapim | 19,0 | 1,8 | 0,35 | `#6C3CE0` a 50 % vers P02 | `#1B3F8F` |
| 7 | Anneaux de Saturne | 0,0 | 2,0 | 0,15 | `#6C3CE0` | `#1B3F8F` |
| 8 | Village du Sahur | 5,0 vers 6,5 pendant le combat | 1,8 vers 2,4 | 0,30 | `#1B3F8F` vers `#FF9F43` | `#1B3F8F` vers `#FF9F43` |

Composition d'arene (brief 15.5):
- plateau de combat central degage: aucun prop a moins de 4 studs du bord du plateau; le plateau occupe 50 a 60 % de la largeur de l'ecran en 16:9 et 70 % en 9:16 (camera de 3/4 inclinee de 30 a 35 degres);
- decor en 3 plans: 0 a 20 studs (props detailles, KIT 800 tris), 20 a 60 studs (ENV 3000 tris, 3 couleurs max), > 60 studs (toile plate ou skybox, 2 couleurs);
- derriere les unites: saturation du decor diminuee de 15 points HSV, contraste L* entre unite et decor >= 30;
- elements animes: 3 a 5 par arene, amplitude <= 1 stud, periode >= 2 s, aucun au-dessus du plateau;
- Village du Sahur (arene 8): village a l'aube, lanternes et tambours; aucun symbole religieux, aucun element de culte, aucune moquerie culturelle.

## 7. UI

Valeurs en pixels pour 1920 x 1080; la mise a l'echelle passe par `UIScale` et `UIAspectRatioConstraint`.

| Element | Regle |
|---------|-------|
| Polices | `LuckiestGuy` titres et chiffres; `FredokaOne` texte courant |
| Contour du texte | `UIStroke` 2 a 4 px en P01, ombre portee 2 px decalee en bas |
| Coins | `UICorner` 12 px panneaux, 16 px boutons, 8 px pastilles |
| Bordures | 4 px, couleur = fond assombri de 25 % de V |
| Boutons | 9-slice avec biseau, pression: echelle 0,92 puis retour Back easing en 0,12 s |
| Cible tactile | 44 x 44 px minimum; bouton COMBAT 320 x 96 px minimum |
| Taille de texte | 14 px minimum sur telephone, 18 px pour les chiffres de combat |
| Contraste | 4,5:1 texte, 7:1 chiffres de combat (blanc P02 avec contour P01) |
| Transitions | glissements et rebonds de 0,2 a 0,35 s; aucune coupe seche |
| Icones de rarete | rond Commune, losange Rare, etoile Epique, hexagone Legendaire, couronne Champion; 24 px sur carte, 48 px en banniere |
| Icones de famille | formes de 2.2, 1 couleur (accent) + contour P01, lisibles a 24 px |
| Hierarchie | 3 tailles de texte maximum par ecran; 1 seul bouton P05 par ecran |
| Carte (brief 15.4) | ratio 3:4, portrait de 3/4, fond = accent de famille, cadre = couleur de rarete, cout en or en haut a gauche (P05 + P01), icones familles et classe en bas, barre "Niv. X", barre d'exemplaires P07 |

## 8. References

Regle R10: 3 references canoniques publiques par personnage, listees dans `art/refs/<slug>/REFS.md`
(URL, traits signature, couleurs, note de moderation). Aucune image copiee dans le depot.

| Slug (fiche) | Ce que l'on retient | Ce que l'on stylise |
|--------------|---------------------|---------------------|
| `art/refs/tralalero-tralala/REFS.md` | requin gris-bleu, 3 pattes, baskets bleues | baskets sans logo, corps en 3 volumes |
| `art/refs/tung-tung-tung-sahur/REFS.md` | buche de bois, grands yeux, batte en bois | aucun element d'horreur, grain de bois peint |
| `art/refs/bombardiro-crocodilo/REFS.md` | tete de crocodile, fuselage bimoteur, helices | bombes cartoon desamorcees, aucune cocarde |
| `art/refs/ballerina-cappuccina/REFS.md` | tete-tasse de cappuccino, tutu, pointes | mousse en 2 tons, tutu en 3 volumes |
| `art/refs/trippi-troppi/REFS.md` | tete de poisson ou chat, corps de crevette | 1 seule variante retenue (chat-crevette) |
| `art/refs/bombombini-gusini/REFS.md` | oie, ailes-reacteurs, bec orange | reacteurs arrondis, aucune etoile militaire |
| `art/refs/chimpanzini-bananini/REFS.md` | chimpanze vert, peau de banane ouverte | banane = 40 % de la hauteur |
| `art/refs/fraisio/REFS.md` | fraise-corps, feuilles en cheveux, tenue de plage | accessoire de couple assorti |
| `art/refs/fraisita/REFS.md` | fraise-corps, feuilles en coiffure, tenue de plage | aucune tenue suggestive (R7) |
| `art/refs/poirita/REFS.md` | poire-corps, micro, fiches de presentatrice | aucun element de ceremonie adulte |

Styles que l'on ne vise pas et qui ne servent donc pas de reference: images IA semi-realistes des memes,
rendu PBR realiste, pixel art, anime, assets d'autres jeux (Clash Royale, TFT, Brawl Stars sont une
inspiration de rythme et d'epaisseur d'UI, jamais une source d'asset).

## 9. Interdits

1. Photorealisme, textures photo, normal maps sur personnages, materiaux PBR realistes.
2. `#000000` et `#FFFFFF` purs; degrades au-dela du degrade vertical de 10 % de V; plus de 1 accent de famille par asset.
3. Texte dans une texture ou dans un rendu de carte (les chiffres et noms sont des `TextLabel`).
4. Logos, marques, cocardes, drapeaux, insignes militaires reels (ex: aucun logo sur les baskets de Tralalero, aucune etoile sur les moteurs de Gusini) (R6).
5. Reprise d'un asset, d'une image ou d'un son d'origine TikTok ou d'un autre jeu (brief 15.9: jamais d'audio TikTok).
6. Sexualisation: pas de tenue suggestive, pas de pose suggestive, pas d'anatomie accentuee; les Tentafruit portent t-shirt, short, lunettes de soleil, colliers de fleurs (R7).
7. Gore, sang, blessures visibles, armes realistes; K.O. = pouf d'etoiles.
8. Symboles religieux, references politiques, personnes reelles, personnages d'autres franchises (R7).
9. Horreur: pas de dents en lame, pas d'yeux injectes, pas de contre-jour sinistre; les antagonistes restent des jouets.
10. Fonds charges: aucun element de decor au-dessus du plateau de combat; flash blanc desactivable (brief 15.7).

## 10. Grille de validation vision (utilisee par le DA)

Protocole: rendu de 3/4 en lumiere neutre (ClockTime 12, Brightness 2, pas de post-effet) + 1 asset deja
accepte comme reference. Chaque question est posee seule au modele de vision. 1 critere en echec =
`REFUSE: <critere>` avec l'action correctrice. Le gout n'est pas un critere. Un cas qui revele un critere
manquant ajoute une ligne a cette grille au lieu d'accorder une exception.

| # | Critere | Question posee au modele de vision | Seuil |
|---|---------|------------------------------------|-------|
| V01 | Palette | Quelle part des pixels (hors fond) est a distance RGB <= 24 d'une couleur declaree (10 maitresses + 1 accent + 4 propres) ? | >= 90 % |
| V02 | Nombre de couleurs | Combien de couleurs plates distinctes (hors P01, P02) ? | <= 4 personnage, <= 4 prop, <= 5 kit |
| V03 | Accent de famille | Un seul accent de famille est-il present et couvre-t-il <= 15 % des pixels ? | oui |
| V04 | Noir et blanc purs | Y a-t-il des zones `#000000` ou `#FFFFFF` ? | non (0 % des pixels) |
| V05 | Traits signature | Dans la vignette 64 px, combien des 4 traits de `REFS.md` sont identifiables ? | >= 3 sur 4 |
| V06 | Silhouette | Silhouette P01 a 64 px: quelle unite parmi les 10 de M1 ? | bonne reponse dans >= 8 cas sur 10 |
| V07 | Proportions | La tete (ou l'objet-tete) fait-elle 35 a 45 % de la hauteur pour un bipede, ou l'element signature >= 30 % de l'aire pour un hybride ? | oui |
| V08 | Hauteur | La hauteur en studs est-elle dans la fourchette de la rarete (3.1) ? | oui (+/- 0,2 stud) |
| V09 | Detail minimal | Existe-t-il un detail modelise < 10 cm (15 cm pour Legendaire et Champion) ? | non |
| V10 | Volumes | Combien de volumes principaux ? | <= 8 |
| V11 | Aretes | Toutes les aretes visibles sont-elles biseautees (2 a 5 cm) hors armes ? | oui |
| V12 | Ombrage | L'ombrage est-il en 2 tons (ombre = teinte +/- 10 degres, V -25 points) sans degrade doux ? | oui |
| V13 | Texte et logos | Y a-t-il du texte, un logo, une marque, un insigne ? | non |
| V14 | Moderation R7 | Y a-t-il un element sexuel, gore, religieux, politique ou une personne reelle ? | non |
| V15 | Contraste decor | L* unite moins L* du decor derriere elle ? | >= 30 |
| V16 | Coherence | Cet asset serait-il a sa place a cote de l'asset de reference accepte ? | oui |
| V17 | Budget | Tris, materiaux, taille de texture (lus par `tools/validate_mesh.py`, pas par le modele de vision) | dans `budgets.yaml` |

Verdict ecrit dans la PR sous la forme: `ACCEPTE` ou `REFUSE: V05 (2 traits sur 4 visibles): agrandir les baskets a 45 % de la longueur du corps`.

## 11. Ecarts par rapport au brief (a valider par le Producteur)

| # | Brief 15.2 | Bible v1 | Raison |
|---|------------|----------|--------|
| E1 | "Orange action" `#FF8A00` en plus de la rarete Rare `#F28C28` | une seule orange P06 `#F28C28` | limite de 10 couleurs du ticket T-0014; les 2 oranges sont voisines (distance RGB 42, meme teinte a 6 degres pres) et se confondent a 64 px; `Rarities.luau` fait foi |
| E2 | 22 valeurs hex (8 UI + 9 familles + 5 raretes) | 10 maitresses + 9 accents de famille isoles (1 par asset) | lisibilite: une image ne montre jamais plus de 15 couleurs |

Aucune valeur de `src/shared/Config/` ni de `art/budgets/budgets.yaml` n'est modifiee par ce document.

## 12. Non verifie

- Aucun rendu n'existe en P1: les seuils V01 a V16 n'ont pas encore ete appliques a un asset reel. Ils seront calibres sur les 3 premiers assets de P2 et ajustes par ticket.
- Les reglages de lumiere (section 6) sont des valeurs de depart issues du brief 15.5 et des regles Roblox; ils n'ont pas ete observes dans Studio (HUMAN_ACTION: capture par arene a la premiere greybox eclairee).
- Les polices `LuckiestGuy` et `FredokaOne` sont celles du brief 15.6; leur disponibilite dans `Enum.Font` du build Roblox courant n'a pas ete verifiee depuis cette machine.
