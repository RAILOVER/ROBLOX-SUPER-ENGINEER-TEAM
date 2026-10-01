# Bibliotheque de skills

Chargee automatiquement par Devin depuis `.devin/skills/`. Chaque ROLE.md liste ses skills prioritaires.
Les skills vendored gardent leur licence (`LICENSE.upstream`) et leur style; les skills `original` sont ecrits par l'equipe.

## Sources et licences

| Source | Licence | Skills vendored |
|--------|---------|-----------------|
| [TabooHarmony/roblox-brain](https://github.com/TabooHarmony/roblox-brain) | MIT | roblox-collaboration-mode, roblox-networking, roblox-security, roblox-data, roblox-server-data, roblox-luau-core, roblox-luau-patterns, roblox-luau-types, roblox-architecture, roblox-performance, roblox-gui, roblox-input, roblox-camera, roblox-lighting, roblox-building, roblox-npc-ai, roblox-analytics, roblox-game-design, roblox-growth-design, roblox-monetization, roblox-player-psychology, roblox-studio-mcp, roblox-tooling, roblox-publish-checklist |
| [nonlooped/roblox-suite](https://github.com/nonlooped/roblox-suite) | MIT | roblox-testing, roblox-user-interfaces, roblox-rojo |
| [mvvthw/roblox-claude-skills](https://github.com/mvvthw/roblox-claude-skills) | MIT | roblox-economy, roblox-datastore |
| [RobLe3/cc-blender-skill](https://github.com/RobLe3/cc-blender-skill) | MIT | blender-modeling, blender-export, blender-uv-texturing, blender-materials, blender-cameras, blender-lighting, atlas-uv-fitting, closed-surface-uv-coverage |
| Equipe (original) | ce repo | team-process, art-direction, game-design-roblox, roblox-sharp-edges, code-review-roblox, blender-python-api, level-design-fundamentals, gameplay-analytics |

## Consultes mais NON vendored (licence incompatible ou absente)

| Source | Raison | Usage autorise |
|--------|--------|----------------|
| brockmartin/roblox-game-skill | pas de fichier LICENSE | lecture en ligne seulement, rien copie |
| dig1t/skills (luau-type-expert, rojo-pro) | pas de fichier LICENSE | idem |
| LevyBytes/AI-SKILL-blender | AGPL-3.0 | lecture en ligne; remplace par `blender-python-api` original |
| fcsouza/agent-skills (game-dev) | GPL-3.0 | lecture en ligne; remplaces par `level-design-fundamentals`, `gameplay-analytics` originaux |
| Donchitos/Claude-Code-Game-Studios | MIT, oriente Unity/Unreal, 80 skills | source d'inspiration pour `team-process`; pas copie |
| 6xvl/robloxstudio-mcp-server, Chrrxs/robloxstudio-mcp | MIT, bridges MCP tiers | non installes sans audit QA (voir docs/mcp-studio.md) |

Les clones complets sont conserves hors repo dans `~/roblox-team-build/upstream/` sur la machine de preparation.

## Skills par role

| Role | Skills prioritaires |
|------|---------------------|
| 01 Producteur | team-process, roblox-collaboration-mode, roblox-publish-checklist, roblox-growth-design |
| 02 Game designer | roblox-game-design, game-design-roblox, roblox-player-psychology, roblox-monetization, roblox-economy, roblox-growth-design, roblox-analytics |
| 03 Directeur artistique | art-direction, roblox-lighting, roblox-building, blender-materials, blender-uv-texturing |
| 04 Dev serveur | roblox-networking, roblox-security, roblox-data, roblox-datastore, roblox-server-data, roblox-monetization, roblox-luau-patterns, roblox-luau-types, roblox-luau-core, roblox-architecture, roblox-sharp-edges, roblox-rojo, roblox-tooling |
| 05 Dev client UI | roblox-gui, roblox-input, roblox-camera, roblox-user-interfaces, roblox-performance, roblox-luau-patterns, roblox-luau-core |
| 06 Tech artist 3D | blender-modeling, blender-uv-texturing, blender-export, atlas-uv-fitting, closed-surface-uv-coverage, blender-python-api, roblox-building |
| 07 Artiste 2D | art-direction, roblox-building, blender-materials, roblox-growth-design, roblox-gui |
| 08 Level designer | roblox-building, roblox-lighting, roblox-game-design, level-design-fundamentals, roblox-performance, roblox-npc-ai |
| 09 QA reviewer | roblox-security, roblox-networking, roblox-testing, roblox-performance, roblox-publish-checklist, roblox-sharp-edges, roblox-luau-types, roblox-luau-core, code-review-roblox |
| 10 Analyste live ops | roblox-analytics, roblox-growth-design, roblox-player-psychology, roblox-monetization, gameplay-analytics |
