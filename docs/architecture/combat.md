# CombatSim : architecture du combat deterministe (T-0010)

Source normative : `design/specs/M1-combat-tour-par-tour.md` (R-M1-01 a R-M1-60) et `design/specs/M1-duel-minimal.md`.
Le serveur rejoue la simulation complete ; le client ne fait qu'animer l'`ActionLog`. Tous les modules sont purs
(aucun `game`, aucun service Roblox, config injectee en parametre) et tournent sous Lune via `tests/run.luau`.

## 1. Modules (`src/shared/Combat/`, 400 lignes max, `--!strict`)

| Module | Role | Regles |
|---|---|---|
| `CombatSim.luau` | point d'entree : `simulate`, `newState`, `step`, `preview`, `orderFocus`, `result`, `mvp` | R-M1-09, R-M1-20, R-M1-55 a R-M1-60 |
| `Setup.luau` | construction des unites (stats), des equipes, synergies, timeline initiale | R-M1-01 a R-M1-04 |
| `Rng.luau` | mulberry32 seedable sur 32 bits : `NextInteger(min, max)`, `NextNumber(min?, max?)`, `Clone` | M-C-01 |
| `Timeline.luau` | initiative, ticks, egalites, prevision | R-M1-04 a R-M1-09 |
| `Formulas.luau` | stats, degats, soins, mort subite, VIT effective | R-M1-01, R-M1-02, R-M1-05, R-M1-10, R-M1-11, R-M1-57 |
| `Actions.luau` | Attaque, Garde, Duo, Mega Combo, `dealDamage`, `healUnit`, `gainEnergy`, entrees du journal | R-M1-13 a R-M1-20, R-M1-34 |
| `SkillEffects.luau` | handlers des `effectId` de `Config.Skills` | R-M1-17, R-M1-22 a R-M1-24 |
| `Targeting.luau` | portee, Provocation, Invisible, focus, logique de classe, soin | R-M1-25 a R-M1-29, R-M1-52, R-M1-55 |
| `Effects.luau` | synergies et combos : paliers, effets de stats, Regen, energie, mods, combos disponibles | R-M1-02, R-M1-13, R-M1-30 a R-M1-32 |
| `Status.luau` | les 13 statuts, K.O., dots, durees, immunite anti-enchainement | R-M1-03, R-M1-35 a R-M1-49 |
| `Tactics.luau` | Garde, Duo, Competence, Attaque selon la tactique | R-M1-50, R-M1-51, R-M1-53 |
| `ActionLog.luau` | `VERSION`, identifiants d'acteur, creation d'entree, serialisation canonique | R-M1-60 |

Types publics : `src/shared/Types/Combat.luau` (`UnitInstance`, `CombatConfig`, `ActionEntry`, `CombatResult`, `State`).
Config ajoutee : `src/shared/Config/Skills.luau` (enregistree dans `Config.Skills`).

## 2. API

```luau
local result = CombatSim.simulate(seed, teamA, teamB, Config, options?)
-- teamA, teamB : { { slug = "banano", row = 1, col = 2, stars = 1?, tactic = "Equilibre"? } } (1 a 8 unites)
-- options : { autoMega = false?, tentafruitEnabled = false? }
-- result : { winner = "A" | "B" | "draw", turns = ticks, actions = n, actionLog = {...}, version = 1,
--            mvp = "slug.case"?, unimplemented = { effectId } }

local state = CombatSim.newState(seed, teamA, teamB, Config)
CombatSim.preview(state, 10)      -- R-M1-09 : { { side, cell, slug } } sans effet de bord
CombatSim.orderFocus(state, "A", cell) -- R-M1-55, retourne false si l'ordre est ignore
while CombatSim.step(state) do end  -- 1 action (Mega Combo eventuel inclus) par appel
```

Le ticket demandait `winner: "A" | "B" | "draw"` ; la spec ecrit `winner = nil` pour le nul. La valeur `"draw"` est
retenue (serialisable, comparable), c'est la seule divergence volontaire avec la spec.

## 3. Format de l'ActionLog (`version = 1`)

Une entree par action (R-M1-56) : action d'unite (Attaque, Competence, Garde, Duo, Skip) ou Mega Combo.

```luau
{
    t = 12,                          -- compteur actions (1..60)
    actor = "banano.A1",             -- slug.case ; case = camp + index 0..7 (row - 1) * 4 + (col - 1)
    action = "Attack" | "Skill" | "Guard" | "Duo" | "Mega" | "Skip",
    skillId = "Grignotage"?,         -- action Skill
    combo = "C05"?,                  -- action Mega
    partner = "bananella.A5"?,       -- Duo et Mega
    targets = { "B2", "B2" },        -- 1 entree par frappe ou soin, dans l'ordre d'application
    values = { 179, 102 },           -- degats > 0, soins < 0 (valeur negative), 0 pour un buff sur soi
    crits = { false, true },
    statuses = { applied = { "Provocation@A1" }, removed = { "Endormi@B2" } },
    ticks = { "Brulure:-77", "RegenPerTurn:+46", "Epines:-30@B2" }, -- effets hors formule principale
    gauges = { energy = 40, mega = 8 }, -- energie de l'acteur et jauge Mega de son equipe apres l'action
    hp = { A1 = 1540, B2 = 0 },      -- PV restants des cases touchees (et de l'acteur)
    kos = { "B2" },                  -- K.O. survenus pendant l'action
}
```

`ActionLog.serialize(log)` produit une chaine canonique (cles triees) ; 2 journaux identiques donnent la meme chaine.
Les champs `skillId`, `combo`, `partner` sont absents (nil) quand ils ne s'appliquent pas. Un `Skip` d'unite
controlee a `targets = {}`. Les `values` negatives sont des soins (le client affiche en vert).

## 4. Ordre d'evaluation d'une action (`CombatSim.step`)

1. `Timeline.nextActor` : ticks jusqu'a ce qu'une unite atteigne 1000 (R-M1-05 a R-M1-07).
2. Mega Combo de l'equipe de l'acteur si `mega >= 100`, paire vivante, usage restant (R-M1-20, R-M1-32) : entree `Mega`,
   +1 action, jauge a 0. Si le combat se termine la, l'acteur ne joue pas.
3. Ouverture de l'entree, `guarding = false` pour l'acteur, +1 action.
4. Debut de tour : `RegenPerTurn` (synergie Mare) puis dots `Brulure` / `Saignement` x mort subite (R-M1-41, R-M1-57).
   Un K.O. ici donne un `Skip`.
5. Controle : `Etourdi`, `Endormi`, `HorsCombat` => `Skip` (R-M1-08). `Charme` => Attaque sur un allie tire au sort,
   `Skip` si seule (R-M1-21).
6. Tactique (R-M1-50 a R-M1-53) : Garde > Duo > Competence > Attaque. Une competence sans cible retombe sur une Attaque
   et ne debite pas l'energie ; une Attaque sans cible donne `Skip`.
7. Jauge Mega : +4 si l'acteur est membre d'une synergie active et n'a pas `Skip` (R-M1-31). `Invisible` tombe sur une
   action offensive (R-M1-46).
8. `Timeline.afterAction` : 0, ou 300 apres Garde (R-M1-07).
9. Fin de tour : immunite anti-controle puis durees des statuts (un statut pose pendant ce tour n'est pas decremente),
   `Bouclier` a 0 tombe (R-M1-44, R-M1-48).
10. Fermeture de l'entree (`gauges`, `hp`), tour d'equipe (R-M1-38, R-M1-55 : `HorsCombat` et focus se decrementent
    quand chaque allie actif a agi), fin de combat (R-M1-58, R-M1-59).

`dealDamage` (R-M1-13, R-M1-14) : formule R-M1-10 avec mods `{ competence, synergie offensive, Expose, Garde, mort
subite }` > Bouclier > PV > compteur de degats recus par ennemi (Colosse) > Epines (Melee et MeleeBackline, journalise
dans `ticks`) > `Endormi` tombe > `energyPerHitTaken` (1 fois par action et par cible, R-M1-23) et `LienDAmour` >
vol de vie > K.O.

## 5. effectId

Implementes (synergies, paliers accessibles en M1 ou faciles) : `RegenPerTurn`, `ColossePctHP`, `LienDAmour`,
`HealPct`, `EnergyGainPct`, `FlatMAG`, `FlatVIT`, `FlatDEFRES`, `PctATQMAG`, `Lifesteal`, `StartShield`, `CritBonus`,
`AoePct` (mod sur les frappes multi-cibles). Combo : `CoupleStrike` (C05).

Implementes (competences `Config.Skills`) : `PowerStrike`, `MultiHit`, `StrikeBackline`, `WakeAlliesSleepEnemy`,
`TauntShield`, `DamageStunChance`, `Heal`, `HealEnergy`, `DamageTauntLifesteal`, `MultiTargetTaunt`.

Non implementes : tout autre `effectId` de `Config.Synergies` (paliers 2 et plus : `ColossePctHPTeam`, `CouplePctHP`,
`HealPctOverheal`, `FlatVITReplay`, `CritBonusFirstHit`, `AoePctSplash`, `RegenPerTurnBurnImmune`, `LifestealATQ`,
`DoubleShot`, `PrimeTime`, `CharmeChance`, ...) et de `Config.Combos` (C01 a C04, C06 a C10). Quand une equipe les
active, l'identifiant est ajoute a `result.unimplemented` (combo : `effectId(C0x)`) et le combat continue sans eux.
Une competence avec un `effectId` inconnu joue comme `PowerStrike` et est journalisee de la meme facon.

## 6. Decisions et interpretations retenues

- D-04 (mort subite) : multiplicative, `1,25 ^ (actions - 40)` sur les degats de formule et les dots, position 5 des
  mods. Action 44 => x2,44 ; action 60 => x86,74.
- D-05 (Duo) : 2 Attaques separees a x1,20 sur la meme cible (ciblage du lanceur), chaque frappe a sa propre variance
  et son propre critique ; 1 action ; 50 energie debites a chacun ; la timeline du partenaire ne bouge pas.
- D-07 (Tentafruit 2) : actif par defaut (`EnergyGainPct` 15 %, arrondi inferieur), desactivable par
  `options.tentafruitEnabled = false` pour les mesures du QA.
- Nul : `winner = "draw"` (le ticket) au lieu de `nil` (la spec), voir §2.
- Statuts sans `turns` dans `Config.Combat.statuses` (Ralenti, Enracine, Brulure, Saignement, Expose, Bouclier,
  Provocation, Invisible, Epines) : la duree vient de la competence (`ApplyOptions.turns`) ; sans duree, le statut
  reste jusqu'au K.O. (ou a 0 pour Bouclier). En M1 seules les Provocations (1 tour) et les Boucliers sont poses.
- Un statut `turns = 1` pose pendant le tour d'une unite n'est pas decremente a la fin de ce tour : il couvre la
  prochaine action de la cible (lecture de R-M1-35 : "la prochaine action de la cible est Skip").
- Charme : la cible alliee est tiree au sort avec le Rng du combat ; une unite seule fait `Skip`.
- Mega Combo C05 : l'acteur de l'entree est le partenaire le plus rapide (VIT puis case), l'autre est `partner` ; 4
  `targets` : 2 soins (valeurs negatives) puis 2 frappes a x2,00 sur la cible unique du plus rapide ; les soins
  ignorent `HealPct` (lecture de R-M1-34) ; les Boucliers appliquent la regle du maximum (R-M1-44).
- Jauge Mega : `megaUsesPerComboPerCombat` = 1 est verifie par combo ; `megaAutoTriggerSeconds` est ignore (le
  serveur declenche a la premiere action alliee, le mode manuel M2 passera par `options.autoMega = false`).
- Garde : `guarding` est leve au debut de la prochaine action de l'unite (toute l'attente a 300 est protegee).
- Competence sans cible valable (ex. soin sur une equipe pleine ne se produit pas : la cible est le lanceur) : la
  tactique retombe sur Attaque sans debiter l'energie.
- Agressif et Soigneur : `healerHoldsSkillAboveAllyHp` = 0 => il soigne des que l'energie le permet, meme a PV pleins
  (soin a 0 journalise), conformement a "soigne des que possible".
- MVP : `degats infliges + soins appliques` (les soins au-dela de HPmax ne comptent pas) ; a egalite, la premiere unite
  dans l'ordre A puis B, cases croissantes.
- `turns` du resultat = nombre de ticks de timeline (le compteur d'actions est `actions`).
- Les equipes sont triees par case avant tout tirage ; 2 unites sur la meme case ou une case hors grille sont des
  erreurs (`assert`), pas des combats.

## 7. Chiffres mesures (Lune 0.10.5, Linux, 2026-10-02)

Commande : `lune run tests/run.luau Robustness` (10 000 combats par defaut, `COMBAT_SIM_COUNT=1000` pour 1 000).

| Mesure | Valeur |
|---|---|
| 10 000 combats aleatoires (1 a 8 unites par camp, 42 slugs L0, 1 a 3 etoiles, seed Rng 20261002) | 10,88 s, 0 erreur |
| Part de nuls (M-C-03) | 88 / 10 000 = 0,88 % |
| Nombre moyen d'actions | 37,5 ; maximum 60 (jamais au-dela) |
| 1 000 combats | 1,14 s, 13 nuls (1,30 %) |
| Determinisme (M-C-01) | 100 seeds, 100 journaux identiques |
| Couverture (M-C-05) | 60 `it` nommes R-M1-01 a R-M1-60, tous verts |
| R-M1-54 (miroir Agressif contre Prudent, 5 unites M1, 100 seeds) | Agressif 86, Prudent 8, nuls 6 : hors cible 35 a 65, ticket T-0022 |

La duree de 10 000 combats est sous la limite de 60 s : le spec de robustesse garde 10 000 par defaut.

## 8. Hors perimetre T-0010

Remotes, DataStore, UI, equilibrage des valeurs (T-0015), mode manuel PvP (M2), boss (`isBoss` present mais aucune
unite boss en M1), paliers 2 et plus des synergies.
