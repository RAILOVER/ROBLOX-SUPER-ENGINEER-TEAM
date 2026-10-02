# Playtest humain: protocole minimal

Obligatoire a chaque fin de phase (voir PROCESS.md). Organise par le Producteur, mesure par le QA,
analyse par l'Analyste live ops a partir de P4.

## Avant

- 5 testeurs minimum, dont 3 sur mobile. Au moins 2 qui n'ont jamais vu le jeu.
- Build fige (`rojo build`), version notee dans `docs/reviews/<phase>-<date>.md`.
- Evenements Funnel `onboarding` actifs, console serveur enregistree.

## Pendant

- Aucune explication orale. Le jeu doit s'expliquer seul.
- Observateur silencieux: note l'heure de la premiere recompense, le premier blocage, le premier sourire.
- Session de 10 min, puis question: "tu continues ou tu arretes ?" Le choix est note.

## Apres (5 questions, echelle 1 a 5)

1. J'ai compris quoi faire dans la premiere minute.
2. J'ai eu envie de continuer apres 10 minutes.
3. Les controles etaient confortables sur mon appareil.
4. J'ai compris comment progresser.
5. Je reviendrais demain.

## Decision

| Mesure | Seuil P1 | Seuil P2+ |
|--------|----------|-----------|
| "je continue" a 10 min | 60 % | 70 % |
| premiere recompense | mediane < 30 s | mediane < 30 s |
| Q2 moyenne | >= 3.5 | >= 4 |
| fps mobile bas de gamme | non mesure | >= 45 |

Sous le seuil: la phase ne change pas. Le Producteur ouvre les tickets correctifs.
