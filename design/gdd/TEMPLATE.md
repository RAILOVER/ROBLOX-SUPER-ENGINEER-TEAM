# GDD: <Nom du jeu>  (version 0.x, phase P1)

Le GDD est court, versionne et testable. Chaque affirmation mesurable renvoie a une spec dans
`design/specs/`. La prose d'ambiance a sa place dans la bible de style, pas ici.

## 1. Pitch (3 phrases)

Quoi, pour qui, pourquoi on y revient.

## 2. Boucle de jeu

| Couche | Duree | Action | Recompense | Spec |
|--------|-------|--------|------------|------|
| Core (seconde a seconde) | 5 a 30 s | | | specs/core-loop.md |
| Meta (session) | 5 a 15 min | | | |
| Long terme (jours) | J1 a J30 | | | |

## 3. Onboarding (premieres 120 secondes)

| Temps | Ce que le joueur voit | Ce qu'il fait | Mesure (Funnel step) |
|-------|-----------------------|---------------|----------------------|
| 0 s | | | onboarding/1 |
| 30 s | premiere recompense | | onboarding/2 |

## 4. Progression

Courbe de puissance, paliers, deblocages. Formules explicites (ex: cout(n) = 50 * 1.15^n).

## 5. Economie

Renvoie a `design/economy/<nom>.md`. Resume: monnaies, sources, sinks, Game Passes, Developer Products.

## 6. Social et multijoueur

Ce qui se passe quand 1, 4, 12 joueurs sont presents. Fallback solo obligatoire.

## 7. Plateformes

Mobile d'abord. Controles tactiles, taille des cibles, orientation.

## 8. Risques et inconnues

Ce qu'on ne sait pas encore et le playtest qui doit le trancher.
