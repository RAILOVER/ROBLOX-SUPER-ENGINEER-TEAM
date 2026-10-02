# Arene 01 : Spiaggia Tralala (greybox P1)

Ticket T-0013. Brief §15.5 (plage de Tralalero, 3 plans, plateau degage) et §17.6 (arene generee par
code, collisions simplifiees). Kit Blender, eclairage final et les 7 autres arenes sont hors perimetre.

## Fichiers

| Fichier | Role |
|---------|------|
| `layout.json` | Source de verite : cases, banc, spawn, 3 cameras, 3 plans de decor, echelle |
| `tools/gen_arena.py` | Transcrit `layout.json` en `src/shared/Config/Arenas/Arena01.luau` (table pure, typee) |
| `src/shared/Config/Arenas/Types.luau` | Schema Luau du layout (luau-lsp verifie la structure du JSON genere) |
| `src/shared/World/ArenaGeometry.luau` | Calculs purs : centre des cases, banc, emprises, budget, champ camera |
| `src/server/World/ArenaBuilder.luau` | `build(parent, arena): Model` et `cellPosition(arena, side, row, col): Vector3` |
| `tests/unit/Arena.spec.luau` | 14 tests Lune sur la partie pure |

Apres toute modification de `layout.json` : `python3 tools/gen_arena.py` (et `--check` en gate).

## Echelle en studs

- Personnage Roblox R15 : 5 studs de haut (`scale.unitHeight = 5`), soit 1 m = 3.571 studs pour un
  brainrot de 1.4 m.
- Case : 6 x 6 studs (`cellSize`), pas de 7 studs (`cellPitch`) : 1 stud de joint visible entre 2 cases,
  une unite de 5 studs tient sur sa case sans deborder. Hauteur de case 0.5 stud (dalle lisible, pas
  d'escalier).
- Camp : 4 colonnes x 7 = 28 studs de large, 2 lignes x 7 = 14 studs de profond.
- Ecart entre les 2 camps (`campGap`) : 10 studs, ligne mediane de 0.5 stud au sol. Les 2 lignes avant sont
  a 17 studs l'une de l'autre (centre a centre), assez pour que les sorts cibles (§9) soient lisibles.
- Zone du plateau (2 camps + ecart) : 28 x 38 studs. Banc a z = -25 (6 places, pas de 7), spawn a z = -38.
- Rivage a z = 65, fond jusqu'a z = 160 : le fond est a plus de 2 fois la distance camera, il ne se
  deplace presque pas a l'ecran et ne gene pas la lecture.

## Repere et nommage

- y vers le haut, sol a y = 0. Camp A (joueur local) en z negatif, camp B (adversaire) en z positif.
- `row = 1` est la ligne avant (face a l'adversaire), `row = 2` la ligne arriere. `col = 1` est a x minimal
  (a gauche depuis la camera combat).
- Parts : `Cell_A_1_1` .. `Cell_B_2_4` (attributs `Side`, `Row`, `Col`), `Bench_1` .. `Bench_6` (attribut
  `Slot`), `Spawn`, dossiers `Decor/foreground`, `Decor/arena`, `Decor/background`, `Cameras/{preparation,
  combat, victory}` (Parts invisibles, attribut `FieldOfView`).
- `ArenaBuilder.cellPosition` renvoie le dessus de la case (y = 0.5) : c'est la que le 05 pose l'unite.

## Flow du joueur

1. Spawn a z = -38, face au plateau (le SpawnLocation regarde vers +z). Le banc (6 dalles creme) est a 13
   studs devant, le camp A (bleu) juste derriere, le camp B (orange) au-dela de la ligne mediane.
2. Preparation : camera `preparation` (10, 30, -50) regardant (0, 2, -12), distance 48 studs, inclinaison
   35.5 degres. Elle cadre le banc et le camp A avec 10 % de marge en 16:9 et 19.5:9 (teste).
3. Combat : camera `combat` (14, 40, -58) regardant (0, 3, 0), distance 70 studs, inclinaison 31.8 degres,
   decalee de 13.6 degres sur la droite pour une vue 3/4. Les 16 cases (pieds et tete d'une unite de 5
   studs) et les 6 places de banc restent dans le champ avec 15 % de marge, en 16:9 et 19.5:9 (teste).
4. Victoire : camera `victory` (8, 8, 14) regardant (0, 4, -12), distance 27.5 studs, basse, cote adversaire,
   pour cadrer le camp A gagnant avec la basket geante en fond.
5. Guidage sans texte : le seul chemin sans decor est l'axe spawn, banc, plateau. Les rochers et le parasol
   ferment le premier plan a gauche et a droite, la mer ferme le fond.

## Lisibilite : contraste camp A / camp B

- Camp A : bleu UI `#2E7CF6`, ligne avant eclaircie `#6FA8FF`. Camp B : orange action `#FF8A00`, ligne avant
  `#FFB04D`. Bleu et orange sont complementaires et restent distincts en daltonisme deuteranope (le bleu
  reste bleu, l'orange devient jaune-brun).
- Les 2 lignes avant sont plus claires que les lignes arriere : la profondeur du camp se lit sans compter.
- Sable `#E9D8A6` (clair, peu sature) sous les cases : les dalles bleues et orange ressortent en valeur et
  en saturation. Rien d'autre que le sable, la ligne mediane (0.1 stud) et les dalles n'est dans la zone
  28 x 38 du plateau (teste : aucune boite de decor ne depasse le dessus des cases dans cette zone).
- Fond (z > 40) : saturation reduite de 15 % par rapport a la palette (basket `#7FA3DE` au lieu de
  `#2E7CF6`, bouees `#E86E6E` au lieu de `#FF4D4D`) pour ne pas concurrencer les unites.
- Pas de texte, pas de texture, pas de MeshPart : couleurs plates `SmoothPlastic`.

## Budget et performance (mesures)

- 82 BaseParts au total : 56 de decor (14 premier plan, 6 arene, 36 fond), 16 cases, 6 banc, 1 spawn,
  3 ancres camera. Budget du ticket : moins de 300. `ArenaGeometry.countParts` et l'attribut `PartCount` du
  Model donnent le meme nombre.
- Collisions : seuls le sol (`Sand`), les 16 cases, les 6 places de banc et le spawn ont `CanCollide` et
  `CanQuery` a true (le tap du 05 raycast sur les cases). Les 56 Parts de decor ont `CanCollide`, `CanQuery`
  et `CanTouch` a false. Aucun CollisionGroup supplementaire : le groupe `Default` suffit.
- StreamingEnabled : le Model est `ModelStreamingMode.Persistent` (82 Parts, toute l'arene est chargee
  des le spawn, aucune case ne peut manquer a l'ecran). `CastShadow = false` partout.
- Le Model est construit au demarrage serveur (`src/server/init.server.luau`) et parente a `Workspace`.

## Ce que l'humain doit verifier dans Studio (HUMAN_ACTION : capture)

Aucun Studio sur les VM des agents : les points ci-dessous ne sont pas verifies.

1. `rojo serve` puis Play (F5). Le Model `arena-01` apparait sous `Workspace`. Verifier dans l'Explorer :
   `Board` (16 Parts), `Bench` (6), `Spawn`, `Decor` (56), `Cameras` (3).
2. Barre de commande, placer la camera combat :
   `local c = workspace["arena-01"].Cameras.combat workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable workspace.CurrentCamera.CFrame = c.CFrame workspace.CurrentCamera.FieldOfView = c:GetAttribute("FieldOfView")`
3. Emulateur d'appareil, paysage, iPhone 14 (19.5:9) et un 16:9 : les 16 cases et les 6 places de banc
   sont entieres a l'ecran, les cases A et B se distinguent a 1 m de l'ecran. Capture a joindre a la PR.
4. Compter les Parts : `print(#workspace["arena-01"]:GetDescendants())` doit afficher 82 Parts + 7 dossiers
   = 89 instances.
5. Verifier que le decor ne cache aucune case depuis la camera combat et que la basket geante reste derriere
   le camp B.
6. Marcher depuis le spawn jusqu'au plateau : le personnage ne traverse pas le sol et ne bute sur aucun
   decor (le decor est traversable, c'est voulu en P1).
