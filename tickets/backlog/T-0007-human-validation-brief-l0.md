---
id: T-0007
title: HUMAN_ACTION valider le brief BATTLEROT et le lot L0 (42 personnages)
role: 01-producteur
phase: P0-preparation
status: backlog
type: arbitrage
priority: P0
depends_on: [T-0006]
spec: design/brief/BATTLEROT.md
acceptance:
  - "l'humain a repondu par ecrit (commentaire de PR ou message) : brief valide ou liste de corrections"
  - "l'humain a coche ou barre chaque personnage de design/roster/lot-L0.md"
  - "les corrections demandees sont reportees dans le brief et le ticket passe en done"
---

## Contexte

Gate P0 du brief §21. Les agents ne valident pas leur propre travail (R4) : le brief corrige par le Producteur doit etre
accepte par l'humain avant tout asset (M2) et avant toute entree de lot L1. Les tickets M1 greybox (cubes, config L0) peuvent avancer en parallele : un nom retire en L0 se retire en une ligne de config (R2).

## Travail attendu (humain)

1. Lire `design/brief/BATTLEROT.md` §0.1 (ecarts) et §7.4 / §7.5.
2. Confirmer le lot L0 ou retirer des noms.
3. Dire si la validation juridique des noms (R6) doit etre lancee des maintenant ou avant publication.

## Hors perimetre

Shortlist L1 (T-0008).

## Verification

Reponse ecrite de l'humain, collee dans ce ticket.

## Non verifie

Sans objet.
