---
id: T-0010
title: CombatSim deterministe (tour par tour, synergies, Mega Combo)
role: 04-dev-serveur
phase: P1-greybox
status: review
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

## Livre

- `src/shared/Combat/` : CombatSim, Setup, Rng, Timeline, Formulas, Actions, SkillEffects, Targeting, Effects, Status,
  Tactics, ActionLog (12 modules, 55 a 317 lignes chacun). Types dans `src/shared/Types/Combat.luau`.
- `src/shared/Config/Skills.luau` (10 competences M1 + competence par defaut), enregistre dans `Config.Skills`.
- Tests : `tests/unit/CombatDeterminism`, `CombatRulesA` (R-M1-01 a 30), `CombatRulesB` (R-M1-31 a 60),
  `CombatRobustness` (10 000 combats), `CombatModuleSize`. `tests/run.luau` : chargement `loadShared("Dossier/Module")`,
  duree affichee, `LUNE_TEST_TIMER=1` pour la duree par spec.
- `docs/architecture/combat.md`. Tickets ouverts : T-0021 (relecture Skills), T-0022 (ambiguites, R-M1-54).
- Mesures : 10 000 combats en 10,88 s, 0 erreur, 0,88 % de nuls, 37,5 actions en moyenne, maximum 60.

## Non verifie

- Execution dans Roblox Studio (Rojo + TestEZ) : impossible sur Linux, seul Lune a tourne. Le type
  `CombatConfig = typeof(require(script.Parent.Parent.Config))` et les `require` relatifs sont valides par luau-lsp
  avec la sourcemap Rojo, pas en jeu.
- R-M1-54 (miroir Agressif contre Prudent entre 35 et 65 %) : mesure 86 / 8 / 6, hors cible. Le test affiche la
  mesure sans echouer ; la decision revient au Game Designer (T-0022) et au QA (T-0015).
- Valeurs de `Config.Skills` : provisoires, non relues (T-0021).
- Effets des synergies de palier 2 et plus et combos autres que C05 : non implementes, journalises dans
  `result.unimplemented` (comportement verifie, valeurs non).
- Performance dans le runtime Roblox (le chiffre de 10,88 s est mesure sous Lune 0.10.5).
