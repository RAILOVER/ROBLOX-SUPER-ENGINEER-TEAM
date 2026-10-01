# AGENTS.md: regles pour tout agent qui travaille dans ce repo

Lis ce fichier, puis `agents/<ton-role>/ROLE.md`, puis le ticket qui t'est assigne. Rien d'autre n'est
necessaire pour commencer. Si une information manque, ouvre un ticket `tickets/backlog/` pour le
Producteur au lieu de deviner.

## Cycle de travail d'un ticket

1. Le ticket est dans `tickets/in-progress/` avec `role:` = ton role. Sinon, tu ne le prends pas.
2. Tu lis les `acceptance:` du ticket. Chaque critere doit etre verifiable par un script, un test ou une capture.
3. Tu travailles sur une branche `<role>/<ticket-id>-<slug>`.
4. Avant la PR: `python3 tools/check_repo.py`, `tools/lint.sh` si tu as touche `src/`, `check_textures.py`
   si tu as touche `assets/`, `validate_mesh.py` si tu as touche un `.blend`.
5. La PR cite le ticket, colle la sortie des scripts, liste ce qui n'a PAS ete verifie.
6. Tu deplaces le ticket dans `tickets/review/` et mets `status: review`. Le QA ou le Producteur le passe en `done`.

## Regles de redaction

- Numeros, pas d'adjectifs. "Plus leger" n'est pas un resultat. "612 tris, 1 materiau, 1024 px" en est un.
- Executer avant d'ecrire. Un bloc de code non execute ne va pas dans la doc.
- Dire ce qui n'a pas ete verifie. Un rapport qui cache un trou vaut moins qu'un rapport court.
- Pas de tiret cadratin ni demi-cadratin dans les documents (verifie par `check_repo.py`).
- Francais pour les docs d'equipe et les tickets, anglais pour le code, les noms d'assets et les skills vendored.

## Frontieres

- Tu ne modifies pas `art/budgets/budgets.yaml` sans ticket valide par le Producteur et le Tech artist 3D.
- Tu ne modifies pas le ROLE.md d'un autre role. Tu proposes un ticket.
- Tu ne generes aucun asset final en phase P1 (greybox). Des cubes, des couleurs plates, c'est tout.
- Tu ne fais pas confiance au client. Jamais. Meme pour "juste l'affichage" si cela touche l'economie.
- Tu ne declares pas un jeu "fun". Tu mesures et tu rapportes; des humains jugent.

## Skills

Les skills de `.devin/skills/` sont charges automatiquement. Chaque ROLE.md liste ceux a lire en priorite.
Les sources upstream et leurs licences sont dans `.devin/skills/INDEX.md`.

## Roblox Studio et MCP

Le code est synchronise par Rojo (`rojo serve` cote humain avec Studio ouvert). Le MCP Roblox Studio
est integre a Studio (menu Assistant) et ne tourne que sur la machine qui execute Studio: voir
`docs/mcp-studio.md` pour ce qu'un agent peut faire avec ou sans acces a Studio.
