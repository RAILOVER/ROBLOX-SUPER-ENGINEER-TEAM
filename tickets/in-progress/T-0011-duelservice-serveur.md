---
id: T-0011
title: DuelService serveur (boucle TFT, remotes gardes, bot adversaire)
role: 04-dev-serveur
phase: P1-greybox
status: in-progress
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

- `src/server/Services/DuelService.luau`, `src/server/Services/DuelBot.luau`, `src/shared/Duel/Economy.luau` (pur)
- `src/shared/Remotes/DuelRemotes.luau` : noms et contrats des remotes (types stricts)

## Hors perimetre

Matchmaking, trophees, DataStore (M2+), UI.

## Verification

```bash
tools/lint.sh
lune run tests/run.luau Duel
```

## Non verifie

A remplir a la livraison (le test en Studio reel est HUMAN_ACTION).
