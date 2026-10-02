# Spec M1 : duel minimal (boucle TFT)

Ticket : T-0009. Source : brief §6.1, §10, §21 (ligne M1). Config : `Config.Duel`, `Config.Rarities`,
`Config.Roster`, `Config.Synergies`, `Config.Combos`. Tickets derives : T-0011 (DuelService, bot), T-0015 (QA).
Le combat lui-meme est specifie dans [M1-combat-tour-par-tour](M1-combat-tour-par-tour.md).
Chaque regle porte un identifiant `D-M1-xx` : le dev serveur ecrit 1 test Lune par regle.

## 1. Enonce testable

Un joueur lance un duel contre le bot M1 (ou contre un 2e joueur), joue entre 8 et 11 manches, et atteint l'ecran de
fin en 7 a 10 minutes, avec les 10 unites M1, 5 synergies activables au palier 1 et le Mega Combo C05 realisable.

## 2. Mesure

| ID | Mesure | Instrument | Seuil |
|---|---|---|---|
| M-D-01 | Nombre de manches par duel | compteur serveur, 1 000 duels bot contre bot sous Lune (T-0015) | mediane entre 8 et 11, p90 <= 14 |
| M-D-02 | Duree d'un duel | chrono serveur manche 1 a ecran de fin, 10 duels humain contre bot (playtest) | mediane entre 7 et 10 min |
| M-D-03 | Temps d'une manche hors combat | `prepSeconds` + resultat (<= 4 s) + transition (<= 3 s) | <= 37 s manches 4+, <= 27 s manches 1 a 3 |
| M-D-04 | Synergies activables au palier 1 avec les 10 unites | test Lune sur `Config.Synergies` et la liste §4 | >= 4 (5 attendues) |
| M-D-05 | Combo MVP realisable | test Lune : les 2 slugs d'un couple de C05 sont dans la liste §4 | vrai |
| M-D-06 | Aucune manche sans fin | toute manche se termine par victoire, defaite ou nul | 100 % sur 1 000 duels |
| M-D-07 | Bot : taux de victoire contre un joueur qui achete au hasard | 1 000 duels sous Lune, bot contre acheteur aleatoire uniforme | entre 55 % et 75 % |
| M-D-08 | Bot : taux de victoire contre lui-meme | 1 000 duels bot contre bot | entre 45 % et 55 % (symetrie, pas d'avantage au 1er joueur) |

Budget temps d'un duel (valeurs de `Config.Duel` et brief §11.9) : manche = preparation (20 s manches 1 a 3,
30 s ensuite) + combat (20 a 35 s, cible 27 s) + resultat 4 s + transition 3 s.
8 manches = 60 + 150 + 8 x 34 = 482 s (8,0 min). 10 manches = 610 s (10,2 min). 11 manches = 674 s (11,2 min).
Les duels de 10 et 11 manches ne tiennent dans 10 min que si "Pret" saute le minuteur dans au moins 50 % des manches
4+ (hypothese H-07 du GDD). Le bot est toujours "Pret" des la fin de ses achats (D-M1-24).

## 3. Regles

### 3.1 Deck et pool

- D-M1-01 : le deck M1 est fixe pour les 2 camps et contient exactement `Duel.deckSize` = 10 slugs (liste §4). Aucun
  Champion (`Duel.maxChampionsPerDeck` = 1 respecte). Le pool d'un joueur contient `Rarities[rarity].poolCopies`
  exemplaires de chaque carte : 8 Communes x 18 + 2 Rares x 15 = 174 cartes.
- D-M1-02 : le deck M1 ne contient aucune carte de cout 3, 4 ou 5. Quand le tirage de la boutique designe un cout absent,
  l'emplacement prend le cout disponible le plus proche en dessous (brief §10.5) : tout tirage de cout >= 3 devient
  cout 2. Test : au niveau 8, la part de cartes a 2 or dans 10 000 tirages est 0,20 + 0,35 + 0,25 + 0,05 = 0,85
  (plus ou moins 0,02).

### 3.2 Boucle de manche

- D-M1-03 : les 2 joueurs commencent avec `Duel.playerHp` = 100 PV, `Duel.economy.startGold` = 3 or, niveau
  `Duel.startLevel` = 2, 0 unite.
- D-M1-04 : une manche enchaine 4 etats dans cet ordre : `Preparation`, `Combat`, `Resultat`, `Transition`. Aucun autre
  ordre n'est accepte par le serveur ; une requete d'achat hors `Preparation` est ignoree et comptee (T-0011).
- D-M1-05 : la duree de `Preparation` est `Duel.prepSecondsEarly` = 20 s pour les manches 1 a
  `Duel.prepSecondsEarlyRounds` = 3, puis `Duel.prepSecondsLate` = 30 s. Si les 2 joueurs sont "Pret", le combat
  demarre `Duel.prepReadySkipSeconds` = 3 s plus tard.
- D-M1-06 : les manches `Duel.pveRounds` = {1, 6, 11} sont PvE. La manche 1 oppose 3 `tim-cheese` 1 etoile niveau 1
  places en ligne avant colonnes 1 a 3. Manche 6 : 2 `glorbo-fruttodrillo` + 2 `trippi-troppi` 1 etoile. Manche 11 :
  2 `boneca-ambalabu` + 2 `bananella` + 1 `pomita` 2 etoiles. Victoire PvE : `Duel.pveRewardGold` = 3 or + 1 exemplaire
  gratuit d'une carte du deck tiree au hasard. Defaite PvE : 0 degat au joueur, 0 or.
- D-M1-07 : au debut de `Preparation` de la manche n >= 2, le joueur recoit `economy.baseIncome` = 5 or + interets
  `min(floor(or / economy.interestPer), economy.interestMax)` + bonus de serie `economy.streak[min(serie, 5)]`
  + `economy.winBonus` = 1 s'il a gagne la manche n-1. Test : 23 or, serie de 4 victoires = 5 + 2 + 2 + 1 = 10 or.
- D-M1-08 : la boutique a `Duel.shopSlots` = 5 emplacements tires selon `Duel.shopOdds[niveau]` avec
  `Random.new(seed)` cote serveur. Relance : `economy.rerollCost` = 2 or. Acheter `economy.xpPerPurchase` = 4 XP :
  `economy.xpCost` = 4 or. Un achat au-dela de `Duel.benchSize` = 6 unites sur le banc est refuse.
- D-M1-09 : `Duel.xpPerRound` = 2 XP automatiques a chaque debut de `Preparation` (manche >= 2). Montee de niveau selon
  `Duel.xpToNext`, maximum `Duel.maxLevel` = 8. Unites autorisees sur le plateau = niveau du joueur.
- D-M1-10 : 3 exemplaires identiques 1 etoile fusionnent en 1 exemplaire 2 etoiles (x1,8 PV, ATQ, MAG, brief §10.4)
  des que le 3e arrive sur le banc ou le plateau. 3 exemplaires 2 etoiles donnent 1 exemplaire 3 etoiles (x3,24).
  Vente : 1 etoile = `duelCost`, 2 etoiles = 3 x `duelCost` - 1, 3 etoiles = 9 x `duelCost` - 1.
- D-M1-11 : le plateau fait `Combat.boardRows` = 2 lignes x `Combat.boardColumns` = 4 colonnes. Une case contient 0 ou
  1 unite. Le placement d'un joueur n'est envoye a l'adversaire qu'au debut de `Combat`.
- D-M1-12 : a la fin de `Preparation`, le serveur appelle `CombatSim.simulate(seed, teamA, teamB, config)` (T-0010)
  et envoie l'`ActionLog` aux 2 clients. `Combat` dure le temps de lecture du journal, borne a 60 actions.

### 3.3 Synergies et combo en duel

- D-M1-13 : une synergie compte les unites du plateau (pas du banc), 1 fois par slug distinct pour les familles et
  classes (2 `banano` 1 etoile sur le plateau comptent 1 Colosse). Le sous-role Couple compte les couples complets
  (`duoPartners` present sur le plateau).
- D-M1-14 : le palier actif est le plus grand `count` atteint dans `Synergies[nom].tiers`. L'interface affiche les
  synergies actives avant le combat, dans les 0,5 s qui suivent un placement.
- D-M1-15 : le combo C05 est propose au joueur quand `Combos.C05.requires` (un couple complet) est sur le plateau au
  debut du combat. Aucun autre combo n'est actif en M1 (drapeau `Combos[id].enabledM1`, a ajouter par T-0010 si besoin).

### 3.4 Degats au joueur et fin de partie

- D-M1-16 : `palier = min(ceil(manche / 3), Duel.playerDamageTierCap)`.
- D-M1-17 : le perdant d'une manche PvP perd
  `Duel.playerDamageBase + Duel.playerDamageTierMult * palier + Duel.playerDamageStarMult * etoilesSurvivantes`,
  ou `etoilesSurvivantes` est la somme des etoiles des unites ennemies encore en vie. Valeurs : 6 + 4 x palier
  + 2 x etoiles. Test : manche 5 (palier 2), 3 survivantes 1 etoile = 6 + 8 + 6 = 20 PV.
- D-M1-18 : manche nulle (R-M1-58) : chaque joueur perd `floor(degats / 2)` avec `etoilesSurvivantes` = etoiles
  survivantes du camp adverse.
- D-M1-19 : la partie s'arrete des qu'un joueur a 0 PV ou moins a la fin de `Resultat`. Si les 2 tombent a 0 dans la
  meme manche, le joueur avec le plus de PV avant la manche gagne ; a egalite, nul.
- D-M1-20 : un abandon (quitter, deconnexion > 30 s) compte comme une defaite ; le duel continue contre un bot qui
  rejoue le dernier plateau du joueur parti, sans achat.
- D-M1-21 : `tools/sim_duel_length.py` (modele sans combat) donne, avec ces valeurs, une mediane de 10 manches
  (p10 = 8 a 9, p90 = 10 a 12) pour 3 ecarts de force. La formule du brief §10.7 (2 + palier + etoiles) donnait
  une mediane de 20 manches : la config a ete corrigee (decision D-03 du GDD), le brief est a mettre a jour.

## 4. Les 10 unites M1

Slugs de `Config.Roster` (lot L0). Aucun Champion, aucune Epique : M1 teste la boucle, pas la puissance.

| Slug | Rarete (cout) | Classe | Familles / sous-role | Competence (brief §7.2) |
|---|---|---|---|---|
| `tim-cheese` | Commune (1) | Sprinteur | Giungla | Grignotage : 2 attaques rapides |
| `trippi-troppi` | Commune (1) | Assassin | Mare | Bond de crevette : frappe la ligne arriere |
| `ta-ta-ta-ta-sahur` | Commune (1) | Mage | Sahur | Ta-ta-ta-ta : reveille les allies Endormis, 50 % d'Endormir 1 ennemi |
| `banano` | Commune (1) | Colosse | Tentafruit, Couple | Muscles de la villa : Provocation 1 tour + Bouclier |
| `bananella` | Commune (1) | Artilleur | Tentafruit, Couple | Lancer de peau : degats + 25 % d'Etourdi |
| `pomito` | Commune (1) | Guerrier | Tentafruit, Couple | Croque-pomme |
| `pomita` | Commune (1) | Soigneur | Tentafruit, Couple | Compote reconfortante : soin 25 % sur l'allie le plus blesse |
| `myrtila` | Commune (1) | Soigneur | Tentafruit, Couple | Smoothie : petit soin + 20 Energie |
| `glorbo-fruttodrillo` | Rare (2) | Colosse | Mare, Frutta | Machoire juteuse : Provocation 1 tour + 30 % de vol de vie |
| `boneca-ambalabu` | Rare (2) | Colosse | Mare, Macchina | Rebond de pneu : 3 ennemis + Provocation 1 tour |

Valeurs des competences (`Config.Skills`, relues par T-0023). Regle de puissance : 100 energie = 4 Attaques
d'accumulation (R-M1-15, R-M1-16), donc une competence a `cost` 100 vaut 2 a 3 Attaques de base (`power` cumule 2,0 a
3,0), `cost` 90 : 1,8 a 2,7, `cost` 80 : 1,6 a 2,4, `cost` 70 : 1,4 a 2,1. Un soin compte `power` x MAG en PV
(R-M1-11), une Attaque magique de base vaut 0,8 (R-M1-12). Statuts poses : Endormi, Etourdi, Provocation, Bouclier
(4 des 13 statuts de R-M1-35 a R-M1-47).

| Slug | `cost` | `effectId` | `power` et `params` retenus (T-0010 => T-0023) | Justification |
|---|---|---|---|---|
| `tim-cheese` | 80 | `MultiHit` | 2 x 0,75 (inchange) | 1,5 sous le plancher 1,6, mais VIT 140 => 1,9 lancers par combat, le plus haut des 10 |
| `trippi-troppi` | 80 | `StrikeBackline` | 1,60 (inchange) | ATQ 140 contre DEF arriere 20 a 30 : vaut 2 Attaques sur la ligne avant |
| `ta-ta-ta-ta-sahur` | 100 | `WakeAlliesSleepEnemy` | 1,00 => 1,60 (MAG), Endormi 50 % 1 tour | 1,0 valait 1,25 Attaque magique ; Endormi tombe au premier degat (R-M1-36) |
| `banano` | 100 | `TauntShield` | Bouclier 0,20 => 0,25 x HPmax, Provocation 1 tour | 0,20 : 45 % de victoires contre 55 % pour les 2 autres Colosses ; reste sous le Bouclier de C05 (0,30) |
| `bananella` | 100 | `DamageStunChance` | 1,50 => 1,80, Etourdi 25 % 1 tour | 1,5 + 0,25 action ennemie = 1,75 ; 1,8 + 0,25 = 2,05 |
| `pomito` | 90 | `PowerStrike` | 1,80 => 1,50 + `lifestealPct` 0,50 | fiche L0 "se soigne de 50 % des degats", absent de T-0010 ; 1,5 + soin 0,75 = 2,25 |
| `pomita` | 70 | `Heal` | 2,50 (inchange) | 2,5 x MAG 110 = 275 PV = 25 % des PV d'un Guerrier (fiche "soin de 25 %") |
| `myrtila` | 70 | `HealEnergy` | 1,20 => 1,60 (MAG) + 20 energie | 132 PV donnaient 41 % de victoires ; 176 PV reste un "petit soin" sous Compote |
| `glorbo-fruttodrillo` | 100 | `DamageTauntLifesteal` | 1,30 + vol de vie 0,30, Provocation 1 tour (inchange) | 1,3 + 0,39 + Provocation ; 55 % de victoires avec les stats Colosse |
| `boneca-ambalabu` | 100 | `MultiTargetTaunt` | 3 x 0,80, Provocation 1 tour (inchange) | 2,4 Attaques, dans la fourchette |
| 32 autres unites L0 | classe | `PowerStrike` | 1,50 => 2,00 | plancher du cout 100 ; hors M1 |

Mesure (`COMBAT_SIM_M1=2000 lune run tests/run.luau sim/UnitWinRates`, 2 000 combats, equipes de 3 a 5 unites M1
distinctes de meme taille, Equilibre, 1 etoile, seed 20261002 ; taux = combats gagnes par l'equipe de l'unite) :

| Slug | Avant T-0023 | Apres T-0023 | Lancers de competence par combat |
|---|---|---|---|
| `tim-cheese` | 51,2 % | 50,9 % | 1,91 |
| `trippi-troppi` | 53,1 % | 52,4 % | 1,67 |
| `ta-ta-ta-ta-sahur` | 41,8 % | 42,3 % | 1,03 |
| `banano` | 45,1 % | 44,8 % | 1,04 |
| `bananella` | 44,5 % | 44,0 % | 0,70 |
| `pomito` | 54,2 % | 54,4 % | 1,11 |
| `pomita` | 51,8 % | 51,8 % | 1,32 |
| `myrtila` | 41,2 % | 44,3 % | 1,88 |
| `glorbo-fruttodrillo` | 54,7 % | 53,5 % | 1,23 |
| `boneca-ambalabu` | 54,6 % | 54,9 % | 1,23 |

Lecture : les competences pesent peu sur le taux de victoire (1 lancer par combat en moyenne) ; un essai a `power`
2,4 pour `ta-ta-ta-ta-sahur` et `bananella` ne les monte qu'a 44,3 % et 45,2 %. L'ecart de 10 points entre les
Colosses (HP 1 400) et les unites a 750 PV (Mage, Artilleur) vient des stats de classe `Combat.classes`, hors
perimetre de T-0023 (decision D-11, T-0015).

Synergies activables au palier 1 (D-M1-22, test Lune : compter les membres de `Synergies[nom].members` presents) :

| Synergie | Palier 1 | Membres M1 | Effet (`effectId`, params) | Obligatoire M1 |
|---|---|---|---|---|
| Mare | 2 | `trippi-troppi`, `glorbo-fruttodrillo`, `boneca-ambalabu` | `RegenPerTurn` hpMaxPct 0,03 | oui |
| Colosse | 2 | `glorbo-fruttodrillo`, `boneca-ambalabu`, `banano` | `ColossePctHP` pct 0,20 | oui |
| Couple | 1 couple | `banano` + `bananella`, `pomito` + `pomita` | `LienDAmour` energyOnPartnerHit 10, debloque Duo | oui |
| Soigneur | 2 | `pomita`, `myrtila` | `HealPct` pct 0,20 | oui |
| Tentafruit | 2 | 6 unites | `EnergyGainPct` pct 0,15 | si budget (D-07) |

Synergies presentes mais non activables (1 seul membre, aucun effet en M1) : Giungla, Sahur, Frutta, Macchina,
Sprinteur, Assassin, Mage, Artilleur, Guerrier. L'interface les affiche grisees avec "1 / 2".

- D-M1-23 : combo MVP realisable : C05 "Declaration d'amour" (`Combos.C05`, `mvp = true`) avec `banano` + `bananella`
  ou `pomito` + `pomita`. C01 n'est pas realisable en M1 (aucun Champion dans le deck).

## 5. Bot adversaire M1 (DuelBot, T-0011)

Le bot joue la meme boucle que le joueur avec les memes regles d'or, de boutique et de plateau (aucune triche :
meme pool, memes probabilites, pas de vision du plateau adverse pendant `Preparation`).

- D-M1-24 : le bot termine ses achats et se declare "Pret" en `botThinkSeconds` = 3 s (valeur a ajouter dans
  `Config.Duel` par T-0011), tirage `Random.new(seed + manche)`.
- D-M1-25 : plan du bot, choisi a la manche 1 parmi 3 plans ponderes (50 % / 30 % / 20 %) : `Couple` (cible
  `banano`, `bananella`, `pomito`, `pomita`, puis Soigneur), `Mare` (cible les 3 Mare puis `banano`), `Tank`
  (cible les 3 Colosses puis les 2 Soigneurs). Le plan est fixe pour tout le duel.
- D-M1-26 : a chaque `Preparation`, le bot achete dans cet ordre tant qu'il a l'or : (1) toute carte qui complete une
  fusion 2 ou 3 etoiles ; (2) toute carte de son plan ; (3) une carte au hasard si son plateau a moins d'unites que son
  niveau. Il garde `economy.interestPer` = 10 or des la manche 4 si cela ne l'empeche pas de remplir son plateau.
- D-M1-27 : le bot relance la boutique (2 or) au plus 1 fois par manche, seulement si l'or restant apres relance
  est >= 10 et qu'aucune carte du plan n'est affichee.
- D-M1-28 : le bot achete 4 XP (4 or) a la manche 4 et a la manche 7 si son or est >= 12 apres l'achat.
- D-M1-29 : placement : Colosse et Guerrier en ligne avant, colonne la plus proche du centre libre ; Assassin,
  Artilleur, Mage, Soigneur en ligne arriere ; Sprinteur en ligne avant. Les 2 partenaires d'un couple occupent la
  meme colonne quand c'est possible (Duo lisible).
- D-M1-30 : tactique par defaut `Equilibre` pour toutes les unites du bot ; les Colosses passent en `Prudent` si le bot
  a moins de 40 PV.
- D-M1-31 : le bot declenche son Mega Combo des que la jauge est pleine (0 s d'attente) et n'utilise jamais l'ordre
  de focus en M1.
- D-M1-32 : le bot est deterministe : meme seed, memes plateaux du joueur => memes achats et placements (test Lune
  sur 100 seeds).

## 6. Cas limites

| Cas | Comportement attendu | Test |
|---|---|---|
| Joueur ne touche rien pendant 3 manches | les 2 XP automatiques tombent, l'or s'accumule avec interets, le combat se joue avec le plateau existant (0 unite = defaite, degats avec `etoilesSurvivantes` complet) | Lune |
| Deconnexion pendant `Preparation` | plateau conserve ; retour en moins de 30 s : reprise ; sinon D-M1-20 | Studio (HUMAN_ACTION) |
| Les 2 joueurs "Pret" a 0,1 s d'ecart | 1 seul depart de combat, `prepReadySkipSeconds` = 3 s | Lune |
| Achat au 7e emplacement du banc | refuse, or inchange, requete comptee | Lune |
| Fusion qui depasse le plateau (niveau 3, 3 unites, 3e exemplaire arrive sur le plateau) | la fusion a lieu sur la case de l'unite du plateau, les 2 autres cases se liberent | Lune |
| Manche 60 actions nulle | D-M1-18 | Lune |
| Mobile, une main | toutes les actions de `Preparation` sont un tap ou un glisser (aucun double tap, aucun appui long obligatoire) | revue UI (05) |
| Serveur a 1 joueur | le bot remplace le 2e joueur sans file d'attente (fallback solo) | Lune |

## 7. Tickets derives

- T-0010 : CombatSim (spec combat).
- T-0011 : DuelService + DuelBot (D-M1-01 a D-M1-32), ajout de `Duel.botThinkSeconds`.
- T-0015 : harnais 10 000 duels, mesures M-D-01, M-D-06, M-D-07, M-D-08.
- A ouvrir (Game Designer) : mise a jour du brief §10.7 et §11.3 avec les valeurs de la config (D-02, D-03).
