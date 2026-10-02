---
id: T-0014
title: Bible de style BATTLEROT v1 et references des 10 unites M1
role: 03-directeur-artistique
phase: P1-greybox
status: review
type: spec
priority: P1
depends_on: [T-0009]
spec: design/brief/BATTLEROT.md
acceptance:
  - "art/style-bible/BATTLEROT.md : palette (10 couleurs max avec hex), proportions, niveau de detail, grille de validation vision avec seuils"
  - "art/refs/<slug>/REFS.md pour les 10 unites M1 : 3 liens de reference canonique + traits signature + note de moderation (R7)"
  - "art/prompts/ : gabarits portrait de carte, oeuf, arene, avec variables"
  - "aucune image generee ni asset final commite"
---

## Contexte

Brief §15 et R10. La bible precede tout asset; en greybox on ne produit que des documents.

## Travail attendu

Voir acceptance. Les liens de reference sont des URL publiques, pas des copies d'images dans le depot.

## Hors perimetre

Validation d'assets (aucun asset en M1).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

- Aucun rendu n'existe en P1: les 17 criteres de la grille vision (bible section 10) n'ont ete appliques a aucun asset. Les seuils seront calibres sur les 3 premiers assets de P2.
- Les couleurs dominantes des 10 fiches `art/refs/` sont lues sur les images de couverture des references publiques (2026-10-02) et arrondies; elles n'ont pas ete mesurees sur un rendu BATTLEROT.
- Les comptes TikTok des videos d'origine (cites par Know Your Meme) n'ont pas pu etre verifies: TikTok renvoie HTTP 200 pour toute URL depuis cette machine. Les 3 URL par fiche sont donc Wikipedia, Know Your Meme et Wikimedia Commons uniquement.
- Les reglages de lumiere par arene (bible section 6) viennent du brief 15.5 et n'ont pas ete observes dans Roblox Studio (HUMAN_ACTION a la premiere greybox eclairee).
- Les gabarits `art/prompts/BATTLEROT.md` n'ont ete executes sur aucun generateur d'images (interdit en P1: aucune image generee ni commitee).
- Ecart E1 de la bible (1 seule orange `#F28C28` au lieu de `#FF8A00` + `#F28C28`) a valider par le Producteur.
