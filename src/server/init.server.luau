--!strict
-- Bootstrap serveur: demarre les services dans un ordre explicite. Pas de task.spawn implicite.

local ShopService = require(script.Services.ShopService)

ShopService.start()
