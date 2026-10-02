--!strict
-- Point d'entree client (T-0012). Ordre explicite, comme le bootstrap serveur :
--   1. DuelController   : branche les remotes du contrat (ReplicatedStorage.DuelRemotes) et garde l'etat confirme ;
--   2. CameraController : cadrage "preparation" de Arena01 ;
--   3. CombatPlayback   : dossier Workspace.DuelPlayback pour les Parts de combat ;
--   4. HudController    : HUD greybox, abonne a DuelState / CombatLog / DuelEnded ;
--   5. DragDrop         : glisser-deposer sur les cases du HUD ;
--   6. JoinDuel         : premiere intention envoyee au serveur.

local DuelController = require(script.Controllers.DuelController)
local CameraController = require(script.Controllers.CameraController)
local CombatPlayback = require(script.Controllers.CombatPlayback)
local HudController = require(script.Controllers.HudController)
local DragDrop = require(script.Controllers.DragDrop)

local connected = DuelController.start()
CameraController.start()
CombatPlayback.start()
HudController.start()
DragDrop.start()
if connected then
	DuelController.join()
else
	warn("[client] contrat DuelRemotes indisponible : HUD affiche sans duel")
end
