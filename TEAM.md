# TEAM.md: qui produit quoi, pour qui

## Flux de fichiers entre roles

```
                    +------------------+
                    |  01 Producteur   |  tickets/, PROCESS.md, decisions de phase
                    +--------+---------+
                             | tickets
        +--------------------+---------------------+
        v                    v                     v
+---------------+   +----------------------+   +------------------+
| 02 Game       |   | 03 Directeur         |   | 09 QA / reviewer |
| designer      |   | artistique           |   | (lit tout)       |
| design/gdd    |   | art/style-bible      |   | tests/, reviews  |
| design/specs  |   | art/prompts          |   +------------------+
| design/economy|   | validation visuelle  |
+-------+-------+   +----------+-----------+
        | specs                 | bible + prompts
        v                       v
+---------------+   +---------------------+   +------------------+
| 04 Dev serveur|   | 06 Tech artist 3D   |   | 07 Artiste 2D    |
| src/server    |   | assets/meshes       |   | assets/textures  |
| src/shared    |   | tools/blender       |   | assets/ui        |
+-------+-------+   +----------+----------+   +--------+---------+
        |                      | kits FBX valides        | textures validees
        v                      v                         v
+---------------+   +-------------------------------------------+
| 05 Dev client |   | 08 Level designer                         |
| src/client    |   | assemble kits + eclairage dans Studio     |
+---------------+   +-------------------------------------------+
                                     |
                                     v  build jouable
                       +---------------------------+
                       | Humains: playtest jalon   |
                       +-------------+-------------+
                                     | telemetrie post-lancement
                                     v
                       +---------------------------+
                       | 10 Analyste live ops      |  -> propositions au Game designer
                       +---------------------------+
```

## Matrice RACI simplifiee

| Livrable | Responsable | Valide | Consulte |
|----------|-------------|--------|----------|
| Backlog, phases | 01 | humain | tous |
| GDD, specs, economie | 02 | 01 | 04, 05, 10 |
| Bible de style, prompts | 03 | 01 + humain | 06, 07, 08 |
| Code serveur, DataStore, remotes | 04 | 09 | 02, 05 |
| UI, camera, input, mobile | 05 | 09 + 03 (visuel) | 02, 04 |
| Meshes, LOD, collisions, FBX | 06 | script validate_mesh + 03 | 08 |
| Textures PBR, UI 2D, icone, miniature | 07 | script check_textures + 03 | 05, 10 |
| Maps, flow, eclairage | 08 | 03 + 09 (perf) | 02, 06 |
| Revue de code, tests, exploits, perf | 09 | 01 | 04, 05 |
| Telemetrie, retention, A/B | 10 | 01 | 02, 07 |

## Modeles et sessions

| Role | Mode Devin recommande | Pourquoi |
|------|-----------------------|----------|
| 01 Producteur | Ultra (modele le plus capable) | arbitre, decoupe, decide des phases |
| 02, 03, 09 | Normal | jugement et redaction longue |
| 04, 05, 06, 07, 08, 10 | Normal, Fast possible pour les tickets mecaniques | execution outillee |

Chaque session d'agent est lancee avec son playbook `playbooks/<role>.md` et un seul ticket.
Une session = un ticket = une PR. Pas de session "fais tout".

## Points de synchronisation

- Fin de chaque phase: le Producteur ecrit `docs/reviews/<phase>-<date>.md` avec les mesures et le verdict humain.
- Toute modification de `art/budgets/budgets.yaml`: ticket, accord 01 + 06, re-execution des scripts sur tous les assets.
- Conflit entre deux roles: ticket `type: arbitrage` pour le Producteur. Il tranche en moins de 1 cycle.
