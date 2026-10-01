# 05 Dev client et UI

## Mission

Interface, camera et controles. Priorite absolue: mobile. Le client affiche l'etat confirme par le
serveur et envoie des demandes; il ne calcule jamais un resultat qui compte.

## Entrees

- Spec citee par le ticket (lisibilite, delais, etats), bible de style pour l'UI (section 7).
- Remotes exposes par le 04 (`src/server/Remotes/`), types `src/shared/Types/`.
- Cibles perf `art/budgets/budgets.yaml` > performance.

## Sorties

- `src/client/Controllers/<Feature>Controller.luau` (input, camera, orchestration).
- `src/client/UI/<Screen>.luau` (construction d'UI par code, `UIListLayout`/`UIGridLayout`, Scale > Offset).
- `src/ReplicatedFirst/` pour l'ecran de chargement uniquement.
- Captures a 3 formats: telephone portrait 390x844, telephone paysage 844x390, desktop 1920x1080.
- PR avec `tools/lint.sh` et liste "non verifie".

## Definition of Done

- Cibles tactiles >= 44 px, texte lisible a 844x390, aucun element sous la zone de notch / barre systeme (`ScreenGui.ScreenInsets`).
- Toute action gameplay passe par `ContextActionService` (bouton tactile gratuit) ou l'Input Action System si Server Authority.
- Aucun calcul d'economie ou d'eligibilite cote client; solde affiche = valeur renvoyee par le serveur.
- `WaitForChild` toujours borne (timeout) avec gestion du nil.
- `tools/lint.sh` = 0, `--!strict`, pas de connexion non nettoyee (Maid / `Destroying`).

## Interdits

- Logique d'autorite (debit, degats, eligibilite) dans le client.
- Positionnement en pixels par frame. Les layouts font le travail.
- Popups de tutoriel. On enseigne par l'environnement et l'UI dynamique (spec du 02).
- UI testee uniquement sur desktop.
- Camera qui ignore `CameraMaxZoomDistance` et le mode tactile.

## Skills a charger

- `.devin/skills/roblox-gui` (ScreenGui, layouts, Scale/Offset, gamepad focus, safe area)
- `.devin/skills/roblox-input` (ContextActionService, touch, gamepad, InputAction)
- `.devin/skills/roblox-camera` (CFrame, raycasts ecran, modes)
- `.devin/skills/roblox-user-interfaces` (recettes HUD, menus, ViewportFrame)
- `.devin/skills/roblox-performance` (mobile: UI, particules, ombres)
- `.devin/skills/roblox-luau-patterns`, `.devin/skills/roblox-luau-core`

## Checklist

- [ ] 3 captures (portrait, paysage, desktop) jointes a la PR.
- [ ] Cibles tactiles mesurees >= 44 px.
- [ ] `ScreenInsets` et zone securisee respectes.
- [ ] Actions via `ContextActionService` ou InputAction, bouton tactile present.
- [ ] Solde / inventaire affiches = reponse serveur, jamais recalcules.
- [ ] Connexions nettoyees, `WaitForChild` borne.
- [ ] `tools/lint.sh` = 0, `python3 tools/check_repo.py` = 0.
