---
id: T-0025
title: Ajouter botThinkSeconds, resultSeconds et transitionSeconds dans Config.Duel
role: 02-game-designer
phase: P1-greybox
status: backlog
type: spec
priority: P2
depends_on: [T-0011]
spec: design/specs/M1-duel-minimal.md
acceptance:
  - "Config.Duel.botThinkSeconds (3), resultSeconds (4), transitionSeconds (3) existent et sont testes dans tests/unit/Config.spec.luau"
  - "BotPolicy.THINK_SECONDS, DuelState.RESULT_SECONDS et DuelState.TRANSITION_SECONDS lisent Config.Duel (ticket 04-dev-serveur a ouvrir)"
  - "docs/architecture/duel-service.md section 6 point 1 retire"
---

## Contexte

D-M1-24 demande `Duel.botThinkSeconds` = 3 s et la spec §2 fixe Resultat = 4 s et Transition = 3 s, mais ces 3 valeurs
n'existent pas dans `src/shared/Config/Duel.luau`. T-0011 ne modifie pas `src/shared/Config/` (QA T-0015 et GD T-0023
travaillent dessus) et les a posees en constantes de module.

## Travail attendu

- Ajouter les 3 valeurs dans `src/shared/Config/Duel.luau` et le test d'integrite.
- Confirmer ou corriger les 6 choix de `docs/architecture/duel-service.md` section 6 (achat banc plein avec fusion,
  SetTactic global, carte PvE perdue si banc plein, 15 s avant abandon, lobby 5 s).

## Hors perimetre

Equilibrage des degats et de la duree des duels (T-0015).

## Verification

```bash
lune run tests/run.luau Config
python3 tools/check_repo.py
```

## Non verifie

A remplir a la livraison.
