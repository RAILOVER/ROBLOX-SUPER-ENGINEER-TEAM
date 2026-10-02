---
id: T-0029
title: Fenetres d'equilibrage L0 : 3 unites au-dessus de 60 %, synergie Cielo a 65 %, ecart 3 etoiles contre 1 etoile, Soigneurs sous 43 %
role: 02-game-designer
phase: P1-greybox
status: backlog
type: spec
priority: P2
depends_on: [T-0015, T-0023]
spec: design/brief/BATTLEROT.md
acceptance:
  - "decision ecrite pour chaque point : valeur ajustee dans Config (Roster, Rarities.statCoef, Progression.starMultipliers, Synergies) ou ecart accepte avec la raison"
  - "mesure attendue apres ajustement : lune run tests/sim/run_duels.luau 10000 20261002 donne 42 unites entre 40 et 60 % hors nuls et aucune synergie > 65 % sur plus de 100 combats"
---

## Contexte

Mesures du harnais T-0015 (`docs/reports/balance-M1-2026-10-02.md`, code T-0010, Config inchangee), passe L0 :
42 unites, cases aleatoires, equipes de 2 a 8 de meme taille, chaque paire jouee dans les 2 sens, 10 000 combats,
seed 20261002. Taux = victoires / (victoires + defaites). Attention : 31 effets de synergies et combos hors M1 ne
sont pas implementes dans CombatSim (`result.unimplemented`), les taux L0 des synergies refletent surtout les stats.

## Chiffres

1. Unites hors de la fenetre 40 a 60 % : **cappuccino-assassino 64,0 %** (Legendaire, Assassin, 2 338 combats),
   **tralalero-tralala 63,5 %** (Champion, Sprinteur, 2 416), **tung-tung-tung-sahur 62,0 %** (Champion, Guerrier,
   2 422). Les 39 autres sont entre 41,2 % (bananita-dolfinita) et 59,0 % (bombardiro-crocodilo). Les 3 unites hautes
   sont des raretes a `statCoef` 1,36 et 1,50 : l'ecart est peut-etre voulu (cout d'achat), a confirmer.
2. Synergies au-dessus de 65 % : Cielo:1 **65,4 %** (610 combats) ; Assassin:2 75,0 % (86 combats) ; Macchina:2
   87,5 % (16) ; Tentafruit:3 69,0 % (32) ; Couple:2 66,7 % (12). Seul Cielo:1 a un echantillon suffisant ; les
   paliers 2 et 3 sont rares en equipes aleatoires. En bas : Mare:2 22,8 % (60 combats), Soigneur:1 37,4 % (1 684),
   Soigneur:2 37,0 % (198).
3. Etoiles : 3 etoiles **62,4 %**, 2 etoiles 48,6 %, 1 etoile **38,9 %** (L0) ; M1 : 63,4 / 48,1 / 38,3. Avec
   `starMultipliers = { 1.0, 1.8, 3.24 }`, une unite 3 etoiles pese plus que la difference de rarete. Le brief vise
   environ 60 % pour un ecart d'un niveau : ici un ecart de 2 etoiles donne environ 62 contre 39.
4. Classes : Soigneur **42,9 %** (L0, 11 666 combats) et 45,7 % (M1), classe la plus basse dans les 2 passes ;
   Assassin la plus haute : 57,1 % (L0), 59,6 % (M1, trippi-troppi seul). Les 2 Soigneurs M1 (pomita 47,7 %,
   myrtila 43,7 %) sont les 2 unites les plus basses du M1 (toutes 2 dans la fenetre).

Les 10 unites M1 sont dans la fenetre (43,7 a 59,6 %) : les valeurs des competences M1 restent du ressort de
T-0023, ce ticket ne les couvre pas.

## Hors perimetre

Tactiques (T-0024), rythme et nuls (T-0028), competences M1 (T-0023).

## Verification

```bash
lune run tests/sim/run_duels.luau 10000 20261002
lune run tests/sim/run_duels.luau 10000 20261002 --m1
```

## Non verifie

A remplir a la livraison.
