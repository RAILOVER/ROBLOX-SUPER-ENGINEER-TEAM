# Tickets

Un ticket = un fichier markdown = une unite de travail pour un seul role. Le Producteur cree et
deplace les tickets; l'agent assigne les fait avancer de `in-progress` a `review`.

Nom de fichier: `<id>-<slug>.md`, id au format `T-0001`. Le dossier reflete le `status:`.

| Dossier | status | Qui deplace |
|---------|--------|-------------|
| backlog | backlog | Producteur |
| in-progress | in-progress | Producteur (assignation) |
| review | review | agent assigne (PR ouverte) |
| done | done | QA ou Producteur apres validation |

Template: [TEMPLATE.md](TEMPLATE.md). Verification: `python3 tools/check_repo.py`.
