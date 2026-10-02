---
id: S-0000
title: <Comportement a specifier>
owner: 02-game-designer
status: draft            # draft | validated | implemented | measured
---

# Spec: <titre>

Une spec decrit un comportement observable et la facon de le mesurer. Pas de prose vague.
Mauvais: "l'onboarding est fluide". Bon: "le joueur obtient sa premiere recompense en moins de 30 s".

## Enonce testable

> Le joueur <fait X> et observe <Y> en moins de <N> secondes / avec <probabilite> / dans <condition>.

## Mesure

| Metrique | Instrument | Seuil de succes | Ou lire |
|----------|------------|-----------------|---------|
| temps jusqu'a la premiere recompense | `AnalyticsService:LogFunnelStepEvent("onboarding", 2)` + horodatage serveur | mediane < 30 s, p90 < 60 s | Creator Hub > Funnels, ou log console en playtest |

## Regles

Liste numerotee des regles que le serveur applique. Chaque regle devient un test dans `tests/`.

1. ...
2. ...

## Cas limites

Que se passe-t-il si le joueur quitte, se deconnecte, triche, est AFK, est sur mobile.

## Tickets derives

- T-xxxx (04-dev-serveur): ...
- T-xxxx (05-dev-client-ui): ...
- T-xxxx (09-qa-reviewer): test automatise des regles 1 a N
