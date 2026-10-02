---
id: T-0023
title: Relecture des valeurs de Config.Skills (10 competences M1 et competence par defaut)
role: 02-game-designer
phase: P1-greybox
status: review
type: spec
priority: P1
depends_on: [T-0010]
spec: design/specs/M1-duel-minimal.md
acceptance:
  - "src/shared/Config/Skills.luau relu : chaque power, params et target des 10 competences M1 valide ou corrige, avec la justification en commentaire"
  - "design/specs/M1-duel-minimal.md mis a jour avec les valeurs retenues (section competences)"
  - "la competence par defaut des 32 autres unites L0 (Attaque renforcee x1,5) confirmee ou remplacee"
  - "lune run tests/run.luau Combat passe apres modification"
---

## Contexte

La spec M1 dit que les puissances des 10 competences ne sont pas chiffrees. T-0010 a cree `Config.Skills` avec des
valeurs provisoires pour que CombatSim et les tests tournent. Ces valeurs ne sont pas normatives.

## Valeurs posees par T-0010

| Slug | skillId | effectId | power | params |
|---|---|---|---|---|
| tim-cheese | Grignotage | MultiHit | 0,75 x 2 | hits 2 |
| trippi-troppi | BondDeCrevette | StrikeBackline | 1,60 | ligne arriere la plus faible |
| ta-ta-ta-ta-sahur | TaTaTaTa | WakeAlliesSleepEnemy | 1,00 (MAG) | sleepChance 0,50, sleepTurns 1 |
| banano | MusclesDeLaVilla | TauntShield | 0 | tauntTurns 1, shieldPct 0,20 |
| bananella | LancerDePeau | DamageStunChance | 1,50 | stunChance 0,25, stunTurns 1 |
| pomito | CroquePomme | PowerStrike | 1,80 | |
| pomita | CompoteReconfortante | Heal | 2,50 (MAG) | allie le plus blesse |
| myrtila | Smoothie | HealEnergy | 1,20 (MAG) | energy 20 |
| glorbo-fruttodrillo | MachoireJuteuse | DamageTauntLifesteal | 1,30 | tauntTurns 1, lifestealPct 0,30 |
| boneca-ambalabu | RebondDePneu | MultiTargetTaunt | 0,80 x 3 cibles | targets 3, tauntTurns 1 |

Les couts viennent de `Config.Combat.classes[class].skillCost` (R-M1-17).

## Travail attendu

Relire chaque ligne avec les formules R-M1-10 et R-M1-11, ajuster dans `Skills.luau`, documenter.

## Hors perimetre

Equilibrage global par simulation (T-0015).

## Verification

```bash
python3 tools/check_repo.py
tools/lint.sh
lune run tests/run.luau Combat
```

## Resultat (2026-10-02)

- 10 competences relues avec la regle "cost 100 = 2 a 3 Attaques" : 5 changements (`ta-ta-ta-ta-sahur` 1,0 => 1,6 ;
  `banano` Bouclier 0,20 => 0,25 ; `bananella` 1,5 => 1,8 ; `pomito` 1,8 => 1,5 + vol de vie 0,50 selon la fiche
  L0 ; `myrtila` 1,2 => 1,6), 5 confirmees, competence par defaut 1,5 => 2,0. Justifications en commentaire dans
  `Skills.luau` et tableau dans `design/specs/M1-duel-minimal.md` section 4.
- `SkillEffects.PowerStrike` lit `params.lifestealPct` (optionnel) pour Croque-pomme.
- Test R-M1-24 : le Bouclier de banano est lu depuis `Config.Skills` (0,25) dans le meme commit.
- Mesure 2 000 combats (`tests/sim/UnitWinRates.spec.luau`) avant / apres : au plus 3 points de deplacement ; les
  stats de classe dominent (decision D-11 ouverte au GDD).

## Non verifie

- Les references DA `art/refs/<slug>/REFS.md` n'existent que pour `trippi-troppi` parmi les 10 unites M1 : les 9
  autres sont comparees a la fiche `design/roster/lot-L0-fiches.md` seulement.
- Equilibrage des stats de classe (D-11) et mesure a 10 000 combats : T-0015.
- Effet en duel complet (10 manches, 2 et 3 etoiles) : pas de harnais duel sous Lune (T-0011 en cours).
