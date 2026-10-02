---
id: T-0005
title: Choisir le depot GitHub distant et le harnais de tests
role: 01-producteur
phase: P0-preparation
status: done
type: arbitrage
priority: P0
depends_on: []
acceptance:
  - "repo distant cree et accessible par Devin"
  - "runner de tests choisi et execute en CI : lune run tests/run.luau passe"
---

## Contexte

Phase P0. Le depot distant est `RAILOVER/ROBLOX-SUPER-ENGINEER-TEAM` (PR #1 fusionnee). Le runner devait etre choisi
avant d'ecrire des tests en volume pour BATTLEROT.

## Decision (2026-10-01)

Runner : **Lune + runner maison compatible TestEZ** (`tests/run.luau`, API `describe` / `it` / `expect`) pour tous les modules
purs (`src/shared/Config`, `src/shared/Combat`, progression, oeufs). Il tourne sur Linux et en CI sans Roblox Studio, charge
les modules avec un shim `script` / `require` qui imite l'arbre Rojo. Les tests qui exigent le moteur Roblox (DataStore,
Remotes, Instances) utilisent TestEZ dans Studio et restent `HUMAN_ACTION` tant qu'aucune machine Studio n'est en CI.

Pourquoi pas Jest-Lua : il depend de Wally + Roblox (ou de `jest-lua` sous Lune, encore instable en 2026) et aurait ajoute
une dependance runtime pour un besoin couvert par 150 lignes.

## Verification

```bash
lune run tests/run.luau     # 1 spec(s), 13 test(s) OK, 0 echec(s)
```

## Non verifie

Execution de TestEZ dans Studio (aucune machine Studio accessible aux agents).
