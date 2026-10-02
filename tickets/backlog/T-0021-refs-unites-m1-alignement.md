---
id: T-0021
title: Aligner les fiches de references art/refs sur les 10 unites M1 de la spec
role: 03-directeur-artistique
phase: P1-greybox
status: backlog
type: spec
priority: P2
depends_on: [T-0009, T-0014]
spec: design/specs/M1-duel-minimal.md
acceptance:
  - "art/refs/<slug>/REFS.md existe pour les 10 slugs de design/specs/M1-duel-minimal.md section 4 (meme format que les fiches T-0014 : 3 URL publiques, traits signature, couleurs, note de moderation)"
  - "les fiches T-0014 qui ne sont pas dans la liste M1 sont conservees (elles servent pour M2)"
  - "python3 tools/check_repo.py : 0 erreur"
---

## Contexte

T-0014 (bible de style) a produit 10 fiches de references en parallele de T-0009 (specs M1), avant que la liste
des 10 unites M1 soit connue. Resultat : 1 seul slug commun (`trippi-troppi`). Les 9 autres unites M1
(`tim-cheese`, `ta-ta-ta-ta-sahur`, `banano`, `bananella`, `pomito`, `pomita`, `myrtila`, `glorbo-fruttodrillo`,
`boneca-ambalabu`) n'ont pas de fiche.

## Travail attendu

Voir acceptance. Pas d'image, pas d'asset : documents uniquement. Le protocole 64 px (docs/reports/legibilite-64px.md)
et la grille vision de la bible s'appliqueront a ces 10 unites en M2.

## Non verifie

A remplir par l'agent.
