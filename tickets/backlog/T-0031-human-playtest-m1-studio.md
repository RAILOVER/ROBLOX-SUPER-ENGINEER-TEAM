---
id: T-0031
title: HUMAN_ACTION playtest M1 dans Roblox Studio (solo contre bot, tactile emule, 2 joueurs)
role: 01-producteur
phase: P1-greybox
status: backlog
type: arbitrage
priority: P0
depends_on: [T-0011, T-0012, T-0019]
spec: design/specs/M1-duel-minimal.md
acceptance:
  - "les 32 etapes ci-dessous sont cochees avec le resultat observe (chiffre) ou marquees ECART avec capture"
  - "0 erreur et 0 warning [DuelController] dans la console apres un duel complet solo contre le bot"
  - "3 captures : paysage telephone emule (Preparation), paysage telephone emule (Combat), desktop 1280x720 (Resultat)"
  - "duree reelle chronometree de 3 combats, comparee a PlaybackPlan.totalSeconds affiche dans la console"
---

## Contexte

Les agents n'ont pas Roblox Studio (`AGENTS.md`). T-0012 livre le HUD greybox, le glisser-deposer et la lecture du
journal ; T-0011 livre le serveur. Tout ce qui suit est a executer par l'humain, dans l'ordre, et a renvoyer dans ce
ticket (section Resultats). Les valeurs attendues viennent de `src/shared/Config/Duel.luau` et `Combat.luau`.

## Prerequis

1. T-0019 fait : experience creee, `rojo serve default.project.json` lance, plugin Rojo connecte.
2. Branche a jour : `git fetch origin && git checkout devin/1790906273-battlerot-brief-m0 && git pull`.
3. Studio : View > Output ouvert, filtre sur "Duel".

## A. Play Solo contre le bot (12 etapes)

| # | Action | Resultat attendu |
| --- | --- | --- |
| A1 | Play (F5) | `PlayerGui.DuelHud` existe ; bandeau "Connexion au duel..." puis "En attente d'un adversaire..." |
| A2 | attendre | bot entre sous 5 s ; phase "Preparation", "Manche 1 (bot)", timer 20 s decroissant |
| A3 | lire le bandeau haut | "3 or", "Niv 2  XP 0/4", 2 barres de PV a 100 |
| A4 | lire la boutique | 5 cases avec nom + cout, toutes a 1 or (niveau 2 : 100 % cout 1) |
| A5 | tap sur la case 1 | l'unite apparait sur le banc, or = 2, case 1 "VENDU" ; delai ressenti < 0,3 s |
| A6 | glisser case 2 vers le banc | or = 1, 2 unites sur le banc |
| A7 | glisser case 3 vers le banc | or = 0, 3 unites ; glisser case 4 : rien ne change (refus serveur), la tuile ne reste pas |
| A8 | bouton "Relance (2 or)" | grise ou sans effet a 0 or ; boutique inchangee |
| A9 | glisser 1 unite du banc vers une case du plateau | tuile sur la case, "Plateau 1 / 2 (niveau 2)" |
| A10 | glisser une 3e unite vers le plateau (2 deja posees) | refusee : la tuile revient au banc sous 1 s |
| A11 | glisser une unite du banc vers "VENDRE" | elle disparait, or = +1 (cout de vente serveur) |
| A12 | bouton "PRET" | texte "PRET (envoye)", timer passe a 3 s, puis phase "Combat" |

## B. Combat et lecture du journal (8 etapes)

| # | Action | Resultat attendu |
| --- | --- | --- |
| B1 | debut du combat | camera "combat" ; 1 Part par unite des 2 camps sur les cases ; nom + barre de PV au-dessus |
| B2 | observer 10 s | l'attaquant avance vers sa cible puis revient ; nombre rouge "-N" sur la cible ; "+N" vert si soin |
| B3 | critique | nombre jaune suivi de "CRIT" |
| B4 | K.O. | la Part retrecit et disparait en 0,4 s ; texte "K.O." |
| B5 | timeline a droite | 10 lignes ; la 1re ligne change a chaque action ; lignes du camp adverse en fond rouge sombre |
| B6 | chronometrer le combat | duree entre la 1re action et le bandeau de resultat : entre 7 s et 31 s (plan M1 moyen 24,5 s) ; noter la valeur |
| B7 | fin | bandeau "MANCHE GAGNEE / PERDUE / NULLE" avec "degats joueur : vous X, adversaire Y" ; PV joueur mis a jour en haut |
| B8 | si un "MEGA" apparait dans la timeline | bandeau violet "MEGA COMBO Cxx" pendant 2,5 s ; bouton Mega a 100 % |

## C. Fin de duel et robustesse (4 etapes)

| # | Action | Resultat attendu |
| --- | --- | --- |
| C1 | jouer jusqu'a la fin (8 a 11 manches attendues) | bandeau "VICTOIRE / DEFAITE / EGALITE en N manches", PV finaux affiches |
| C2 | console Output | 0 erreur ; 0 ligne "[DuelController]" |
| C3 | Stop puis Play | le HUD se recree sans doublon (1 seul `DuelHud` dans `PlayerGui`) |
| C4 | redimensionner la fenetre pendant Preparation | le HUD suit ; aucun bouton < 44 px (mesurer avec l'explorateur : `AbsoluteSize`) |

## D. Tactile emule (4 etapes)

Test > Device > iPhone 14 (ou equivalent), orientation paysage, puis Play.

| # | Action | Resultat attendu |
| --- | --- | --- |
| D1 | lire le HUD | rien sous l'encoche ni sous la barre Roblox ; 3 colonnes visibles ; echelle 1 (canevas 400 px de haut) |
| D2 | glisser a 1 doigt boutique -> banc | achat ; le "fantome" suit le doigt ; la case cible est entouree d'or |
| D3 | 2 doigts simultanes | un seul glisser actif ; aucune erreur console |
| D4 | mesurer `ui_button_primary_ready.AbsoluteSize` | >= 44 x 44 |

## E. 2 joueurs en test local (4 etapes)

Test > Clients and Servers > 2 players, Start.

| # | Action | Resultat attendu |
| --- | --- | --- |
| E1 | les 2 clients rejoignent | "Manche 1" sans "(bot)" ; chaque client voit son propre nom a gauche et l'autre a droite |
| E2 | boutiques | differentes entre les 2 clients (tirages par siege) |
| E3 | combat | memes nombres de degats et meme resultat sur les 2 clients ; PV joueur coherents |
| E4 | un client quitte | l'autre recoit "VICTOIRE ... (forfeit)" apres 15 s (`ghostAfterSeconds`) |

## Resultats (a remplir par l'humain)

- Captures : ...
- Durees chronometrees (B6) : combat 1 ... s, combat 2 ... s, combat 3 ... s
- Ecarts constates : ...
- Decision : M1 greybox valide / a corriger (tickets a ouvrir pour 04-dev-serveur ou 05-dev-client-ui)

## Non verifie

Rien n'est verifie par les agents : ce ticket est entierement HUMAN_ACTION.
