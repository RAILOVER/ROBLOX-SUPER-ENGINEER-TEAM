--!strict
-- Bootstrap serveur: demarre les services dans un ordre explicite. Pas de task.spawn implicite.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local ArenaBuilder = require(script.World.ArenaBuilder)
local DuelService = require(script.Services.DuelService)
local ShopService = require(script.Services.ShopService)

-- Arene greybox (T-0013) : construite au demarrage pour etre visible dans Studio des le Play.
ArenaBuilder.build(Workspace, Config.Arenas.byId[Config.Arenas.order[1]])

ShopService.start()
DuelService.start()
