---
id: T-0008
title: HUMAN_ACTION valider la shortlist L1 de memes recents
role: 01-producteur
phase: P0-preparation
status: backlog
type: arbitrage
priority: P1
depends_on: [T-0006]
spec: design/roster/lot-L1-memes-recents.md
acceptance:
  - "chaque ligne L1-01 a L1-08 est marquee retenue ou rejetee par l'humain"
  - "la famille Viral et le combo C14 sont acceptes ou renvoyes au Game Designer"
  - "aucun nom L1 n'entre dans src/shared/Config/Roster/ avant ce ticket en done"
---

## Contexte

Pipeline de tendances (brief §7.5, etape 8). La shortlist vient de `docs/reports/trends-2026-10-01.md`.
Six Seven est propose, pas pre-valide.

## Travail attendu (humain)

Cocher les personnages retenus; dire si des cles d'API (YouTube, Giphy, Reddit) peuvent etre fournies pour une
seconde passe de mesure.

## Hors perimetre

Fiches detaillees et assets (tickets M2+ apres validation).

## Verification

Reponse ecrite de l'humain, collee dans ce ticket.

## Non verifie

Sans objet.
