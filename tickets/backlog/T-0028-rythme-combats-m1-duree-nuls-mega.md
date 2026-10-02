---
id: T-0028
title: Rythme des combats M1 : duree animee 42 s, 8,9 % de nuls, Mega Combos dans 22 % des combats
role: 02-game-designer
phase: P1-greybox
status: backlog
type: spec
priority: P1
depends_on: [T-0015, T-0024]
spec: design/specs/M1-combat-tour-par-tour.md
acceptance:
  - "decision ecrite sur les valeurs Config.Combat concernees (drawAfterActions, suddenDeathAfterActions, suddenDeathDamageRamp, megaGainPerSynergyAction, megaGaugeMax, pvpActionAnimationMaxSeconds) ou sur les cibles M-C-03 et M-C-04"
  - "mesure attendue apres ajustement : lune run tests/sim/run_duels.luau 10000 20261002 --m1 donne nuls < 2 %, duree animee 20 a 35 s, combats avec Mega 60 a 80 %"
  - "ticket 04-dev-serveur ouvert si un changement de code (pas de valeur) est necessaire"
---

## Contexte

Mesures du harnais T-0015 (`docs/reports/balance-M1-2026-10-02.md`, code T-0010, Config inchangee), passe M1 :
10 unites de `Config.Skills.m1Slugs`, placements D-M1-29, equipes de 2 a 8 unites de meme taille des 2 cotes,
10 000 combats, seed 20261002, 0 erreur.

## Chiffres

1. Duree animee estimee (M-C-04, `actions x 0,8 s + 2,5 s par Mega`) : **42,1 s** en moyenne pour une cible de
   20 a 35 s (L0 : 38,7 s). 51,9 actions par combat en moyenne ; 58,6 % des combats durent 51 a 59 actions.
2. Nuls a 60 actions (M-C-03) : **8,9 %** (888 sur 10 000) pour une cible < 2 %. 12,9 % des combats atteignent
   60 actions. Les nuls se concentrent sur les grandes equipes : 8 contre 8 : 32,4 % (932 sur 2 876) ; 7 contre 7 :
   15,4 % ; 6 contre 6 : 8,7 % ; 5 contre 5 : 3,9 % ; 2 a 4 unites : moins de 1,2 %. Au miroir (meme equipe des
   2 cotes) : 18,7 % de nuls. T-0010 mesurait 0,88 % avec des tailles d'equipe independantes (1 a 8) : les combats
   desequilibres finissent vite et masquaient le probleme.
3. Mega Combos : **22,0 %** des combats M1 en ont au moins 1 (cible 60 a 80 %), 0,23 Mega par combat ; part des
   valeurs (degats, soins, boucliers) des Mega : 3,8 % (cible <= 20 %). Seul C05 `Declaration d'amour` est
   implemente au M1 : il exige un couple (banano + bananella, pomito + pomita ou myrtila + myrtilo hors M1) dans
   l'equipe, donc la cible 60 a 80 % n'est atteignable au M1 qu'en elargissant les declencheurs ou en revoyant la
   cible pour ce jalon.
4. Mort subite : `suddenDeathAfterActions = 40`, `suddenDeathDamageRamp` actuel : pas assez pour conclure avant
   60 actions quand 2 Colosses ou 2 Soigneurs se font face (Colosse : 44,1 % de victoires et 15,4 % de nuls dans
   ses combats, la classe la plus sujette aux nuls).

## Pistes (a trancher par le Game Designer, pas par le QA)

- Rampe de mort subite plus forte ou plus tot ; ou `drawAfterActions` plus haut avec un depart anticipe.
- Gain de jauge Mega par action de synergie, ou Mega declenchable par une synergie seule (pas seulement un couple).
- Revoir les cibles M-C-03 et M-C-04 si le rythme long est voulu pour le M1.

## Hors perimetre

Equilibre des tactiques (T-0024), valeurs des competences (T-0023), fenetres par unite et synergie (T-0029).

## Verification

```bash
lune run tests/sim/run_duels.luau 10000 20261002 --m1
lune run tests/run.luau
```

## Non verifie

A remplir a la livraison.
