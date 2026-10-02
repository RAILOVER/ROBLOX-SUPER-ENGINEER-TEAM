# GDD BATTLEROT v1 (index vivant)

Version : 1.0 (T-0009, 2026-10-02). Statut : en revue, validation humaine M0 attendue.
Source de verite du jeu : [le brief](../brief/BATTLEROT.md). Ce GDD ne recopie pas le brief : il renvoie a la
section qui fait foi, note ce qui est deja en config (`src/shared/Config/`), ce qui est specifie de facon testable
(`design/specs/`) et ce qui reste ouvert. Toute valeur chiffree vit dans la config, jamais ici.

Pitch en une phrase : brief §1.1. Piliers : brief §1.2. Public (mobile, une main) : brief §1.3.

## 1. Carte du jeu, section par section

| Sujet | Brief | Config | Spec testable | Etat |
|---|---|---|---|---|
| Vision, piliers, KPI de lancement | §1 | aucune | aucune (KPI mesures au M6, §20) | fige |
| Regles absolues R1 a R8 | §2 | `Limits.luau` (R5 budgets) | `tools/check_repo.py` | fige |
| Boucle d'un duel (7 a 10 min) et de session (15 min) | §6.1, §6.2 | `Duel.luau` | [M1-duel-minimal](../specs/M1-duel-minimal.md) | specifie M1 |
| Boucle meta et quotidienne | §6.3, §6.4 | `Eggs.luau`, `Economy.luau` | aucune (M4) | hors M1 |
| Raretes, niveaux, cartes | §7.1 | `Rarities.luau`, `Progression.luau` | tests `Config.spec` | config v1 |
| Roster L0 (42 unites) | §7.2 | `Roster/L0*.luau` (genere par `tools/gen_roster.py`) | `design/roster/lot-L0-fiches.md` | fige, validation humaine T-0007 |
| Stats par classe, coefficient de rarete | §7.3 | `Combat.classes`, `Rarities.statCoef` | [M1-combat](../specs/M1-combat-tour-par-tour.md) R-M1-02 | config v1 |
| Lots L1+ et tendances | §7.4, §7.5 | aucune | `docs/reports/trends-*` | hors M1 |
| Synergies (9 familles, 7 classes, 2 sous-roles) | §8 | `Synergies.luau` | M1-duel-minimal §4 (5 activables en M1) | config v1 |
| Mega Combos (13, 5 MVP) | §9 | `Combos.luau`, `Combat.mega*` | M1-combat R-M1-30 a R-M1-34 (C05 seul en M1) | config v1 |
| Duel : deck, manches, economie, etoiles, boutique, plateau | §10.1 a §10.6 | `Duel.luau` | M1-duel-minimal §3 | specifie M1 |
| Degats au joueur, fin de partie | §10.7 | `Duel.playerDamage*` | M1-duel-minimal §3.4 | recalibre (voir D-03) |
| Fantomes, emotes | §10.8, §10.9 | `Duel.ghostAfterSeconds`, `emoteCooldownSeconds` | aucune (M4) | hors M1 |
| Combat : timeline, actions, ciblage | §11.1 a §11.4 | `Combat.luau` | M1-combat R-M1-01 a R-M1-29 | specifie M1 |
| Formules | §11.5 | `Combat.damageVariance`, `critMultiplier`, `minimumDamage` | M1-combat R-M1-10 a R-M1-14 | specifie M1 |
| 13 statuts | §11.6 | `Combat.statuses` | M1-combat R-M1-35 a R-M1-49 | specifie M1 |
| Tactiques automatiques | §11.7 | `Combat.tactics` | M1-combat R-M1-50 a R-M1-54 | specifie M1 |
| Mode manuel (Histoire) | §11.8 | `Combat.manualTurnSeconds` | aucune (M2) | hors M1 |
| Interventions PvP, limites, journal | §11.9 a §11.11 | `Combat.focus*`, `suddenDeath*`, `drawAfterActions` | M1-combat R-M1-55 a R-M1-60 | specifie M1 |
| Modes Histoire, Versus, Classe | §12 | `Duel.trophies`, `arenaThresholds` | aucune (M2 a M4) | hors M1 |
| Oeufs, economie, limites, monetisation | §13 | `Eggs.luau`, `Economy.luau`, `Limits.luau` | aucune (M4) | hors M1 |
| FTUE, quetes, social, accessibilite | §14 | aucune | aucune (M2) | hors M1 |
| Direction artistique | §15 | aucune | bible DA (03) | hors GDD |
| Technique Roblox, securite, perf | §16 | `Limits.luau` | tickets T-0010, T-0011 | hors GDD |
| QA, cibles d'equilibrage | §19 | aucune | T-0015 (10 000 duels) | hors GDD |
| Jalons et gates | §21 | aucune | `PROCESS.md` | fige |

Hors perimetre du GDD v1 et de M1 : histoire, oeufs, classe, monetisation, assets finaux (brief §21, ligne M1).

## 2. Ce que M1 doit prouver

M1 est le premier jouable (brief §21). Il contient 10 unites greybox, 5 synergies activables, 1 Mega Combo (C05),
un duel complet contre un bot et entre 2 joueurs. Les deux specs M1 donnent une mesure par regle. Le gate M1
"l'humain trouve la boucle fun" est le seul critere non mesurable par les agents : il est `HUMAN_ACTION`
(`docs/playtest-humain.md`).

## 3. Decisions ouvertes

| ID | Question | Options | Qui tranche | Avant |
|---|---|---|---|---|
| D-01 | Preparation : 20 s manches 1 a 3 puis 30 s (brief §10.2) ou 30 s partout ? Config garde le brief. | A : brief ; B : 30 s partout ; C : 25 s partout | humain, apres A/B M4 | M2 |
| D-02 | Energie de depart et gains : le brief §11.3 (20 au depart, +20 attaque, +30 Garde) remplace les anciennes valeurs de `Combat.luau` (0, +25, +15). Applique en T-0009. | garder le brief | Game Designer | fait |
| D-03 | Degats au joueur : la formule du brief §10.7 (2 + palier + etoiles) donne une mediane de 20 manches dans `tools/sim_duel_length.py`, hors cible 8 a 11. Config passee a 6 + 4 x palier + 2 x etoiles (mediane 10). Le brief doit etre mis a jour. | A : config actuelle ; B : revenir au brief et baisser `playerHp` a 50 | Game Designer, verifie par T-0015 | M1 |
| D-04 | Mort subite : "+25 % cumules" lu comme multiplicatif (x1,25 par action au-dela de 40). Alternative additive (+25 points de % par action). Ferme par T-0024 : A, mesure T-0010 10 000 combats aleatoires = 0,88 % de nuls (cible < 2 %). | A : multiplicatif | fait (T-0024) | fait |
| D-05 | Duo : "2 x 120 %" lu comme chaque partenaire inflige une Attaque de base x 1,20. Ferme par T-0024 : A, 2 frappes separees avec variance et critique propres (R-M1-19). | A : 2 attaques | fait (T-0024) | fait |
| D-06 | Bot M1 : achats ponderes vers les synergies (spec duel §5) ou copie de plateaux enregistres (fantome, §10.8) ? | A : heuristique ; B : fantome | Dev serveur (cout) | M1 |
| D-07 | Tentafruit 2 (energie +15 %) : 5e synergie activable en M1, implementee si budget, sinon desactivee par drapeau. Ferme par T-0024 : A, actif par defaut, `options.tentafruitEnabled = false` pour les mesures QA. | A : implementer | fait (T-0010, T-0024) | fait |
| D-08 | Ordre fixe des modificateurs multiplicatifs (brief §11.5 "documente dans le code") : fige par R-M1-13. | aucune | fait | fait |
| D-09 | Nombre d'exemplaires du pool pour un deck sans Epique : le tirage retombe sur le cout inferieur (§10.5). Impact sur la vitesse de 3 etoiles non mesure. | mesurer | QA T-0015 | M2 |
| D-10 | Tactique Prudent dominee au miroir (R-M1-54) : avant, 2 000 combats miroir 5 unites M1 donnaient Agressif 87,7 % / Prudent 6,9 % / nuls 5,5 % (brief §11.7 : Garde Equilibre sous 25 %, Prudent sous 40 % ; spec : classes sans logique propre visent "en face"). Cause mesuree : la cible "en face" disperse les degats (Prudent sans aucune Garde plafonne a 24,0 %) et la Garde a 40 % boucle (l'unite garde a chaque tour sans jamais remonter). Correction : R-M1-52 vise `hp` min pour toutes les classes sans logique propre et `Combat.tactics` passe a Equilibre 0,20 / Prudent 0,25. Apres : Agressif 54,5 % / Prudent 43,2 % / nuls 2,3 % (T1) et 60,3 % / 39,7 % / 0,0 % (T2) ; Agressif / Equilibre 53,7 % / 45,4 % ; Equilibre / Prudent 45,9 % / 50,8 %. Essai ecarte : Prudent 0,28 seul (59,5 % / 37,7 %, marge de 2,7 points). Le brief §11.7 est a mettre a jour. | A : ciblage + Garde 0,20 / 0,25 ; B : Garde 0,28 seule | Game Designer (T-0024), verifie par T-0015 a 10 000 combats | fait |

## 4. Hypotheses a tester en playtest (humain, M1)

Instrument : `docs/playtest-humain.md`, 5 testeurs minimum dont 3 sur mobile, duel contre le bot puis entre 2 joueurs.

| ID | Hypothese | Mesure | Seuil |
|---|---|---|---|
| H-01 | Un duel complet contre le bot dure 7 a 10 min | chrono serveur entre la manche 1 et l'ecran de fin, mediane sur 10 duels | 7 min <= mediane <= 10 min |
| H-02 | Un duel dure 8 a 11 manches | compteur de manches, mediane sur 10 duels | 8 <= mediane <= 11 |
| H-03 | Un combat dure 20 a 35 s en vitesse x2 | `ActionLog` : actions x 0,8 s + animations, moyenne par duel | 20 s <= moyenne <= 35 s |
| H-04 | Le joueur voit et comprend la 1re synergie active | question Q2 du formulaire apres la manche 3 ("quelle synergie est active ?") | >= 4 testeurs sur 5 repondent juste |
| H-05 | Le joueur declenche C05 au moins 1 fois par duel | evenement `MegaComboFired`, part des duels | >= 60 % des duels |
| H-06 | La preparation de 20 s suffit aux manches 1 a 3 | part des manches 1 a 3 ou le joueur appuie "Pret" avant la fin | >= 50 % |
| H-07 | La preparation de 30 s n'est pas trop longue | part des manches 4+ ou le joueur appuie "Pret" avant 20 s | >= 50 % (sinon D-01 option C) |
| H-08 | Le joueur continue apres 10 min | question "continuer ou arreter" a 10 min | >= 70 % continuent |
| H-09 | L'ordre de focus est utilise | evenement `FocusOrder`, part des combats PvP | entre 30 % et 80 % |
| H-10 | Les degats au joueur sont lisibles | question Q4 ("combien de PV avez-vous perdu a la derniere manche ?") | >= 3 testeurs sur 5 a plus ou moins 2 PV |

Chaque hypothese echouee ouvre un ticket `type: spec` pour le Game Designer. Aucune ne se conclut par "le jeu est
fun" : on rapporte les mesures.

## 5. Historique

| Version | Date | Changement |
|---|---|---|
| 1.0 | 2026-10-02 | Index vivant, decisions D-01 a D-09, hypotheses H-01 a H-10 (T-0009) |
| 1.1 | 2026-10-02 | D-04, D-05, D-07 fermees ; D-10 (R-M1-52 et seuils de Garde, mesure R-M1-54 avant / apres) (T-0024) |
