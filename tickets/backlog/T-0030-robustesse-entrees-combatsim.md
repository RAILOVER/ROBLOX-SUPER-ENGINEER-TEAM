---
id: T-0030
title: Robustesse des entrees de CombatSim (orderFocus, tactique inconnue, seeds, equipes vides)
role: 04-dev-serveur
phase: P1-greybox
status: backlog
type: code
priority: P2
depends_on: [T-0010, T-0015]
spec: design/specs/M1-combat-tour-par-tour.md
acceptance:
  - "CombatSim.orderFocus retourne false (ou leve une erreur explicite) pour une case hors grille, un camp inconnu ou un combat termine, sans consommer l'ordre"
  - "une tactique inconnue est refusee par Setup.newState avec un message explicite, pas par un index nil dans Tactics"
  - "le comportement pour une seed hors de 0 a 2^31 - 1 et pour une equipe vide est soit refuse a Setup, soit ecrit dans docs/architecture/combat.md"
  - "les tests marques 'observe' dans tests/unit/CombatEdgeCases.spec.luau sont mis a jour vers le comportement choisi"
---

## Contexte

La revue QA de T-0010 (`docs/reviews/T-0010.md`, T-0015) a sonde les entrees limites de `src/shared/Combat/`.
Aucun point n'est bloquant pour le M1 (DuelService valide les entrees avant d'appeler CombatSim), mais le module
partage accepte ou plante de facon non explicite dans 5 cas. Les comportements actuels sont fixes par
`tests/unit/CombatEdgeCases.spec.luau` (tests marques "observe") pour que tout changement soit visible.

## Points observes

1. `CombatSim.orderFocus(state, "A", -5)` et `orderFocus(state, "B", 99)` retournent `true` et consomment l'ordre
   de focus (1 seul par combat, `Combat.focusOrdersPerCombat`). Un joueur qui vise une case vide perd son ordre
   sans effet. `orderFocus(state, "C", 0)` plante : `CombatSim.luau:163 attempt to index nil with
   'focusOrdersUsed'`.
2. `orderFocus` apres `state.winner ~= nil` retourne `true` et compte l'ordre. Sans effet (step reste `false`),
   mais le compteur ment.
3. Tactique inconnue (`tactic = "Zzz"`) : acceptee par `Setup.newState`, plante au 1er tour de l'unite dans
   `Tactics.luau:97 attempt to index nil with 'guardBelowHp'`. Attendu : `assert` dans Setup comme pour le slug
   (`unite inconnue`) et la case (`case invalide`).
4. Seeds `-1`, `1.5`, `2^31` : acceptees, combat termine et deterministe, mais hors du domaine documente
   (0 a 2^31 - 1). A refuser ou a documenter (`Rng.new` normalise ?).
5. Equipe A vide : `winner = "B"`, 0 action, `mvp` = 1re unite de B (0 degat). 2 equipes vides : `"draw"` avec
   0 action. A refuser a Setup (`equipe vide`) ou a documenter.

Mineur, documentation : dans l'ActionLog, `hp` et `targets` sont cles par case (`A0`) alors que `actor` et
`mvp` sont `slug.sideCell` (`banano.A0`). Le client doit appliquer `ActionLog.caseOf` pour relier les deux ;
a ecrire dans `docs/architecture/combat.md` section ActionLog.

## Hors perimetre

Valeurs de `Config` (T-0023, T-0024), DuelService et validation des remotes (T-0011).

## Verification

```bash
tools/lint.sh
lune run tests/run.luau CombatEdgeCases
python3 tools/check_repo.py
```

## Non verifie

A remplir a la livraison.
