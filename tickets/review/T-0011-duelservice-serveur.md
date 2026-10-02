---
id: T-0011
title: DuelService serveur (boucle TFT, remotes gardes, bot adversaire)
role: 04-dev-serveur
phase: P1-greybox
status: review
type: feature
priority: P0
depends_on: [T-0010]
spec: design/specs/M1-duel-minimal.md
acceptance:
  - "src/server/Services/DuelService.luau : manches, or, interets, series, boutique, banc 6, plateau 2x4, degats au joueur selon Config.Duel"
  - "tous les remotes passent par RemoteGuard (types, bornes, etat de manche, frequence); une requete invalide est ignoree et comptee"
  - "un bot serveur (achats aleatoires ponderes) permet un duel joueur contre IA complet"
  - "le tirage de la boutique utilise Random.new(seed) cote serveur; le client ne recoit que le resultat"
  - "test Lune de la logique economique (or, interets, series) sur 1 000 manches simulees"
  - "tools/lint.sh et lune run tests/run.luau passent"
---

## Contexte

Brief §10 et §16. Le DuelService orchestre la preparation puis appelle CombatSim et envoie l'ActionLog au client.

## Travail attendu

- `src/server/Services/DuelService.luau`, `DuelMatch.luau`, `DuelBot.luau` (couche Roblox : remotes, task.wait, bot)
- `src/shared/Duel/Economy.luau`, `Shop.luau`, `Seat.luau`, `DuelState.luau`, `BotPolicy.luau`, `Decks.luau` (purs)
- `src/shared/Remotes/DuelRemotes.luau` : noms et contrats des remotes (types stricts), `src/shared/Types/Duel.luau`
- `tests/unit/DuelEconomy.spec.luau`, `DuelShop.spec.luau`, `DuelState.spec.luau`, `DuelBot.spec.luau` (42 tests)
- `docs/architecture/duel-service.md` : diagramme d'etats, contrats, chiffres mesures

## Hors perimetre

Matchmaking, trophees, DataStore (M2+), UI.

## Verification

```bash
tools/lint.sh
lune run tests/run.luau Duel
```

## Non verifie

- `DuelService.luau`, `DuelMatch.luau`, `DuelBot.luau` touchent `Players`, `RemoteEvent`, `task.wait` : non
  executables sous Lune. Verifie seulement par `luau-lsp analyze` (types) et `selene`. HUMAN_ACTION : lancer Play en
  Studio avec 1 joueur (bot) puis 2 joueurs (Team Test), verifier que la boutique, les achats, le combat et la fin de
  duel arrivent au client via `ReplicatedStorage.DuelRemotes` (le client T-0012 n'existe pas encore).
- Cooldown 100 ms et compteur `RemoteGuard.strike` : logique relue, non mesuree sans client.
- Reconnexion (D-M1-20) : siege garde 15 s (`Config.Duel.ghostAfterSeconds`) puis abandon ; non testable sous Lune.
- Duree des duels : 100 duels bot contre bot (pas humain reel) donnent une mediane de 8 manches, 60 % en 8 a 11 ;
  la mesure sur 10 000 duels et l'equilibrage sont T-0015. Aucun jugement "fun" ou "jouable".
- `botThinkSeconds`, `resultSeconds`, `transitionSeconds` absents de `Config.Duel` : constantes de module, ticket
  T-0025 ouvert pour le game designer.
