# Roblox Studio MCP: ce qu'un agent peut faire, et depuis ou

## Etat des lieux (verifie le 2026-10-01)

- Roblox fournit un serveur MCP integre a Studio (menu Assistant > MCP). Transport stdio, il tourne
  sur la machine qui execute Studio (Windows ou macOS).
- L'ancien `Roblox/studio-rust-mcp-server` est archive et renvoie vers le MCP integre.
- Des bridges tiers existent (`Chrrxs/robloxstudio-mcp`, `6xvl/robloxstudio-mcp-server`, MIT). Ils ne
  sont pas audites par cette equipe: on ne les installe pas sans ticket d'audit du QA.

## Consequence pour l'equipe

Les agents Devin tournent sur des VM Linux sans Studio. Trois modes de travail:

| Mode | Qui | Ce qui est possible |
|------|-----|---------------------|
| Offline (defaut) | tout agent | ecrire `src/`, `rojo build`, lint, tests Lune/Jest, scripts Blender |
| Studio via humain | humain avec Studio + Rojo | `rojo serve`, playtest, MicroProfiler, captures |
| Studio via MCP | humain qui connecte son client MCP (Claude Desktop, Cursor, VS Code) a Studio | executer du Luau dans Studio, lire la console, inserer des assets, lancer un play |

Un agent qui n'a pas acces a Studio le dit dans sa PR ("non verifie en Studio") et fournit un script
Luau pret a executer dans la barre de commande pour que l'humain verifie.

## Protocole MCP quand il est disponible

Resume de `.devin/skills/roblox-studio-mcp` (vendored):

1. `list_roblox_studios` puis passer `studio_id` a chaque appel.
2. `get_studio_state`: confirmer Edit / Client / Server.
3. Inspecter avant d'ecrire (`search_game_tree`, `script_read`).
4. Ecrire par lots bornes, relire apres chaque ecriture.
5. `start_stop_play`, `get_console_output`, `screen_capture` pour la preuve.
6. Nettoyer ce qui a ete cree pour le test.

## Option a decider par l'humain

Si l'equipe veut un agent capable de piloter Studio sans intervention humaine, il faut une machine
Windows avec Studio installe et un bridge MCP expose. Cela demande un compte Roblox dedie et une
decision explicite (ticket `type: arbitrage`). Ce n'est pas en place.
