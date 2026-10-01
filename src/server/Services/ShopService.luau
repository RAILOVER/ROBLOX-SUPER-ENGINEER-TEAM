--!strict
-- Exemple de reference: achat d'un objet avec autorite serveur complete.
-- Le client envoie (itemId, quantity). Le serveur relit le prix, verifie le solde, debite, puis repond.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local RemoteGuard = require(script.Parent.Parent.Remotes.RemoteGuard)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerProfile = Types.PlayerProfile

local ShopService = {}

-- Injecte par le DataService au demarrage (une seule source de verite pour le profil).
ShopService.getProfile = nil :: ((player: Player) -> PlayerProfile?)?

local itemIds: { string } = {}
for itemId in pairs(Economy.items) do
	table.insert(itemIds, itemId :: string)
end

local validators = {
	RemoteGuard.oneOf(itemIds),
	RemoteGuard.integerBetween(1, Economy.maxPurchaseQuantity),
}

function ShopService.purchase(
	player: Player,
	itemId: unknown,
	quantity: unknown
): Types.RemoteResult<number>
	if not RemoteGuard.check(player, { itemId, quantity }, validators, "ShopService.purchase") then
		return { ok = false, reason = "invalid_request" }
	end
	if not RemoteGuard.cooldown(player, "purchase", Economy.purchaseCooldownSeconds) then
		return { ok = false, reason = "too_fast" }
	end
	local getProfile = ShopService.getProfile
	local profile = if getProfile then getProfile(player) else nil
	if profile == nil then
		return { ok = false, reason = "profile_not_loaded" }
	end

	local item = Economy.items[itemId :: string]
	local total = item.price * (quantity :: number)
	if profile.coins < total then
		return { ok = false, reason = "insufficient_funds" }
	end

	profile.coins -= total
	profile.inventory[itemId :: string] = (profile.inventory[itemId :: string] or 0)
		+ quantity :: number
	return { ok = true, value = profile.coins }
end

function ShopService.start(): ()
	local remote = Instance.new("RemoteFunction")
	remote.Name = "Purchase"
	remote.Parent = ReplicatedStorage
	remote.OnServerInvoke = function(player: Player, itemId: unknown, quantity: unknown)
		return ShopService.purchase(player, itemId, quantity)
	end
	Players.PlayerRemoving:Connect(RemoteGuard.forget)
end

return ShopService
