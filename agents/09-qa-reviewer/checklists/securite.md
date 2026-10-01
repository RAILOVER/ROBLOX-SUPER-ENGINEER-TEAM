# Audit securite (avant chaque fin de phase P3+, et pour toute PR qui touche remotes / economie / data)

## CRITICAL (bloquant)
- [ ] Etat de jeu autoritaire cote serveur; modele d'autorite documente (classique ou Server Authority).
- [ ] Tous les arguments de remotes valides (type, bornes, NaN/inf, utf8, appartenance, etat).
- [ ] Rate limit par joueur sur chaque remote.
- [ ] DataStore avec session lock; `UpdateAsync`; `BindToClose`.
- [ ] Aucune mutation de monnaie initiee par le client.
- [ ] `ProcessReceipt` idempotent, `NotProcessedYet` quand le grant echoue, teste joueur absent.
- [ ] Aucun secret dans le code replique (`src/shared`, `src/client`).

## HIGH
- [ ] Mouvement / actions: transitions validees (distance, cooldown, etat), pas de sur-validation qui kick les joueurs legitimes.
- [ ] Echanges / trades atomiques.
- [ ] `ProximityPrompt`, `ClickDetector`, `DragDetector` valides comme des remotes.
- [ ] Teleports valides cote serveur.

## MEDIUM
- [ ] Cooldowns serveur, leaderboards calcules serveur, anti-AFK sur les recompenses.
- [ ] `TextService` sur tout texte joueur affiche.
- [ ] Logs des requetes invalides avec seuil, pas de kick sur 1 paquet.

## Tentatives d'exploit a executer (script `tests/playtest/exploit_*.luau`)
- [ ] Flood 100 req/s sur chaque remote: heartbeat reste < 16 ms.
- [ ] Argument NaN, inf, -1, 1e308, chaine 10 000 caracteres, table avec cles mixtes.
- [ ] Achat avec prix negatif / quantite 0 / item inexistant passe en argument.
- [ ] Double connexion du meme compte (2 Studio clients): aucune perte de donnees.
- [ ] Deconnexion pendant la sauvegarde: donnees intactes au retour.
