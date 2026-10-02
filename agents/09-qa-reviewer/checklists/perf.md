# Mesure de performance

Appareil de reference bas de gamme: telephone Android 3 Go RAM (ou emulation Studio: Device Emulator
telephone + Quality Level 1 + Network Simulator "mobile"). Noter l'appareil / l'emulation dans le rapport.

| Mesure | Outil | Cible (budgets.yaml) |
|--------|-------|----------------------|
| fps client mobile | Developer Console (F9) > Stats, ou MicroProfiler | >= 45 |
| fps client desktop | idem | >= 60 |
| heartbeat serveur | Server Stats | < 16 ms |
| memoire client | Memory tab, 10 min de jeu | stable, < 900 Mo |
| parts visibles | `#workspace:GetDescendants()` filtre BasePart dans la zone | <= 15 000 |
| lumieres a ombres | script d'inventaire | <= 6 |
| draw calls | MicroProfiler > Render | <= 2 500 |
| taille de join | Studio Settings > Network > Print Join Size Breakdown | note, en baisse |

Protocole: mesurer avant et apres la PR, meme zone, meme nombre de joueurs, 60 s chacun. Coller les deux series.
