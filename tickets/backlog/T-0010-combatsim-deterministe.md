---
id: T-0010
title: CombatSim deterministe (tour par tour, synergies, Mega Combo)
role: 04-dev-serveur
phase: P1-greybox
status: backlog
type: feature
priority: P0
depends_on: [T-0009]
spec: design/specs/M1-combat-tour-par-tour.md
acceptance:
  - "src/shared/Combat/CombatSim.luau pur (aucun service Roblox, config injectee en parametre) : simulate(seed, teamA, teamB, config) -> { winner, actionLog, turns }"
  - "meme seed + memes equipes = meme ActionLog, verifie par un test Lune sur 100 seeds"
  - "actions Attaque, Competence, Garde, Duo, MegaCombo implementees; 13 statuts de Config.Combat.statuses appliques"
  - "effets de synergie pour les 4 synergies M1 et combo C05 ou C01 implementes via effectId"
  - "10 000 duels aleatoires sous Lune sans erreur ni boucle infinie (mort subite a 40 actions, nul a 60)"
  - "tools/lint.sh et lune run tests/run.luau passent; aucun module au-dessus de 400 lignes (decouper en Timeline, Actions, Effects, Status)"
---

## Contexte

Coeur du jeu (brief §11). Le serveur rejoue la simulation; le client ne fait qu'animer l'ActionLog. Les modules doivent
rester purs pour tourner sous Lune (voir tests/run.luau) et plus tard dans Studio.

## Travail attendu

- `src/shared/Combat/{CombatSim,Timeline,Actions,Effects,Status,Rng}.luau`
- `tests/unit/Combat*.spec.luau`
- Doc courte `docs/architecture/combat.md` : format de l'ActionLog (versionne).

## Hors perimetre

Remotes, DataStore, UI, equilibrage des valeurs (QA T-0015).

## Verification

```bash
tools/lint.sh
lune run tests/run.luau Combat
```

## Non verifie

A remplir a la livraison.
