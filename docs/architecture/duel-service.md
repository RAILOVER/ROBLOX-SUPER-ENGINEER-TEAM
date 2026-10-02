# DuelService : architecture du duel TFT (T-0011)

Source normative : `design/specs/M1-duel-minimal.md` (D-M1-01 a D-M1-32). Le serveur est la seule autorite : il tire
la boutique, compte l'or, simule le combat (`CombatSim`, T-0010) et applique les degats. Le client n'envoie que des
intentions et ne recoit que des vues. Toute la regle de jeu est dans des modules purs sous `src/shared/Duel/`
(aucun `game`, config injectee), testes sous Lune ; la couche Roblox (`src/server/Services/Duel*.luau`) ne fait
que du minutage, du transport et de la garde.

## 1. Modules

| Module | Role | Regles | Pur / Lune |
|---|---|---|---|
| `src/shared/Duel/Economy.luau` | revenu, interets, series, XP, prix de vente, degats au joueur, duree de Preparation | D-M1-05, D-M1-07, D-M1-09, D-M1-10, D-M1-16 a D-M1-18 | oui |
| `src/shared/Duel/Shop.luau` | pool de copies, tirage par `shopOdds[niveau]`, repli de cout, retour au pool, triple pour fusion | D-M1-01, D-M1-02, D-M1-08, D-M1-10 | oui |
| `src/shared/Duel/Seat.luau` | 1 siege : achat, relance, XP, placement 2 x 4, banc 6, vente, fusion, tactique, equipe pour CombatSim | D-M1-08 a D-M1-11 | oui |
| `src/shared/Duel/DuelState.luau` | etat complet, transitions, PvE, degats, fin, abandon, `apply` des intentions, `toClientView` | D-M1-03 a D-M1-06, D-M1-12, D-M1-19, D-M1-20 | oui |
| `src/shared/Duel/BotPolicy.luau` | decision du bot : plan, achats, relance, XP, placement, tactique | D-M1-25 a D-M1-32 | oui |
| `src/shared/Duel/Decks.luau` | deck fixe M1 (10 slugs) et troupes PvE des manches 1, 6, 11 | D-M1-01, D-M1-06 | oui |
| `src/shared/Remotes/DuelRemotes.luau` | noms, schemas d'arguments, phase requise et cooldown des remotes, validation pure | D-M1-04 | oui |
| `src/shared/Types/Duel.luau` | types exportes : `State`, `Seat`, `OwnedUnit`, `ClientView`, payloads | contrat T-0012 | oui |
| `src/server/Services/DuelService.luau` | RemoteEvent, RemoteGuard, sieges par joueur, lobby 2 humains ou bot, reconnexion | D-M1-04, D-M1-20 | non |
| `src/server/Services/DuelMatch.luau` | boucle d'un duel avec `task.wait`, bots, diffusion des vues et journaux | D-M1-05, D-M1-12 | non |
| `src/server/Services/DuelBot.luau` | memoire du bot et delai de reflexion (3 s) autour de `BotPolicy` | D-M1-24 | non |

Tous les fichiers font moins de 400 lignes et commencent par `--!strict`.

## 2. Diagramme d'etats

```text
         JoinDuel (2 humains, ou 1 humain + bot)
Lobby ------------------------------------------> Preparation (manche n)
                                                     | minuteur : 20 s (manches 1 a 3), 30 s ensuite,
                                                     | ramene a 3 s quand les 2 sieges sont Pret
                                                     v
                                                  Combat  : CombatSim.simulate(seed serveur), duree = actions x 0,8 s
                                                     |      (PvE manches 1, 6, 11 : 1 combat par siege)
                                                     v
                                                  Resultat : PV, series, recompense PvE, 4 s + 3 s de transition
                                                     |
                             un siege a 0 PV ? ------+------ non : Preparation (manche n + 1)
                                                     |
                                                    oui
                                                     v
                                                    Fin : DuelEnded (winnerSeat, reason = hp | forfeit | draw)
```

Transitions pures (`DuelState`) : `beginPreparation`, `beginCombat`, `beginResult`, `endResult` (qui appelle
`checkEnd`), `forfeit`. `tick(state, dt)` decremente le minuteur et retourne `true` quand la phase est finie.
`DuelMatch.run` enchaine ces appels avec `task.wait(0.25)` ; les bots jouent 3 s apres le debut de Preparation.

Debut de Preparation (manche >= 2) : revenu `5 + interets (1 par 10 or, max 5) + serie (streak[min(serie, 5)])
+ 1 si victoire`, 2 XP automatiques, nouvelle boutique (les cartes non vendues retournent au pool).

Degats au perdant PvP : `6 + 4 x palier + 2 x etoilesSurvivantes`, `palier = min(ceil(manche / 3), 5)`. Manche
nulle : chaque siege perd `floor(degats / 2)`. PvE : 0 degat ; victoire = 3 or + 1 carte du deck au hasard.

## 3. Contrats des remotes

Dossier `ReplicatedStorage.DuelRemotes` (cree par `DuelService.start`), 1 `RemoteEvent` par nom. Les noms et
schemas vivent uniquement dans `src/shared/Remotes/DuelRemotes.luau` ; les types des payloads dans
`src/shared/Types/Duel.luau`. Cooldown : 100 ms par joueur et par remote.

### 3.1 Client vers serveur (10 remotes, `FireServer`)

| Remote | Arguments | Phase exigee | Effet serveur |
|---|---|---|---|
| `JoinDuel` | aucun | aucune | lobby : 2e humain si un joueur attend, sinon attente 5 s puis bot ; reconnexion si le joueur a deja un siege |
| `BuyShopSlot` | `slot: number` (1 a 5) | Preparation | achat si or suffisant et banc non plein (ou fusion completee) |
| `Reroll` | aucun | Preparation | relance a 2 or |
| `BuyXp` | aucun | Preparation | 4 XP pour 4 or |
| `PlaceUnit` | `instanceId: string` (`u%d+`), `row: number` (1 a 2), `col: number` (1 a 4) | Preparation | placement, echange si la case est occupee, refus si plateau = niveau |
| `BenchUnit` | `instanceId: string` | Preparation | retour au banc si une place existe |
| `SellUnit` | `instanceId: string` | Preparation | vente, exemplaires rendus au pool |
| `SetTactic` | `tactic: "Agressif" / "Equilibre" / "Prudent"`, `instanceId: string?` | Preparation | tactique d'une unite, ou de toutes les unites du siege sans identifiant |
| `OrderFocus` | `cell: number` (0 a 7) | Combat | accepte et ignore en M1 (combat simule d'un bloc, D-M1-12) |
| `Ready` | aucun | Preparation | siege Pret ; les 2 Pret ramenent le minuteur a 3 s |

Garde d'une requete, dans l'ordre : nombre et schema des arguments (`DuelRemotes.validateArgs`), cooldown
(`RemoteGuard.cooldown`), siege occupe par le joueur, phase du duel, puis `DuelState.apply` qui refuse tout ce qui
est impossible (or, banc, case, unite inconnue). Chaque refus incremente `RemoteGuard.strike`, le compteur global
`DuelService.invalidRequests()` et `seat.invalidRequests` ; aucune erreur serveur n'est levee.

### 3.2 Serveur vers client (3 remotes, `FireClient`)

| Remote | Payload (type exporte) | Quand |
|---|---|---|
| `DuelState` | `ClientView` | a chaque changement d'etat du siege, a chaque seconde du minuteur, a chaque transition |
| `CombatLog` | `CombatLogPayload` | au debut de Combat (PvP : le meme journal aux 2 sieges, PvE : 1 journal par siege) |
| `DuelEnded` | `DuelEndedPayload` | a l'entree en Fin |

```luau
type ClientView = {
	phase: "Lobby" | "Preparation" | "Combat" | "Resultat" | "Fin",
	round: number,
	isPve: boolean,
	timerSeconds: number,
	seatIndex: number,
	me: {
		seatIndex: number, kind: "human" | "bot" | "ghost", displayName: string,
		hp: number, level: number, streak: number, ready: boolean, boardCount: number,
		gold: number, xp: number, xpToNext: number, nextIncome: number,
		bench: { OwnedUnit }, board: { OwnedUnit }, shop: { { slug: string, cost: number, sold: boolean } },
	},
	opponent: {
		seatIndex: number, kind: "human" | "bot" | "ghost", displayName: string,
		hp: number, level: number, streak: number, ready: boolean, boardCount: number,
		board: { OwnedUnit }, -- vide avant Combat (D-M1-11)
	},
	lastOutcome: ("win" | "loss" | "draw")?,
}
type OwnedUnit = { instanceId: string, slug: string, stars: number, tactic: Tactic, row: number, col: number }
-- row = col = 0 sur le banc ; instanceId = "u" .. compteur du siege

type CombatLogPayload = {
	round: number, isPve: boolean,
	side: "A" | "B", -- camp du destinataire dans le journal
	teams: { A: { UnitInstance }, B: { UnitInstance } },
	result: CombatResult, -- docs/architecture/combat.md section 3 (winner, turns, actions, actionLog, version)
	playerDamage: { number }, -- index 1 = siege 1, index 2 = siege 2
}

type DuelEndedPayload = {
	rounds: number, winnerSeat: number?, youWon: boolean, hp: { number }, reason: "hp" | "forfeit" | "draw",
}
```

## 4. Ce que le client ne peut jamais decider

- l'or, les interets, les series, l'XP, le niveau : calcules par `Economy` depuis `Config.Duel` ;
- le contenu de la boutique : `Shop.roll` avec le `Rng` du siege (seed serveur), le client ne recoit que le resultat ;
- le resultat du combat, les degats, la fin de partie : `CombatSim.simulate` avec un seed serveur, puis `DuelState` ;
- la boutique, le banc, l'or, le pool de l'adversaire : absents de `ClientView` ; son plateau n'apparait qu'a partir
  de Combat ;
- le minuteur : seul le serveur le decremente, `Ready` ne fait que le raccourcir a 3 s si les 2 sieges sont prets ;
- la phase : une intention hors phase est refusee et comptee (`wrong_phase`).

Le bot (`BotPolicy`) joue avec les memes regles via `DuelState.apply` : meme pool, memes probabilites, aucune vision
du plateau adverse pendant Preparation.

## 5. Chiffres mesures (`lune run tests/run.luau Duel`, 42 tests, 0 echec)

- Odds de boutique : 100 000 tirages par niveau (2 a 8) sur un deck a 5 couts, ecart < 1 point par cout.
- Repli D-M1-02 : niveau 8, deck M1, 10 000 tirages : part de cartes a 2 or = 0,85 plus ou moins 0,02.
- Economie : 1 000 manches simulees, or jamais negatif, interets max 5, revenu max 14 ; exemple spec 23 or et
  serie 4 = 10 or ; degats manche 5 avec 3 survivantes = 20 PV.
- 100 duels complets bot contre bot (`DuelState` + `CombatSim.simulate`, seeds 1 a 100) : mediane 8 manches,
  min 7, max 12, 60 duels sur 100 en 8 a 11 manches (cible `Config.Duel.targetRounds`), 0 nul. Repartition :
  7 manches x 33, 8 x 27, 9 x 21, 10 x 12, 12 x 7. Les 7 duels a 12 manches passent la manche 11 PvE sans degat.
  Le modele sans combat de la spec (D-M1-21) donnait une mediane de 10 : le combat reel rend les manches plus
  tranchees (etoiles survivantes elevees), a mesurer sur 10 000 duels par T-0015 avant tout reglage.
- Bot : 100 seeds rejoues 2 fois, memes achats et placements ; plans sur 300 seeds proches de 50 / 30 / 20.

## 6. Choix d'implementation a confirmer (Game Designer)

1. `botThinkSeconds` (3 s), duree de Resultat (4 s) et de Transition (3 s) ne sont pas dans `Config.Duel` :
   constantes `BotPolicy.THINK_SECONDS`, `DuelState.RESULT_SECONDS`, `DuelState.TRANSITION_SECONDS` (ticket T-0025).
2. Achat banc plein : refuse, sauf si la carte achetee complete une fusion (3e exemplaire 1 etoile), comme dans TFT.
3. `SetTactic` sans `instanceId` applique la tactique a toutes les unites du siege (le brief parle d'un reglage par
   unite, la commande demandee par T-0011 n'avait qu'un argument : les 2 sont servis).
4. Carte gratuite PvE : perdue si le banc est plein.
5. Deconnexion : siege conserve `Config.Duel.ghostAfterSeconds` = 15 s, puis abandon (la spec cite 30 s en texte ;
   la config fait foi).
6. Lobby : si le serveur a au moins 2 joueurs, `JoinDuel` attend 5 s un 2e humain, sinon le bot entre sans attente.
