---
id: T-0012
title: UI greybox du duel (mobile paysage) et lecture de l'ActionLog
role: 05-dev-client-ui
phase: P1-greybox
status: review
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

## Livre

- `src/shared/Duel/PlaybackPlan.luau` (pur) + `tests/unit/PlaybackPlan.spec.luau` : 100 combats L0 et 100 combats M1,
  1 etape par entree, PV finaux identiques, duree moyenne 22,4 s (L0) et 24,5 s (M1) pour une cible 20 a 35 s.
- `src/client/Controllers/{DuelController,HudController,DragDrop,CombatPlayback,CameraController}.luau`,
  `src/client/UI/{Theme,ShopPanel,BoardPanel,StatusPanel,SynergyPanel,TimelinePanel,ActionBar,Banner}.luau`,
  `src/client/init.client.luau`.
- `docs/architecture/client-duel.md`, tickets `T-0031` (playtest humain) et `T-0032` (contrat : MegaCombo, hpMax).

## Hors perimetre

Ouverture d'oeufs, menus, boutique Robux (M2+).

## Verification

```bash
python3 tools/check_repo.py
tools/lint.sh
lune run tests/run.luau
rojo build default.project.json -o build/battlerot.rbxl
```

## Non verifie

- Rendu reel dans Roblox Studio (Play Solo contre le bot, tactile emule, 2 joueurs en test local) : cette machine
  n'a pas Studio. Checklist chiffree dans `tickets/backlog/T-0031-human-playtest-m1-studio.md` (HUMAN_ACTION).
- Tailles tactiles reelles (>= 44 px a 1280x720 et sur telephone emule) : garanties par construction (UIScale >= 1,
  UISizeConstraint 44 x 44) mais non mesurees dans Studio (T-0031 C4 et D4).
- Comportement de `PlayerGui:GetGuiObjectsAtPosition` avec `ScreenInsets = DeviceSafeInsets` sur un appareil a
  encoche : non observe (T-0031 D1, D2).
- Duree reelle du combat anime (task.wait cumule) contre `PlaybackPlan.totalSeconds` : mesuree sous Lune seulement
  (T-0031 B6).
- Le bouton Mega Combo n'envoie rien : aucune intention `MegaCombo` dans le contrat T-0011 (ticket T-0032 ouvert
  pour 04-dev-serveur). Le PV max des unites est deduit du journal (T-0032).
