# Rojo: du repo a Roblox Studio

## Cote humain (machine avec Studio)

1. Installer le plugin Rojo dans Studio (`rojo plugin install` ou Marketplace "Rojo 7").
2. Dans le repo: `rojo serve default.project.json`.
3. Dans Studio: Rojo > Connect (localhost:34872). Les fichiers `src/` apparaissent dans l'explorateur.
4. Pour un fichier `.rbxl` de build: `rojo build default.project.json -o build/game.rbxl`.

## Cote agent (machine sans Studio)

- `rojo sourcemap default.project.json -o sourcemap.json` alimente `luau-lsp analyze` (voir `tools/lint.sh`).
- `rojo build` produit un `.rbxl` que l'humain ou le QA ouvre dans Studio.
- Aucun agent n'edite de script directement dans Studio: la source de verite est `src/`. Un script
  cree dans Studio hors Rojo est perdu a la prochaine synchro.

## Conventions de fichiers

| Fichier | Instance Roblox |
|---------|-----------------|
| `*.server.luau` | Script |
| `*.client.luau` | LocalScript |
| `*.luau` | ModuleScript |
| dossier avec `init.luau` | ModuleScript contenant ses enfants |
| `*.model.json` / `*.rbxm` | modele (eviter, prefere le code) |

Mapping complet dans `default.project.json`. `Packages/` (Wally) est ignore par git: `wally install`.
