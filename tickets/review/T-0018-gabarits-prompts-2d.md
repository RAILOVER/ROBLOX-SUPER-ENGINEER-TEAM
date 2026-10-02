---
id: T-0018
title: Gabarits de prompts 2D (cartes, oeufs, icones) et grille de lisibilite 64 px
role: 07-artiste-2d
phase: P1-greybox
status: review
type: spec
priority: P2
depends_on: [T-0014]
spec: design/brief/BATTLEROT.md
acceptance:
  - "art/prompts/cards.md, eggs.md, icons.md : gabarits avec variables {slug, famille, rarete, palette}"
  - "docs/reports/legibilite-64px.md : protocole de test de lisibilite (portrait reduit a 64 px, 5 lecteurs) a appliquer en M2"
  - "aucune image generee commitee en P1"
---

## Contexte

Brief §18 et pilier 3 (lisible en 64 px). En greybox, seulement des gabarits et des protocoles.

## Travail attendu

Voir acceptance. Livre :

- `art/prompts/cards.md` : 3 gabarits (cadre de rarete, fond de famille, dos), exemple `tim-cheese`.
- `art/prompts/eggs.md` : 3 gabarits (oeuf entier, planche d'ouverture 4 x 4, icone), exemple Oeuf d'Or.
- `art/prompts/icons.md` : 3 gabarits, inventaire de 56 icones nommees, exemples `tim-cheese` (famille, classe, rarete) et Brulure.
- `art/prompts/ui-kit.md` : 12 elements du duel M1, 53 fichiers nommes `ui_<element>_<etat>.png`, tactile 44 px.
- `docs/reports/legibilite-64px.md` : protocole 64 px, 5 lecteurs, 3 s, cible 80 %, modeles CSV et tableau.

## Hors perimetre

Generation d'images (M2).

## Verification

```bash
python3 tools/check_repo.py
```

## Non verifie

- Aucun prompt n'a ete envoye a un modele d'image : la generation est hors perimetre (M2). Les gabarits ne sont donc pas
  testes sur un vrai modele ; le choix des mots STYLE et NEGATIFS reste a confirmer sur 4 generations en M2.
- La bible `art/style-bible/BATTLEROT.md` (T-0014) n'existe sur aucune branche distante au moment de la livraison : les hex
  de `{palette}` viennent du brief §15.2 et de `Rarities.luau`, marques "a aligner sur la bible".
- Les 10 unites M1 (`design/specs/M1-duel-minimal.md`, T-0009) ne sont pas encore choisies : le compte d'icones M2
  (25 a 30) est une estimation.
- Le protocole 64 px n'a pas ete joue avec des lecteurs : seules les commandes ImageMagick ont ete executees, sur 10 disques
  de couleur generes localement et non commites.
- Rien n'a ete ouvert dans Roblox Studio (taille tactile 44 px non mesuree sur appareil : `HUMAN_ACTION` en M2).
- `check_textures.py` tourne sur des dossiers `assets/` vides (0 erreur) : il ne prouve rien sur les noms proposes, seule la
  lecture du script le fait (prefixe `Icon_` = 512 carre, autres `ui_*` = taille <= 1024).
