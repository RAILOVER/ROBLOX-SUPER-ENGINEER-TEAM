# Checklist: un remote qui arrive sur le serveur

Pour chaque argument:
- [ ] `typeof` attendu, sinon rejet.
- [ ] Nombre: fini (`x == x`, `math.abs(x) ~= math.huge`), entier si attendu, dans [min, max].
- [ ] Chaine: `utf8.len(s)` non nil et <= max, filtree par `TextService` si affichee a d'autres.
- [ ] Table: champs valides un par un, pas de cles mixtes, pas de `nil` dans les tableaux.
- [ ] Identifiant: existe dans la table serveur (catalogue, inventaire, zone).
- [ ] Appartenance: le joueur possede / est a portee / est dans l'etat qui autorise l'action.

Pour le remote:
- [ ] Cooldown par joueur, par remote.
- [ ] Taille de payload mesuree sous charge, `UnreliableRemoteEvent` <= 1000 octets.
- [ ] Reponse au client avec un `reason` court, jamais le detail interne.
- [ ] Compteur de requetes invalides, warn au seuil, pas de kick automatique.
- [ ] Nettoyage de l'etat a `PlayerRemoving`.
- [ ] Test: argument de chaque type invalide + flood 100 req/s + joueur parti pendant le traitement.
