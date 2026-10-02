--!strict
-- Index des tables de configuration BATTLEROT. Toute valeur de gameplay vit ici (brief R2), jamais en dur dans
-- un service. Le serveur relit ces tables pour calculer; le client les lit pour afficher.

return table.freeze({
	Economy = require(script.Economy),
	Rarities = require(script.Rarities),
	Progression = require(script.Progression),
	Combat = require(script.Combat),
	Roster = require(script.Roster),
	Synergies = require(script.Synergies),
	Combos = require(script.Combos),
	Skills = require(script.Skills),
	Duel = require(script.Duel),
	Eggs = require(script.Eggs),
	Limits = require(script.Limits),
	Arenas = require(script.Arenas),
})
