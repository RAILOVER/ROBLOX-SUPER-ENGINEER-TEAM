---
id: T-0024
title: Ambiguites de la spec combat tranchees par T-0010 et tactique Prudent dominee au miroir (R-M1-54)
role: 02-game-designer
phase: P1-greybox
status: review
type: spec
priority: P1
depends_on: [T-0010]
spec: design/specs/M1-combat-tour-par-tour.md
acceptance:
  - "chaque interpretation de docs/architecture/combat.md section 6 est confirmee ou remplacee dans design/specs/M1-combat-tour-par-tour.md"
  - "R-M1-54 : decision ecrite (modifier Combat.tactics, les seuils de Garde, ou la cible 35 a 65 %) avec la mesure attendue pour T-0015"
  - "winner nul : 'draw' ou nil fixe dans la spec et dans Types/Combat.luau"
---

## Contexte

T-0010 a implemente CombatSim en choisissant l'interpretation la plus simple quand la spec ne tranchait pas. Les
choix sont listes dans `docs/architecture/combat.md` section 6 et doivent etre confirmes par le Game Designer.

## Points a trancher

1. `winner` au nul : le ticket T-0010 demande `"draw"`, la spec R-M1-58 ecrit `nil`. Implemente : `"draw"`.
2. Statuts sans `turns` dans `Config.Combat.statuses` : duree fournie par la competence, sinon permanents.
3. Un statut `turns = 1` pose pendant le tour de la cible couvre sa prochaine action (pas decremente le tour meme).
4. Charme : allie tire au sort ; unite seule => Skip.
5. Mega C05 : acteur = partenaire le plus rapide ; soins sans `HealPct` ; `megaAutoTriggerSeconds` ignore en M1.
6. Soigneur Agressif : soigne des que l'energie le permet, meme a PV pleins (soin de 0 journalise).
7. Competence sans cible => Attaque sans debit d'energie.
8. R-M1-54 mesure par T-0010 (5 unites M1 identiques, 100 seeds) : Agressif 86 victoires, Prudent 8, nuls 6. La cible
   35 a 65 % n'est pas atteinte : Prudent passe en Garde sous 40 % de PV a chaque tour et son Soigneur retient sa
   competence au-dessus de 85 %, donc il n'attaque presque plus. Le test `R-M1-54` affiche la mesure sans bloquer.

## Travail attendu

Trancher chaque point, mettre a jour la spec et ouvrir un ticket 04-dev-serveur si le code doit changer.

## Hors perimetre

Equilibrage des valeurs de competences (T-0023) et harnais QA (T-0015).

## Verification

```bash
python3 tools/check_repo.py
```

## Resultat (2026-10-02)

- Points 1 a 7 confirmes dans la spec, regle par regle ("revise T-0024") : R-M1-17, R-M1-18, R-M1-21, R-M1-33,
  R-M1-34, regles communes des statuts, R-M1-51, R-M1-58, R-M1-59, R-M1-60. `winner` nul = `"draw"`.
- Point 8 : cause mesuree avec `tests/sim/MirrorTactics.spec.luau` (2 000 seeds). Aucune valeur simple de
  `Combat.tactics` ne suffit (Prudent sans Garde : 24,0 %) : la cible "en face" de R-M1-52 disperse les degats.
  Correction D-10 : R-M1-52 vise `hp` min pour les classes sans logique propre (`Targeting.pickSingle`) et Garde
  Equilibre 0,20 / Prudent 0,25. Avant : Agressif 87,7 % / Prudent 6,9 % / nuls 5,5 %. Apres : 54,5 % / 43,2 % /
  2,3 %. Test R-M1-50 mis a jour sur les nouveaux seuils dans le meme commit.

## Non verifie

- La mesure R-M1-54 a 10 000 combats et sur d'autres compositions que T1 et T2 (5 unites M1) : T-0015.
- L'effet de D-10 sur le duel complet contre le bot (D-M1-30 met les Colosses du bot en Prudent) : pas de harnais
  duel sous Lune, T-0011 en cours.
- Le brief §11.7 (Garde 25 % / 40 %) n'est pas modifie : mise a jour a faire par le ticket d'alignement du brief
  deja prevu (spec combat section 5).
