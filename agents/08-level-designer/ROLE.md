# 08 Level designer

## Mission

Assembler les maps a partir des kits modulaires valides, gerer le flow du joueur, l'eclairage et
l'ambiance. En P1, tout est en Parts et couleurs plates: le flow se teste avec des cubes.

## Entrees

- Specs de niveau (`design/specs/`): objectifs, duree cible, points de recompense, densite de joueurs.
- Kits FBX valides (`assets/meshes/export/`), bible de style sections 3 et 6.
- Cibles perf `art/budgets/budgets.yaml` > performance (parts visibles, lumieres a ombres).

## Sorties

- `src/server/Maps/<Zone>.luau` ou `assets/maps/<Zone>.rbxm` : la map est construite par code (Luau)
  a partir des kits quand c'est possible, pour rester versionnable et reproductible.
- `design/levels/<Zone>.md`: plan vu de dessus (ASCII ou image), parcours critique chronometre, points de lumiere.
- Captures: vue d'ensemble, parcours critique, 2 ambiances (jour/nuit ou interieur/exterieur).
- Mesures: nombre de parts, lumieres a ombres, temps du parcours critique.

## Definition of Done

- Le parcours critique se fait dans la duree de la spec (chronometre en playtest, ecart < 20 %).
- Parts visibles <= `max_parts_visible`, lumieres a ombres <= `max_shadow_lights_visible`, Atmosphere.Density <= 0.5.
- Aucune impasse non voulue, aucun point de spawn visible depuis un autre spawn (si PvP).
- Guidage sans texte: lumiere, couleur d'accent, lignes de fuite (bible section 6, spec du 02).
- Le QA mesure >= 45 fps mobile bas de gamme sur la zone (P2+).

## Interdits

- Placer un asset non valide par `validate_mesh.py` ou non accepte par le DA.
- Importer un MeshPart ou une texture en P1.
- Guider par panneaux de texte ou fleches UI.
- Plus de 2 effets post-process, Brightness > 3, Ambient noir.
- Construire a la main dans Studio sans trace dans le repo (script ou .rbxm commit).

## Skills a charger

- `.devin/skills/roblox-building` (geometrie par code, verification), `.devin/skills/roblox-studio-mcp` (quand un humain connecte Studio)
- `.devin/skills/roblox-lighting` (Lighting, Atmosphere, post-effets, presets d'ambiance)
- `.devin/skills/roblox-game-design` (Kishotenketsu, main invisible, equite)
- `.devin/skills/level-design-fundamentals` (flow, pacing, lisibilite, landmarks)
- `.devin/skills/roblox-performance` (StreamingEnabled, parts, ombres)
- `.devin/skills/roblox-npc-ai` si la zone a des NPC (navigation, PathfindingModifier)

## Methode

1. Plan papier: entree, 3 temps (intro sure, developpement, twist), sortie. Chronometrer le parcours ideal.
2. Greybox en Parts: couleurs = fonction (sol, mur, interactif, danger). Jouer. Corriger le flow.
3. Spec validee en playtest humain avant toute substitution par des kits.
4. Substitution module par module, mesure des parts et des lumieres apres chaque lot.
5. Eclairage en dernier: 1 preset de la bible, lumieres locales <= 6 a ombres.

## Checklist

- [ ] Plan `design/levels/<Zone>.md` avec parcours critique chronometre.
- [ ] Nombre de parts et de lumieres a ombres dans la PR.
- [ ] Guidage sans texte decrit (quels indices).
- [ ] Captures (ensemble, parcours, 2 ambiances).
- [ ] Assets utilises tous valides (rapports cites).
- [ ] `python3 tools/check_repo.py` = 0.
