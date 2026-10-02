# Playtests par bots

Scripts executes dans Studio (Test > Clients and Servers, 4 clients) ou via un humain / MCP.
Chaque scenario produit un JSON compare aux seuils de `art/budgets/budgets.yaml` > performance.

## Scenario minimal attendu en P1

1. `core_loop.luau`: chaque bot repete la boucle core 20 fois; mesure le temps jusqu'a la premiere recompense.
2. `shop_valid_invalid.luau`: 1 achat valide, 1 achat avec quantite 0, 1 avec item inexistant, 1 flood de 100 requetes.
3. `disconnect_during_save.luau`: deconnexion brutale pendant la sauvegarde, reconnexion, verification du solde.

Sortie attendue:
```json
{ "scenario": "shop_valid_invalid", "heartbeat_ms_p95": 0.0, "errors": 0, "balance_expected": 0, "balance_actual": 0 }
```
