# Spec M1 : combat au tour par tour

Ticket : T-0009. Source : brief §7.3, §9.1, §11. Config : `Config.Combat` (toutes les variables ci-dessous sont des
champs de cette table, sauf mention), `Config.Rarities.statCoef`, `Config.Synergies`, `Config.Combos`.
Tickets derives : T-0010 (CombatSim), T-0015 (QA). Spec parente : [M1-duel-minimal](M1-duel-minimal.md).
Chaque regle `R-M1-xx` donne lieu a 1 test Lune dans `tests/unit/Combat*.spec.luau`. Le pseudo-code est normatif :
memes noms, memes arrondis.

## 1. Enonce testable

`CombatSim.simulate(seed, teamA, teamB, config)` rejoue un combat entre 2 equipes de 1 a 8 unites sur une timeline,
avec 5 actions, 13 statuts, 3 tactiques, et se termine toujours en moins de 60 actions par victoire, defaite ou nul.

## 2. Mesure

| ID | Mesure | Instrument | Seuil |
|---|---|---|---|
| M-C-01 | Determinisme | meme seed, memes equipes, 100 seeds : `ActionLog` identique octet par octet | 100 / 100 |
| M-C-02 | Fin de combat | 10 000 combats aleatoires sous Lune | 0 erreur, 0 combat > `drawAfterActions` actions |
| M-C-03 | Part de nuls | 10 000 combats | < 2 % |
| M-C-04 | Duree animee | `actions x pvpActionAnimationMaxSeconds` + 2,5 s par Mega Combo, moyenne | entre 20 et 35 s |
| M-C-05 | Couverture des regles | 1 test nomme par regle R-M1-xx | 60 / 60 presents |
| M-C-06 | Taille des modules | `wc -l` de chaque fichier `src/shared/Combat/*.luau` | <= 400 lignes |

## 3. Regles

### 3.1 Unites et stats (brief §7.3)

- R-M1-01 : une unite de combat est construite depuis `Roster[slug]` : `classes[class]` donne HP, ATQ, MAG, DEF, RES,
  VIT, range, skillCost, critChance ; chaque stat est multipliee par `Rarities[rarity].statCoef` puis par
  `statOverrides[stat]` (defaut 1), puis par le coefficient d'etoiles (1 etoile 1,00 ; 2 etoiles 1,80 ; 3 etoiles
  3,24, sur HP, ATQ et MAG seulement), arrondie a l'entier inferieur. Test : `glorbo-fruttodrillo` 1 etoile : HP =
  floor(1400 x 1,10) = 1540, ATQ = 77, VIT = 88.
- R-M1-02 : les paliers de synergie actifs (spec duel D-M1-13, D-M1-14) appliquent leurs `params` aux stats avant le
  premier tick : `ColossePctHP` => HP et HPmax x (1 + pct) pour les Colosses ; `FlatMAG` => MAG + MAG ; les pourcentages
  s'additionnent entre eux avant d'etre multiplies (2 bonus de +20 % PV donnent x1,40, pas x1,44).
- R-M1-03 : une unite a 4 compteurs : `hp` (0 a HPmax), `energy` (0 a `energyMax` = 100), `timeline` (0 a
  `timelineThreshold` = 1000), `statuses` (liste ordonnee). `hp <= 0` => K.O. : l'unite ne joue plus, n'est plus
  ciblable, ses statuts sont effaces.

### 3.2 Timeline et initiative (brief §11.2)

- R-M1-04 : au debut du combat, `timeline = rng:NextInteger(0, timelineStartRandomMax) + timelineStartVitMult * VIT`
  (0 a 200 + 2 x VIT), tire dans l'ordre fixe : equipe A colonnes 1 a 4 ligne avant puis arriere, puis equipe B.
- R-M1-05 : un tick ajoute `VIT_effective` a la `timeline` de chaque unite vivante non `HorsCombat`, avec
  `VIT_effective = floor(VIT * (1 + Ralenti.VIT) * (1 + Enracine.VIT))` (les malus VIT se multiplient, un seul par
  statut, minimum 1). Les ticks se succedent jusqu'a ce qu'au moins 1 unite ait `timeline >= timelineThreshold`.
- R-M1-06 : si plusieurs unites atteignent le seuil au meme tick, elles agissent dans cet ordre : VIT la plus haute ;
  a egalite de VIT, les camps alternent en commencant par le camp qui n'a pas agi en dernier (equipe A au tout
  debut) ; a egalite dans le meme camp, la case la plus basse (ligne avant colonne 1 = 0 ... ligne arriere colonne 4
  = 7).
- R-M1-07 : apres son action, `timeline = 0`, sauf Garde : `timeline = floor(guardTimelineAdvance *
  timelineThreshold)` = 300.
- R-M1-08 : une unite sous `Etourdi`, `Endormi` ou `HorsCombat` qui atteint le seuil "perd son tour" : son action
  est `Skip`, consomme 1 action du compteur (R-M1-56), `timeline = 0`, et le statut decremente `turns`.
- R-M1-09 : le serveur fournit au client la liste des 10 prochaines actions prevues (simulation des ticks sans
  effet de bord), recalculee apres chaque action ; le test verifie que la prevision 1 est toujours egale a l'acteur
  reel de l'action suivante en l'absence de changement de VIT.

### 3.3 Formules (brief §11.5)

```
-- R-M1-10 : degats d'une attaque (physique : ATQ contre DEF ; magique : MAG contre RES)
function damage(power, attackStat, defenseStat, rng, critChance, mods)
    local base = power * attackStat * 100 / (100 + defenseStat)
    local variance = rng:NextNumber(damageVariance[1], damageVariance[2])   -- 0.95 a 1.05
    local crit = (rng:NextNumber() < critChance) and critMultiplier or 1     -- x1.5
    local value = base * variance * crit
    for _, m in mods do value *= m end                                       -- ordre fixe R-M1-13
    return math.max(minimumDamage, math.floor(value + 0.5))                  -- entier, minimum 1
end

-- R-M1-11 : soins
function heal(power, MAG, healBonusPct)
    return math.floor(power * MAG * (1 + healBonusPct) + 0.5)               -- HealPct (Soigneur 2) = 0.20
end
```

- R-M1-12 : `power` vaut `basicAttackPower` = 1,00 pour une Attaque physique, `basicAttackMagicPower` = 0,80 pour
  une Attaque d'une classe de `magicBasicAttackClasses` (Soigneur, Mage), et la puissance de la competence sinon
  (fiches §7.2, a chiffrer par T-0010 dans `Config.Skills`).
- R-M1-13 : `mods` est construit dans cet ordre fixe et documente dans `Effects.luau` : (1) bonus de competence
  (ex. +25 %), (2) bonus de synergie offensifs (`Frutta` ATQ/MAG, `Artilleur` zone), (3) `Expose` sur la cible
  (x1,25), (4) `Garde` de la cible (x`guardDamageReduction` = 0,50), (5) mort subite (R-M1-57). Les auras et les
  etoiles sont deja dans les stats (R-M1-01, R-M1-02), elles ne sont pas des mods.
- R-M1-14 : application des degats : `Bouclier` absorbe d'abord (`shield -= value`, le reste va aux `hp`), puis
  `hp -= reste`, puis `Epines` renvoie `floor(value * thornsPct)` a un attaquant de melee, puis la cible gagne
  `energyPerHitTaken` = 10 (1 fois par action ennemie, meme si elle est touchee 3 fois par Rebond de pneu), puis
  `LienDAmour` donne `energyOnPartnerHit` = 10 au partenaire vivant, puis le soin de vol de vie eventuel. Test :
  1000 degats sur une cible a 300 de Bouclier et 1200 PV => bouclier 0, PV 500.

### 3.4 Les 5 actions (brief §11.3)

- R-M1-15 : chaque unite commence avec `energy = energyStart` = 20. `energy` est borne par `energyMax` = 100. Tout
  gain d'energie est multiplie par (1 + `EnergyGainPct.pct`) = 1,15 si Tentafruit 2 est actif (arrondi inferieur).
- R-M1-16 : Attaque : 1 cible selon R-M1-25 a R-M1-28, `power` R-M1-12, puis `energy += energyPerBasicAttack` = 20.
  Test : 4 Attaques depuis 20 donnent exactement 100.
- R-M1-17 : Competence : disponible si `energy >= classes[class].skillCost` (Colosse 100, Guerrier 90, Assassin 80,
  Artilleur 100, Soigneur 70, Mage 100, Sprinteur 80) ; `energy -= skillCost` ; effet de la fiche §7.2. Une
  competence ne donne pas `energyPerBasicAttack`.
- R-M1-18 : Garde : pose le marqueur `guarding = true` jusqu'a la prochaine action de l'unite (toute action, Skip
  compris) ; les degats subis sont multiplies par `guardDamageReduction` = 0,50 ; `energy += guardEnergyGain` = 30 ;
  `timeline` R-M1-07.
- R-M1-19 : Duo : disponible si Couple 1 est actif, si le partenaire (`Roster[slug].duoPartners`) est vivant, sans
  statut de controle, et si les 2 ont `energy >= duoEnergyCost` = 50. Les 2 perdent 50 ; chacun inflige une Attaque
  (R-M1-10) de `power = basicAttackPower * duoPowerMultiplier` = 1,20 sur la meme cible (ciblage du lanceur) ; le
  partenaire ne perd pas sa `timeline`. L'action compte 1 au compteur (R-M1-56). Le Duo est choisi par la tactique
  avant la Competence quand il est disponible (R-M1-50).
- R-M1-20 : Mega Combo : action d'equipe inseree avant la prochaine action alliee (R-M1-30 a R-M1-34).
- R-M1-21 : une unite sous `Charme` joue une Attaque sur un allie tire au hasard parmi ses allies vivants (elle-meme
  exclue) ; si elle est seule, l'action est `Skip`.
- R-M1-22 : Ta-ta-ta-ta (M1, `ta-ta-ta-ta-sahur`) : retire `Endormi` a tous les allies, puis `rng:NextNumber() < 0,50`
  => `Endormi` 1 tour sur 1 ennemi au hasard (R-M1-48 s'applique).
- R-M1-23 : Grignotage (M1, `tim-cheese`) : 2 Attaques consecutives sur la meme cible, 1 seule action au compteur,
  1 seul gain `energyPerHitTaken` pour la cible.
- R-M1-24 : Provocation posee par Muscles de la villa, Machoire juteuse et Rebond de pneu dure `turns` = 1 tour de la
  source ; Machoire juteuse soigne la source de floor(0,30 x degats infliges) ; Rebond de pneu touche 3 ennemis
  distincts (ou moins s'il en reste moins) a `power` 0,80 chacun.

### 3.5 Ciblage (brief §11.4)

- R-M1-25 : `range = "Melee"` : cibles possibles = ennemis vivants de la ligne avant ; si elle est vide, ligne arriere.
- R-M1-26 : `range = "Ranged"` ou `"MeleeBackline"` (Assassin) : tous les ennemis vivants.
- R-M1-27 : une source de `Provocation` vivante et ciblable force toute Attaque, Competence ou Duo a cible unique de
  l'ennemi a la viser (priorite sur R-M1-25 et R-M1-26, et sur l'ordre de focus R-M1-55). `Invisible` retire l'unite
  des cibles possibles ; si toutes les cibles sont `Invisible`, l'action vise la plus proche quand meme (pas de Skip).
- R-M1-28 : parmi les cibles possibles, la tactique choisit (R-M1-50 a R-M1-54) ; a egalite, la cible "en face"
  (meme colonne), puis la case la plus basse.
- R-M1-29 : les soins visent l'allie vivant avec le plus petit `hp / HPmax` ; a egalite, le lanceur.

### 3.6 Mega Combo (brief §9.1)

- R-M1-30 : la jauge `mega` est par equipe, de 0 a `megaGaugeMax` = 100, remise a 0 au debut de chaque combat.
- R-M1-31 : `mega += megaGainPerSynergyAction` = 4 a chaque action (Attaque, Competence, Garde, Duo ; pas Skip) d'un
  allie membre d'au moins 1 synergie active ; `mega += megaGainPerKO` = 8 quand un ennemi est mis K.O. par l'equipe.
  Test : 25 actions de synergie => 100.
- R-M1-32 : un combo est disponible si `mega >= megaGaugeMax`, si tous les slugs de `Combos[id].requires` sont vivants
  et sur le plateau, et si le combo n'a pas depasse `megaUsesPerComboPerCombat` = 1 dans ce combat. Apres
  declenchement, `mega = 0`.
- R-M1-33 : en PvP, si un combo est disponible et que le joueur n'agit pas dans `megaAutoTriggerSeconds` = 8 s
  (temps client), le combo le plus puissant se lance seul ; le bot lance a 0 s. En simulation Lune, la decision est
  un parametre de `simulate` (`autoMega = true` par defaut).
- R-M1-34 : C05 "Declaration d'amour" (M1) : pour les 2 partenaires, `Bouclier` = floor(0,30 x HPmax) et soin de
  floor(0,25 x HPmax) (sans `HealPct`), puis chacun inflige une Attaque de `power` 2,00 sur la meme cible (ciblage du
  partenaire le plus rapide). Compte 1 action au compteur. Les autres combos sont ignores en M1.

### 3.7 Les 13 statuts (brief §11.6, `Combat.statuses`)

Regles communes : un statut porte `kind`, une duree `turns` (tours de la cible) quand la config en donne une, sinon
la duree donnee par la competence ; `turns` decremente a la fin de chaque tour de la cible (Skip compris) et le
statut tombe a 0. Reposer un statut deja present remet `turns` au maximum (sauf `Saignement`, R-M1-42).

- R-M1-35 : `Etourdi` (`control`, turns 1) : la prochaine action de la cible est `Skip` (R-M1-08).
- R-M1-36 : `Endormi` (`control`, turns 1, `breaksOnDamage`) : comme `Etourdi`, mais tout degat > 0 retire le statut
  immediatement (l'unite joue normalement a son prochain tour).
- R-M1-37 : `Charme` (`control`, turns 1) : la prochaine action est une Attaque sur un allie (R-M1-21).
- R-M1-38 : `HorsCombat` (`control`, turns 2, `bossImmune`) : l'unite ne gagne pas de `timeline`, n'est pas ciblable,
  ne compte pas comme vivante pour les synergies et les combos, revient apres 2 tours d'equipe de sa propre equipe
  avec ses `hp` et `energy` inchanges. Un boss (drapeau `isBoss`, M2) est immunise ; en M1 aucun boss.
- R-M1-39 : `Ralenti` (`debuff`, VIT -0,30) : R-M1-05.
- R-M1-40 : `Enracine` (`debuff`, VIT -0,50) : R-M1-05 ; cumulable avec `Ralenti` (x0,70 x 0,50 = x0,35).
- R-M1-41 : `Brulure` (`dot`, hpMaxPerTurn 0,05) : au debut de chaque tour de la cible, `hp -= floor(0,05 x HPmax)`,
  ignore `Bouclier` et `Garde`, ne donne pas `energyPerHitTaken`, peut mettre K.O. Immunite si Mare 4 (hors M1).
- R-M1-42 : `Saignement` (`dot`, hpMaxPerTurn 0,04, maxStacks 3) : comme `Brulure` avec `stacks x 0,04 x HPmax` ;
  chaque pose ajoute 1 stack jusqu'a 3 et remet `turns` ; les stacks tombent ensemble.
- R-M1-43 : `Expose` (`debuff`, damageTaken 0,25) : mod x1,25 en position 3 de R-M1-13.
- R-M1-44 : `Bouclier` (`buff`) : porte une valeur `shield` en PV ; absorbe en premier (R-M1-14) ; reposer un
  Bouclier garde la plus grande valeur (pas d'addition) ; tombe a 0 ou a la fin de sa duree.
- R-M1-45 : `Provocation` (`buff`) : R-M1-27 ; 1 seule source de Provocation est retenue par camp : la plus recente.
- R-M1-46 : `Invisible` (`buff`) : non ciblable par les actions a cible unique (R-M1-27) ; les effets de zone la
  touchent ; attaquer retire `Invisible`.
- R-M1-47 : `Epines` (`buff`, `thornsPct` donne par la competence) : renvoie `floor(degats x thornsPct)` a un
  attaquant dont `range` est `Melee` ou `MeleeBackline`, apres les degats (R-M1-14) ; les Epines ne renvoient pas les
  degats renvoyes.
- R-M1-48 : anti-enchainement : quand un statut `control` tombe, la cible gagne `controlImmunityTurnsAfterControl` = 1
  tour d'immunite aux 4 statuts `control` (le statut est refuse, l'action continue). Un boss resiste a
  `bossControlResistance` = 0,50 : `rng:NextNumber() < 0,50` => statut refuse.
- R-M1-49 : le test de couverture verifie que `Combat.statuses` contient exactement ces 13 cles et aucune autre.

### 3.8 Tactiques automatiques (brief §11.7, `Combat.tactics`)

Priorite commune a chaque tour d'une unite, premiere regle vraie : Mega Combo en attente (R-M1-20) > Garde > Duo >
Competence > Attaque. `t = tactics[tactique]`.

- R-M1-50 : Garde si `hp / HPmax < t.guardBelowHp` et (`tactique == "Prudent"` ou un Soigneur allie est vivant).
  `Agressif` : `guardBelowHp` = 0 => jamais de Garde. `Equilibre` : 0,25. `Prudent` : 0,40.
- R-M1-51 : Competence si `energy >= skillCost`, sauf Soigneur : il garde sa competence tant qu'aucun allie n'a
  `hp / HPmax < t.healerHoldsSkillAboveAllyHp` (Agressif 0 => soigne des que possible ; Equilibre 0,70 ;
  Prudent 0,85). Prudent : si l'unite a une competence defensive (Bouclier, Provocation, soin) et une offensive,
  la defensive passe d'abord (M1 : aucune unite n'a les 2, test sur un faux roster).
- R-M1-52 : cible d'une Attaque ou d'une Competence offensive : `Agressif` vise l'ennemi ciblable avec le plus petit
  `hp` absolu ; `Equilibre` et `Prudent` appliquent la logique de classe : Assassin => ligne arriere la plus faible
  (`hp` min) ; Artilleur => la ligne qui contient le plus d'unites vivantes (puis `hp` min) ; Colosse => l'ennemi qui
  a inflige le plus de degats a l'equipe depuis le debut du combat ; autres classes => l'ennemi "en face" sinon
  `hp` min.
- R-M1-53 : la tactique par defaut est `Equilibre` ; elle est fixee par unite pendant `Preparation` et ne change pas
  pendant le combat (M1 : pas de changement en direct).
- R-M1-54 : 100 combats "Agressif contre Prudent" avec 2 equipes identiques (miroir) donnent entre 35 % et 65 % de
  victoires pour chaque camp (aucune tactique dominante au miroir, mesure T-0015).

### 3.9 Interventions, limites et journal (brief §11.9 a §11.11)

- R-M1-55 : ordre de focus : `focusOrdersPerCombat` = 1 par joueur et par combat ; pendant `focusTurns` = 2 tours
  d'equipe (2 actions de chaque allie vivant, Skip compris), toute action a cible unique des allies vise la cible
  designee si R-M1-25 a R-M1-27 le permettent ; sinon le ciblage normal. Un 2e ordre est ignore et compte.
- R-M1-56 : le compteur `actions` augmente de 1 a chaque action d'unite (Attaque, Competence, Garde, Duo, Skip) et a
  chaque Mega Combo. Les ticks de statuts, les regenerations de synergie et les gains d'energie ne comptent pas.
- R-M1-57 : mort subite : pour `actions > suddenDeathAfterActions` = 40, tous les degats (R-M1-10 et dot) sont
  multiplies par `(1 + suddenDeathDamageRamp) ^ (actions - suddenDeathAfterActions)` = 1,25 ^ (actions - 40),
  en position 5 de R-M1-13. Test : action 44 => x2,44 (arrondi 2 decimales), action 60 => x86,74.
- R-M1-58 : nul : si `actions >= drawAfterActions` = 60 et que les 2 equipes ont encore une unite vivante, le combat
  s'arrete avec `winner = nil` (spec duel D-M1-18).
- R-M1-59 : victoire : des qu'une equipe n'a plus d'unite vivante ni `HorsCombat`, `winner` = l'autre equipe, le combat
  s'arrete a la fin de l'action en cours. Si les 2 equipes tombent dans la meme action, `winner = nil`.
- R-M1-60 : `ActionLog` : liste ordonnee de `{ t = actions, actor = slug.case, action = "Attack" | "Skill" | "Guard"
  | "Duo" | "Mega" | "Skip", targets = { case }, values = { degats ou soins par cible }, statuses = { poses et
  retires }, gauges = { energy acteur, mega equipe } }`, plus `turns` (nombre de ticks) et `winner`. Le format est
  versionne (`version = 1`) et documente dans `docs/architecture/combat.md` (T-0010). `MVP` de la manche = l'unite
  avec `degats + soins` max.

## 4. Cas limites

| Cas | Comportement attendu | Regle |
|---|---|---|
| Equipe de 1 unite contre 8 | combat valide, se termine en moins de 60 actions (mort subite) | R-M1-57, R-M1-59 |
| 2 Provocations dans le meme camp | seule la plus recente attire | R-M1-45 |
| Cible unique toutes Invisible | l'action vise quand meme la plus proche | R-M1-27 |
| Duo quand le partenaire est Etourdi | Duo indisponible, la tactique passe a Competence ou Attaque | R-M1-19 |
| Soigneur seul survivant, Agressif | il soigne lui-meme ou attaque (80 % MAG), jamais Skip | R-M1-29, R-M1-51 |
| Brulure sur une unite a 1 PV avec Bouclier | K.O. (le dot ignore le Bouclier) | R-M1-41 |
| Energie a 95 + Attaque | 100 (borne), pas 115 | R-M1-15 |
| Les 2 dernieres unites se tuent sur Epines dans la meme action | nul | R-M1-47, R-M1-59 |
| Mega disponible au tour d'une unite Etourdie | le Mega s'insere avant le Skip | R-M1-20 |
| seed identique, ordre des unites dans `teamA` permute | `ActionLog` identique (tri par case avant tirage) | R-M1-04 |

## 5. Tickets derives

- T-0010 : CombatSim, Timeline, Actions, Effects, Status, Rng ; `Config.Skills` (puissances des 10 competences M1) ;
  `docs/architecture/combat.md`.
- T-0015 : harnais 10 000 combats, mesures M-C-02 a M-C-04, R-M1-54.
- A ouvrir (Game Designer) : brief §11.3 et §11.10 a aligner sur `Combat.luau` (decisions D-02, D-04, D-05 du GDD).
