---
id: T-0006
title: Auditer le prompt BATTLEROT et produire le brief corrige
role: 01-producteur
phase: P0-preparation
status: review
type: audit
priority: P0
depends_on: [T-0005]
spec: design/brief/BATTLEROT.md
acceptance:
  - "docs/reviews/BATTLEROT-audit-prompt-2026-10-01.md compare chaque demande de l'humain (25 lignes) a une section du brief"
  - "design/brief/BATTLEROT.md : titre BATTLEROT, roster par lots (§7.4), pipeline tendances (§7.5), depot existant (§3.2), 0 tiret cadratin"
  - "src/shared/Config/* transcrit §7 a §13 et lune run tests/run.luau passe (integrite roster / synergies / combos)"
  - "python3 tools/check_repo.py et tools/lint.sh a 0 erreur"
---

## Contexte

L'humain a fourni un prompt genere par Claude et demande qu'il soit verifie point par point contre sa demande, corrige de
facon autonome (le prompt n'est pas une source de verite), puis execute par l'equipe. Nom impose : BATTLEROT.

## Travail attendu

- Audit tabule demande par demande, avec verdict OK / CORRIGE / AJOUTE.
- Brief corrige dans le depot, avec tableau des ecarts (§0.1).
- Transcription des tables de gameplay en config Luau (R2) et test d'integrite Lune.
- Rapport de tendances v1 et shortlist L1.
- Tickets M0 / M1 pour chaque role.

## Hors perimetre

Equilibrage chiffre (QA, M1), validation juridique (humain), assets.

## Verification

```bash
python3 tools/check_repo.py      # 0 erreur
tools/lint.sh                    # lint: OK
lune run tests/run.luau          # 13 tests OK
```

## Non verifie

Rien n'a ete ouvert dans Roblox Studio. L'equilibrage des tables n'est pas simule (T-0015).
