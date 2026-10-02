# Client du duel (T-0012) : HUD greybox, glisser-deposer, lecture de l'ActionLog

Role : 05-dev-client-ui. Spec : `design/specs/M1-duel-minimal.md`. Contrat serveur : `docs/architecture/duel-service.md`
(sections 3 et 4), journal : `docs/architecture/combat.md` (section 3).

## 1. Modules

| Fichier | Role | Pur (Lune) |
| --- | --- | --- |
| `src/shared/Duel/PlaybackPlan.luau` | journal -> etapes d'animation datees, `totalSeconds`, `finalHp`, `upcoming`, `indexAt` | oui (tests/unit/PlaybackPlan.spec.luau) |
| `src/client/init.client.luau` | ordre de demarrage : DuelController, CameraController, CombatPlayback, HudController, DragDrop, puis `JoinDuel` | non |
| `src/client/Controllers/DuelController.luau` | branche les RemoteEvent de `ReplicatedStorage.DuelRemotes` en iterant `DuelRemotes.clientToServer` et `serverToClient`, garde le dernier `ClientView`, expose les intentions | non |
| `src/client/Controllers/HudController.luau` | ScreenGui `DuelHud`, canevas + UIScale, assemble les panneaux, redessine a chaque `DuelState` | non |
| `src/client/Controllers/DragDrop.luau` | glisser-deposer 1 pointeur (souris ou 1 doigt), tap, affichage optimiste annulable | non |
| `src/client/Controllers/CombatPlayback.luau` | Parts par unite, deplacement, nombres flottants, barres de PV, K.O., bandeau MEGA COMBO, resultat | non |
| `src/client/Controllers/CameraController.luau` | 3 cadrages fixes de `Config.Arenas.byId["arena-01"].cameras` en `Scriptable` | non |
| `src/client/UI/Theme.luau` | palette (bible section 3), fabriques Frame / TextLabel / TextButton (44 px min), tuile d'unite | non |
| `src/client/UI/ShopPanel.luau` | `ui_shop_slot_1..5`, `ui_shop_button_reroll`, `ui_shop_button_xp` | non |
| `src/client/UI/BoardPanel.luau` | `ui_board_cell_<row>_<col>` (2 x 4, vue de dessus), `ui_bench_slot_1..6`, `ui_sell_zone` | non |
| `src/client/UI/StatusPanel.luau` | `ui_gold_panel`, `ui_level_panel`, `ui_hp_bar_me`, `ui_round_badge`, `ui_timer_ring`, `ui_hp_bar_opponent` | non |
| `src/client/UI/SynergyPanel.luau` | `ui_synergy_panel`, `ui_synergy_row_1..8` (calcul d'affichage) | non |
| `src/client/UI/TimelinePanel.luau` | `ui_timeline_bar`, `ui_timeline_slot_1..10` | non |
| `src/client/UI/ActionBar.luau` | `ui_megacombo_button`, `ui_button_primary_ready`, `ui_tactic_*`, `ui_camera_*` | non |
| `src/client/UI/Banner.luau` | `ui_banner` : attente, preparation, MEGA COMBO, resultat, fin | non |

Choix documente : le plateau du HUD est une vue de dessus schematique en 2D (8 Frames), pas une projection sur les cases
3D. Raison : le glisser-deposer tactile reste dans un seul espace de coordonnees (celui du ScreenGui) et ne depend pas
de la camera. Les cases 3D de l'arene ne servent qu'a la lecture du combat (Parts posees par `ArenaGeometry.cellTop`).

## 2. Flux de donnees serveur -> client

```
DuelService (serveur)                         Client
  ReplicatedStorage.DuelRemotes/*  <--FireServer--  DuelController.send(name, ...)   (10 intentions du contrat)
  DuelState(view: ClientView)      --OnClientEvent-> DuelController -> HudController.render(view)
  CombatLog(payload)               --OnClientEvent-> DuelController -> CombatPlayback.play(payload) -> plan
                                                                   -> TimelinePanel (10 prochaines etapes)
  DuelEnded(payload)               --OnClientEvent-> DuelController -> Banner (VICTOIRE / DEFAITE / EGALITE)
```

1. `init.client` appelle `DuelController.start()` : `WaitForChild(DuelRemotes.FOLDER, 15)` puis un `WaitForChild`
   borne par nom de remote. Les noms viennent du contrat ; aucun nom n'est recopie dans le client.
2. `DuelController.send` applique le cooldown contractuel (`DuelRemotes.COOLDOWN_SECONDS` = 0,1 s) cote client pour ne
   pas envoyer une intention que le serveur ignorerait de toute facon. Il ne verifie rien d'autre : or, phase, siege,
   capacite du plateau sont juges par le serveur.
3. `DuelController.isIntentOpen(name)` lit la phase exigee par le contrat (`phase` du schema) et la phase du dernier
   `ClientView` pour griser les boutons. C'est une lecture du contrat, pas une regle de jeu.
4. Chaque `DuelState` incremente `DuelController.getStateVersion()` et redessine integralement boutique, banc, plateau,
   synergies, statut, boutons. Il n'y a pas d'etat local persistant en dehors de la selection d'unite (tactique).
5. `CombatLog` est transforme en plan par `PlaybackPlan.build(Config, payload)` puis joue par `CombatPlayback`. La
   timeline et la jauge Mega du HUD suivent l'index d'etape via `CombatPlayback.setStepHook`.
6. Le retour en `Preparation` appelle `CombatPlayback.clear()` (Parts detruites, jauge remise a 0 pour l'affichage).

## 3. Ce que le client n'affiche jamais avant confirmation

| Donnee | Source affichee | Jamais calcule cote client |
| --- | --- | --- |
| or, revenu suivant | `view.me.gold`, `view.me.nextIncome` | solde apres achat, interet, serie |
| prix d'une unite | `view.me.shop[i].cost` | cout par rarete |
| XP, niveau, XP suivante | `view.me.xp`, `level`, `xpToNext` | passage de niveau |
| PV des 2 sieges | `view.me.hp`, `view.opponent.hp` | degats au joueur |
| contenu de la boutique, vendu | `view.me.shop` | tirage, probabilites |
| banc et plateau | `view.me.bench`, `view.me.board` | fusion 3 etoiles, capacite |
| timer | `view.timerSeconds` recale a chaque `DuelState`, decremente en affichage | fin de phase |
| degats, soins, critiques, PV d'unite, K.O. | `actionLog[i].values`, `crits`, `hp`, `kos` | toute regle de combat |
| resultat de manche, degats joueur | `payload.result.winner`, `payload.playerDamage` | issue du combat |
| fin du duel | `DuelEnded` | condition de victoire |

Affichages optimistes et leur annulation (`DragDrop.optimisticMove`) : apres un depot accepte localement (intention
envoyee), la tuile est reparentee sur la case cible a 50 % de transparence avec l'attribut `Optimistic`. Elle est
detruite et redessinee par le prochain `DuelState` (confirmation ou refus). Si aucun `DuelState` n'arrive sous
`RESYNC_SECONDS` = 0,75 s (intention ignoree sans diffusion), `HudController.handles().rerender()` redessine le
dernier etat confirme. Un depot sur une cible invalide (banc -> banc, boutique -> plateau, case occupee) ne envoie
rien et redessine immediatement.

Deux calculs d'affichage, assumes et documentes :

1. `SynergyPanel.compute` compte les slugs distincts du plateau membres de chaque synergie de `Config.Synergies` et en
   deduit le palier affiche. Le serveur (`Effects.computeSynergies`) reste la reference ; les cas K.O., `HorsCombat` et
   `Couple` ne sont pas reproduits.
2. `CombatPlayback.setHp` deduit le PV max d'une unite du journal : PV apres + degats du premier coup recu. Il ne lit
   aucune stat du roster. Si le serveur ajoute `hpMax` aux equipes du `CombatLogPayload` (ticket T-0032), cette
   deduction disparait.

Le bouton `ui_megacombo_button` est visible et grise : le contrat T-0011 ne contient pas d'intention `MegaCombo` (le
Mega Combo se declenche dans `CombatSim`). Il affiche la derniere jauge lue dans le journal (`gauges.mega`) et
redeviendra actif des que `DuelRemotes.clientToServer.MegaCombo` existera (T-0032), sans changement cote HUD.

## 4. Mapping ActionLog -> animation

`PlaybackPlan.fromLog` produit une etape par entree, dans l'ordre, sans fusion ni suppression (test : `#plan ==
#actionLog`, PV finaux identiques). Chaque etape porte `t, kind, actorCell, targetCells, values, crits, statuses,
ticks, hpAfter, kos, gauges, skillId, combo, partner, startSeconds, durationSeconds`.

| Champ du journal | Animation (`CombatPlayback.playStep`) |
| --- | --- |
| `actor = "slug.A3"` | la Part `A3` avance de 35 % vers `targets[1]` puis revient (duree min(durationSeconds, 0,6) s) |
| `values[i] > 0` | nombre flottant `-N` rouge au-dessus de `targets[i]` ; jaune + `CRIT` si `crits[i]` |
| `values[i] < 0` | nombre flottant `+N` vert (soin) |
| `values[i] == 0` | le type d'action en texte (buff, garde) |
| `statuses.applied` | texte violet du nom du statut sur la cible |
| `hp[cell]` | barre de PV de la Part `cell` (vert > 50 %, or > 25 %, rouge sinon) et PV en chiffres |
| `kos` | Part reduite a 30 % et rendue transparente en 0,4 s, texte `K.O.` |
| `action == "Mega"` | bandeau `MEGA COMBO <combo>` pendant 2,5 s |
| `gauges.mega` | pourcentage sur le bouton Mega Combo (`megaGaugeMax` = 100) |
| fin du plan | bandeau `MANCHE GAGNEE / PERDUE / NULLE` + `playerDamage` (3 s) |

Minutage (M-C-04). `Config.Combat.pvpActionAnimationMaxSeconds` = 0,8 s par action donne 41,3 s pour 51,6 actions
(moyenne M1). Le plan compresse sans toucher aux regles :

| Regle | Valeur |
| --- | --- |
| duree de base par type | Attack 0,6 s ; Skill 0,8 s ; Duo 0,8 s ; Guard 0,35 s ; Skip 0,2 s ; Mega 2,5 s |
| action repetitive (meme type que la precedente, sans critique, K.O. ni statut pose) | x 0,7 |
| mort subite (t > `suddenDeathAfterActions` = 40) | x 0,5 |
| bornes | min 0,15 s ; max 0,8 s hors Mega ; Mega toujours 2,5 s |

Mesure `lune run tests/run.luau PlaybackPlan` (100 combats par passe, equipes de meme taille 2 a 8, seeds fixes) :

| Passe | Actions moyennes | Duree du plan (moyenne) | Min / max | A 0,8 s fixe |
| --- | --- | --- | --- | --- |
| L0 (42 slugs) | 46,4 | 22,4 s | 6,9 s / 27,5 s | 37,1 s |
| M1 (10 unites) | 50,8 | 24,5 s | 8,8 s / 30,1 s | 40,6 s |

Les 2 passes sont dans la cible 20 a 35 s ; le test echoue si une moyenne en sort.

## 5. Responsive et entrees

- `ScreenGui.DuelHud` : `ScreenInsets = DeviceSafeInsets`, `SafeAreaCompatibility = FullscreenExtension`,
  `IgnoreGuiInset = false` (la barre Roblox reste libre), `ZIndexBehavior = Sibling`.
- Canevas `Root` de `viewport / scale` px avec `UIScale.Scale = clamp(viewport.Y / 400, 1, 2.4)`, recalcule sur
  `Camera.ViewportSize`. L'echelle n'est jamais < 1 : un bouton de 44 px du canevas mesure au moins 44 px reels.
  Sur 1280 x 720 l'echelle est 1,8 (boutons 79 px) ; sur 844 x 390 (telephone paysage) elle est 1.
- Chaque `TextButton` recoit `UISizeConstraint.MinSize = 44 x 44` et un `UIPadding` de 4 px (`Theme.button`).
- Portrait : non cible en M1 (brief : paysage mobile prioritaire) ; le canevas suit la hauteur et les colonnes
  gauche / droite se compressent. A verifier dans Studio (section 6).
- Entrees : `UserInputService.InputBegan / InputChanged / InputEnded`, `MouseButton1` ou `Touch`, un seul pointeur
  actif. La cible est trouvee par `PlayerGui:GetGuiObjectsAtPosition` dans l'espace `InputObject.Position`
  (deja sous l'inset) ; `GuiService:GetGuiInset()` n'est rajoute que si un ScreenGui ignore l'inset. `gameProcessedEvent`
  n'est pas filtre : il vaut vrai au-dessus d'une Frame `Active`, ce qui est exactement le cas voulu.
- Un tap (< 10 px de deplacement) sur une case de boutique envoie `BuyShopSlot` ; sur une tuile, selectionne l'unite
  pour appliquer `SetTactic(tactic, instanceId)` ; sans selection, `SetTactic(tactic)` vise toutes les unites.

## 6. Verifications a faire dans Roblox Studio (HUMAN_ACTION, ticket T-0031)

Cette machine n'a pas Roblox Studio : rien de ce qui suit n'a ete observe. Le detail chiffre est dans
`tickets/backlog/T-0031-human-playtest-m1-studio.md`.

1. Play Solo : `DuelHud` present dans `PlayerGui`, bandeau "En attente", bot entre, phase Preparation, 5 cases de
   boutique remplies, 3 or, niveau 2.
2. Achat au tap et au glisser (boutique -> banc), refus sans or (la boutique ne change pas), relance a 2 or, XP a 4 or.
3. Banc -> plateau (case libre), plateau -> banc, plateau -> plateau, banc -> zone de vente ; capacite plateau = niveau.
4. Pret : le timer passe a 3 s puis Combat ; Parts posees sur les cases ; nombres flottants ; K.O. ; resultat ; PV joueur.
5. Timeline : 10 lignes, la premiere correspond a l'action jouee ; jauge Mega qui monte ; bandeau MEGA COMBO si le
   journal en contient un.
6. Emulation tactile (Device Emulator, iPhone paysage) : glisser a 1 doigt, boutons >= 44 px, rien sous l'encoche.
7. Test local 2 joueurs : les 2 HUD montrent des boutiques differentes, le meme journal, des PV coherents.
8. Console : 0 erreur, 0 warning `[DuelController]`.
