--!strict
-- Catalogue d'exemple. Les PRIX FONT AUTORITE COTE SERVEUR: le client lit ce module pour l'affichage
-- uniquement, le serveur relit la meme table pour debiter. Toute valeur envoyee par le client est ignoree.

local Economy = {
	items = {
		Potion = { price = 25, currency = "Coins" :: "Coins" },
		Torch = { price = 10, currency = "Coins" :: "Coins" },
	},
	purchaseCooldownSeconds = 0.5,
	maxPurchaseQuantity = 10,
}

table.freeze(Economy.items)

return table.freeze(Economy)
