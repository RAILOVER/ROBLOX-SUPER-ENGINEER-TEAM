---
id: T-0032
title: Contrat DuelRemotes : intention MegaCombo et PV max des unites dans CombatLogPayload
role: 04-dev-serveur
phase: P1-greybox
status: backlog
type: feature
priority: P2
depends_on: [T-0011, T-0012]
spec: design/specs/M1-duel-minimal.md
acceptance:
  - "DuelRemotes.clientToServer.MegaCombo existe (phase Combat, needsSeat) ou la decision 'Mega Combo automatique seulement en M1' est ecrite dans docs/architecture/duel-service.md"
  - "CombatLogPayload.teams.A/B portent hpMax par unite (ou un champ equivalent) pour que le client n'ait plus a le deduire du journal"
  - "tests Lune existants verts ; docs/architecture/duel-service.md section 3 mise a jour"
---

## Contexte

T-0012 (HUD greybox) a besoin de 2 informations que le contrat T-0011 ne fournit pas. Le client contourne cote
affichage (voir `docs/architecture/client-duel.md` section 3) :

1. Le brief demande un bouton Mega Combo qui envoie une intention. `DuelRemotes.clientToServer` n'a pas d'entree
   `MegaCombo` : le Mega se declenche automatiquement dans `CombatSim`. Le bouton est affiche grise avec la jauge lue
   dans `ActionEntry.gauges.mega`. `HudController` appelle `DuelController.isIntentOpen("MegaCombo")` : des que
   l'entree existe dans le contrat, le bouton s'active sans modification client.
2. Les barres de PV des unites pendant la lecture ont besoin d'un PV max. Le client ne lit pas les stats du roster
   (regle AGENTS.md) ; il deduit le max du journal (PV apres + degats du premier coup recu). C'est approximatif pour
   une unite d'abord soignee ou brulee.

## Travail attendu

- Decider : intention `MegaCombo` manuelle (phase Combat) ou automatique seulement en M1. Dans les 2 cas, ecrire la
  decision dans `docs/architecture/duel-service.md`.
- Ajouter `hpMax` (nombre) a chaque `UnitInstance` des equipes envoyees dans `CombatLogPayload`, ou un tableau
  `hpMax: { [string]: number }` par case, calcule par le serveur depuis `Setup`.
- Mettre a jour `src/shared/Types/Duel.luau` et la section 3 de `docs/architecture/duel-service.md`.

## Non verifie

A remplir a la livraison.
