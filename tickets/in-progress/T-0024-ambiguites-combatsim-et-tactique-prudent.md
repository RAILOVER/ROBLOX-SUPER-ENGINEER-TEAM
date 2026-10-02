---
id: T-0024
title: Ambiguites de la spec combat tranchees par T-0010 et tactique Prudent dominee au miroir (R-M1-54)
role: 02-game-designer
phase: P1-greybox
status: backlog
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

## Non verifie

A remplir a la livraison.
