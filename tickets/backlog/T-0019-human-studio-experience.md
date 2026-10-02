---
id: T-0019
title: HUMAN_ACTION creer l'experience Roblox BATTLEROT et brancher Rojo
role: 01-producteur
phase: P1-greybox
status: backlog
type: arbitrage
priority: P0
depends_on: [T-0007]
spec: docs/mcp-studio.md
acceptance:
  - "experience privee BATTLEROT creee sur le Creator Hub (nom, groupe ou compte, id note dans ce ticket)"
  - "rojo serve lance avec default.project.json et Studio connecte : capture d'ecran de l'arbre ReplicatedStorage.Shared.Config"
  - "un Play Solo lance sans erreur dans la console (capture)"
---

## Contexte

Les agents n'ont pas Roblox Studio. Tout ce qui touche a l'experience reelle est fait par l'humain, avec les commandes
preparees par l'equipe (`docs/mcp-studio.md`, README).

## Travail attendu (humain)

```bash
git clone https://github.com/RAILOVER/ROBLOX-SUPER-ENGINEER-TEAM.git
cd ROBLOX-SUPER-ENGINEER-TEAM
rojo serve default.project.json
```
Puis dans Studio : plugin Rojo, Connect, Play.

## Hors perimetre

Game Passes, Developer Products, publication (M4+).

## Verification

Captures collees dans ce ticket.

## Non verifie

Sans objet.
