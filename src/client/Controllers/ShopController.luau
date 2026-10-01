--!strict
-- Le client AFFICHE et DEMANDE. Il ne calcule jamais un solde ni un prix qui fait foi.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local ShopController = {}

function ShopController.requestPurchase(
	itemId: string,
	quantity: number
): Types.RemoteResult<number>
	local remote = ReplicatedStorage:WaitForChild("Purchase", 10)
	if remote == nil or not remote:IsA("RemoteFunction") then
		return { ok = false, reason = "remote_missing" }
	end
	local ok, result = pcall(remote.InvokeServer, remote, itemId, quantity)
	if not ok then
		return { ok = false, reason = "invoke_failed" }
	end
	return result
end

return ShopController
