---
id: T-0012
title: UI greybox du duel (mobile paysage) et lecture de l'ActionLog
role: 05-dev-client-ui
phase: P1-greybox
status: backlog
type: feature
priority: P0
depends_on: [T-0011]
spec: design/specs/M1-duel-minimal.md
acceptance:
  - "src/client/Controllers/DuelController.luau + UI en Frames plates : boutique 5 cases, banc 6, plateau 2x4, or, PV, manche, panneau synergies, timeline, bouton Mega Combo"
  - "glisser-deposer tactile et souris; toutes les zones tactiles font au moins 44 px a 1280x720"
  - "le client rejoue l'ActionLog avec des cubes colores et des nombres de degats; 0,8 s max par action en PvP (Config.Combat)"
  - "aucune valeur de gameplay calculee cote client; le client n'envoie que des intentions (acheter slot N, poser slug en case X)"
  - "tools/lint.sh passe"
---

## Contexte

Brief §11.9, §15.6 (version greybox), §16.3. Cubes, couleurs plates, texte lisible : aucun asset final (AGENTS.md).

## Travail attendu

- `src/client/Controllers/{DuelController,CombatPlayback,HudController}.luau`
- `docs/architecture/client-duel.md` : flux des remotes et etats d'ecran.

## Hors perimetre

Ouverture d'oeufs, menus, boutique Robux (M2+).

## Verification

```bash
tools/lint.sh
```

## Non verifie

A remplir a la livraison (capture Studio = HUMAN_ACTION).
