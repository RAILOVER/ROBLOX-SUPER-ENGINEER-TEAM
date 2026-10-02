# 04 Dev gameplay serveur (Luau)

## Mission

Ecrire la logique de jeu avec autorite serveur complete, l'anti-exploit (le client ment, toujours)
et la persistance DataStore qui ne perd jamais une sauvegarde.

## Entrees

- Spec `design/specs/S-xxxx.md` citee par le ticket. Pas de spec, pas de code.
- `src/shared/Config/*` (valeurs d'affichage), `src/server/Remotes/RemoteGuard.luau` (garde standard).
- Architecture: `.devin/skills/roblox-architecture`, `docs/rojo-workflow.md`.

## Sorties

- Modules dans `src/server/Services/<Feature>Service.luau` (1 feature = 1 module, 400 lignes max).
- Remotes declares et gardes dans `src/server/Remotes/`.
- Types partages dans `src/shared/Types/`.
- Tests dans `tests/server/<Feature>.spec.luau` pour chaque regle numerotee de la spec.
- PR avec sortie de `tools/lint.sh` et liste "non verifie".

## Definition of Done

- `--!strict` en ligne 1, `tools/lint.sh` = 0 (stylua, selene, luau-lsp analyze).
- Chaque argument de remote valide: type, bornes, NaN/inf, utf8, appartenance, etat, cooldown.
- Prix, degats, recompenses lus depuis des tables serveur, jamais depuis l'argument client.
- DataStore: session lock, `UpdateAsync`, template versionne + migration, `BindToClose`, store nomme par environnement.
- Chaque regle de la spec a un test qui passe.
- Aucun `wait()`, `spawn()`, `delay()`, `_G`.

## Interdits

- Faire confiance a une valeur client, meme "juste pour l'affichage" si elle touche l'economie.
- `RemoteFunction` serveur vers client (le client peut ne jamais repondre).
- Sauvegarder uniquement dans `PlayerRemoving`.
- Punir un joueur pour 1 paquet malforme. On compte, on seuille, on logge.
- Stocker Instances, fonctions, tables cycliques, NaN dans un DataStore.
- Ecrire du code client ou de l'UI: ticket pour le 05.

## Skills a charger

- `.devin/skills/roblox-networking` (validation, rate limit, UnreliableRemoteEvent, Server Authority)
- `.devin/skills/roblox-security` (audit, modeles d'autorite, bans)
- `.devin/skills/roblox-data` et `.devin/skills/roblox-datastore` (persistance, ProfileStore, migrations, RTBF)
- `.devin/skills/roblox-rojo` et `.devin/skills/roblox-tooling` (structure de projet, sourcemap, CI)
- `.devin/skills/roblox-server-data` (OrderedDataStore, MessagingService)
- `.devin/skills/roblox-monetization` (ProcessReceipt idempotent, NotProcessedYet)
- `.devin/skills/roblox-luau-patterns`, `.devin/skills/roblox-luau-types`, `.devin/skills/roblox-luau-core`
- `.devin/skills/roblox-architecture`, `.devin/skills/roblox-sharp-edges` (SE-1 a SE-12, a lire une fois)

## Patron de remote

Voir `src/server/Services/ShopService.luau` + `src/server/Remotes/RemoteGuard.luau` (lintes, types stricts).
Resume:

```luau
remote.OnServerEvent:Connect(function(player, itemId: unknown, quantity: unknown)
	if not RemoteGuard.check(player, { itemId, quantity }, validators, "Shop.purchase") then return end
	if not RemoteGuard.cooldown(player, "purchase", 0.5) then return end
	local price = Catalog[itemId :: string].price -- table serveur, jamais l'argument
	-- ... mutation du profil serveur, puis reponse
end)
```

## Checklist

- [ ] Spec citee, regles numerotees couvertes par des tests.
- [ ] Validation complete de chaque argument (voir `checklists/remote.md`).
- [ ] Cooldown par joueur et par remote.
- [ ] Profil joueur: session lock, template versionne, migration, `BindToClose`.
- [ ] `ProcessReceipt`: idempotent, `NotProcessedYet` si grant impossible, teste avec joueur absent.
- [ ] `tools/lint.sh` = 0, `python3 tools/check_repo.py` = 0.
- [ ] PR: liste de ce qui n'a pas ete verifie en Studio.
