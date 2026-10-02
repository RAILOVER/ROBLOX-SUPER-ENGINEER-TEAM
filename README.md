# ROBLOX-SUPER-ENGINEER-TEAM (roblox-studio-team)

Repo d'equipe pour un jeu Roblox produit par 10 agents specialises et valide par des humains.
Ici vivent la documentation de production (GDD, bible de style, tickets), le code Luau synchronise
vers Roblox Studio par Rojo, les sources Blender, et les scripts qui font respecter les budgets techniques.

**Etat: phase P0 (preparation).** Aucun jeu n'est encore defini. Ce repo forme l'equipe, il ne contient
pas encore de contenu de jeu. Le passage en P1 (greybox) est une decision du Producteur apres validation humaine.

## Les 10 roles

| # | Role | Dossier de formation | Produit |
|---|------|----------------------|---------|
| 1 | Producteur / orchestrateur | [agents/01-producteur](agents/01-producteur/ROLE.md) | backlog, tickets, decisions de phase |
| 2 | Game designer | [agents/02-game-designer](agents/02-game-designer/ROLE.md) | GDD, specs testables, economie |
| 3 | Directeur artistique | [agents/03-directeur-artistique](agents/03-directeur-artistique/ROLE.md) | bible de style, validation visuelle |
| 4 | Dev gameplay serveur (Luau) | [agents/04-dev-serveur](agents/04-dev-serveur/ROLE.md) | autorite serveur, anti-exploit, DataStore |
| 5 | Dev client et UI | [agents/05-dev-client-ui](agents/05-dev-client-ui/ROLE.md) | UI, camera, controles, mobile |
| 6 | Technical artist 3D (Blender) | [agents/06-tech-artist-3d](agents/06-tech-artist-3d/ROLE.md) | meshes, UV, LOD, collisions, FBX |
| 7 | Artiste 2D | [agents/07-artiste-2d](agents/07-artiste-2d/ROLE.md) | textures PBR, UI, icones, miniature |
| 8 | Level designer | [agents/08-level-designer](agents/08-level-designer/ROLE.md) | maps, flow, eclairage |
| 9 | QA / reviewer | [agents/09-qa-reviewer](agents/09-qa-reviewer/ROLE.md) | revue, tests, playtests bots, exploits |
| 10 | Analyste live ops | [agents/10-analyste-liveops](agents/10-analyste-liveops/ROLE.md) | telemetrie, retention, A/B |

Vue d'ensemble des interactions: [TEAM.md](TEAM.md). Phases et portes de validation: [PROCESS.md](PROCESS.md).
Regles valables pour tout agent qui entre dans ce repo: [AGENTS.md](AGENTS.md).

## Arborescence

```
agents/           formation par role (ROLE.md + checklists + exemples)
playbooks/        prompt de lancement d'une session Devin par role
.devin/skills/    bibliotheque de skills chargee automatiquement par les agents
design/           GDD, specs testables, economie (templates en P0)
art/              bible de style, templates de prompts, budgets.yaml (source de verite des contraintes)
tickets/          backlog -> in-progress -> review -> done (1 fichier markdown par ticket)
src/              code Luau (server / client / shared / ReplicatedFirst), mappe par default.project.json
assets/           meshes (source .blend, export .fbx, rapports), textures PBR, UI
tools/            scripts de validation: validate_mesh.py, check_textures.py, check_repo.py, lint.sh
tests/            tests Luau (Jest Lua / TestEZ) et scenarios de playtest bot
docs/             procedures outillage: Rojo, MCP Studio, playtests humains
```

## Projet en cours : BATTLEROT

Auto battler TFT x cartes Clash Royale x combat tour par tour Final Fantasy, avec des brainrots. Source de verite :
`design/brief/BATTLEROT.md` (audit du prompt d'origine dans `docs/reviews/BATTLEROT-audit-prompt-2026-10-01.md`).
Roster par lots dans `design/roster/` et `src/shared/Config/Roster/`; tendances memes dans `docs/reports/trends-*.md`
(`python3 tools/trends/fetch_trends.py`, sans cle). Les tickets P0 / M0 / M1 sont dans `tickets/`.

## Commandes de verification

```bash
tools/install_toolchain.sh                      # rojo, selene, stylua, luau-lsp, lune, wally (Linux x86_64)
python3 tools/check_repo.py                     # coherence tickets / roles / skills / liens / Luau / Rojo
tools/lint.sh                                   # stylua --check, selene, luau-lsp analyze
lune run tests/run.luau                         # tests unitaires Lune (specs *.spec.luau, API describe/it/expect)
python3 tools/check_textures.py                 # nommage, puissance de 2, jeux PBR complets
blender -b assets/meshes/source/<f>.blend --python tools/blender/validate_mesh.py -- \
  --budgets art/budgets/budgets.yaml --report assets/meshes/reports/<f>.json --export assets/meshes/export
```

Un script qui renvoie 1 bloque la PR. Aucun agent ne contourne un script: il corrige l'asset ou ouvre
un ticket pour changer `art/budgets/budgets.yaml`, arbitre par le Producteur.

## Principes non negociables

1. Les agents communiquent par fichiers (tickets, docs, PR), jamais par conversation.
2. Les budgets techniques sont juges par des scripts, le style par le Directeur artistique.
3. Greybox d'abord: aucun asset final tant que la boucle n'est pas jugee fun par des humains.
4. Le serveur fait autorite. Le client affiche et demande, il ne decide jamais.
5. Mobile d'abord pour l'UI et les controles.
6. Un humain joue a chaque jalon. Aucun agent ne decide qu'un jeu est amusant.
