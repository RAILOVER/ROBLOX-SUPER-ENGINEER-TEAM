# Kit UI du duel M1 : elements, tailles, etats et nommage

Role : 07-artiste-2d. Ticket T-0018. Source : brief §9.1, §10.2 a §10.7, §11.2, §15.6, §18.1. Valeurs chiffrees :
`src/shared/Config/Duel.luau` (`shopSlots = 5`, `benchSize = 6`, `playerHp = 100`, `maxLevel = 8`, `rerollCost = 2`,
`xpCost = 4`), `src/shared/Config/Combat.luau` (`boardRows = 2`, `boardColumns = 4`, `megaGaugeMax = 100`).
Formats : `art/budgets/budgets.yaml` > textures (`ui_max_size_px: 1024`, puissance de 2, PNG).

Statut : liste P1 (greybox). En M1 l'UI est faite de Frames et de couleurs plates par 05-dev-client-ui (T-0012) : **aucun
fichier de ce kit n'existe en M1**. Cette liste fixe les noms et les tailles pour que le client M1 puisse deja nommer ses
Frames comme les futures images, et pour que la generation M2 soit un remplacement 1 pour 1. **A aligner sur la bible**
`art/style-bible/BATTLEROT.md` (T-0014) : rayon des coins, epaisseur des bordures, police (section 7 de la bible).

## Regles communes

- **Taille minimale tactile : 44 x 44 px** pour tout element qu'on touche (bouton, case de boutique, case de banc, case de
  plateau, carte dans la timeline si elle ouvre une info-bulle). Reference : viewport mobile paysage 640 x 360 points, UIScale 1.
  Un element purement affiche (barre de PV, pastille de manche) peut descendre a 24 px.
- Pas de texte dans les images : tout libelle est un TextLabel (`LuckiestGuy` titres et chiffres, `FredokaOne` texte courant,
  UIStroke 2 a 4 px `#1A1A2E`, brief §15.6).
- Panneaux et boutons en **9-slice** : marges `SliceCenter` documentees ici, image source carree de 128 ou 256 px.
- Etats : `normal`, `pressed` (echelle 0,92 faite par le client, l'image `pressed` est juste plus sombre de 15 %), `disabled`
  (desature a 70 %), `selected` (contour or `#FFC93C` 6 px), `empty` (case vide), `highlight` (lueur verte `#3DDC5C` pour l'aide
  a la synergie, brief §8 encadre). Seuls les etats listes par element sont produits.
- Nommage : `assets/ui/ui_<element>_<etat>.png`, en anglais, minuscules, 1 underscore entre les mots. Pas de prefixe
  `Icon_`, `Thumbnail_` ou `GameIcon_` (reserves par `check_textures.py`). Les icones vont dans `art/prompts/icons.md`.

## Elements du duel M1

| # | Element (brief) | Fichiers futurs `ui_<element>_<etat>.png` | Image source | SliceCenter | Taille affichee min | Tactile |
|---|---|---|---|---|---|---|
| 1 | Boutique, 5 cases (`shopSlots`) | `ui_shop_slot_empty`, `_normal`, `_pressed`, `_disabled`, `_selected`, `_highlight` | 256 x 256 | 32,32,224,224 | 96 x 128 | oui, 44 px |
| 2 | Bouton Relancer (2 or) et bouton Acheter XP (4 or) | `ui_shop_button_normal`, `_pressed`, `_disabled` | 128 x 128 | 24,24,104,104 | 88 x 44 | oui, 44 px |
| 3 | Banc, 6 places (`benchSize`) | `ui_bench_slot_empty`, `_normal`, `_selected`, `_highlight` | 128 x 128 | 24,24,104,104 | 56 x 56 | oui, 44 px |
| 4 | Plateau 2 lignes x 4 colonnes (`boardRows`, `boardColumns`) | `ui_board_cell_empty`, `_normal`, `_selected`, `_highlight`, `_invalid` | 128 x 128 | 24,24,104,104 | 64 x 64 | oui, 44 px (cible de glisser-deposer) |
| 5 | Or (compteur, interets, serie) | `ui_gold_panel_normal` + `Icon_CurrencyGold` | 128 x 64 | 24,16,104,48 | 96 x 32 | non |
| 6 | PV des 2 joueurs (`playerHp` 100) | `ui_hp_bar_bg`, `ui_hp_bar_fill`, `ui_hp_portrait_frame_normal` | 256 x 64 et 128 x 128 | 16,16,240,48 | 160 x 24 | non |
| 7 | Manche et minuteur (20 s puis 30 s) | `ui_round_badge_normal`, `ui_round_badge_pve`, `ui_timer_ring_bg`, `ui_timer_ring_fill` | 128 x 128 | aucun (pas de 9-slice, anneau) | 48 x 48 | non |
| 8 | Panneau synergies (4 synergies en M1) | `ui_synergy_panel_normal`, `ui_synergy_row_inactive`, `_active`, `_highlight`, `ui_synergy_pip_off`, `_on` | 256 x 256, 256 x 64, 32 x 32 | 32,32,224,224 et 16,16,240,48 | ligne 160 x 32, pip 12 x 12 | ligne oui (info-bulle), 44 px de haut |
| 9 | Timeline, 10 prochaines actions (§11.2) | `ui_timeline_bar_normal`, `ui_timeline_slot_ally`, `_enemy`, `_current` | 1024 x 128 et 128 x 128 | 32,32,992,96 et 16,16,112,112 | portrait 64 x 64 | oui si info-bulle, 44 px |
| 10 | Bouton Mega Combo et jauge (`megaGaugeMax` 100) | `ui_megacombo_button_disabled`, `_normal`, `_pulse`, `_pressed`, `ui_megacombo_gauge_bg`, `ui_megacombo_gauge_fill` | 256 x 256 et 256 x 64 | bouton aucun (rond), jauge 16,16,240,48 | bouton 72 x 72, jauge 160 x 16 | oui, 72 px (appui simple et appui long, §9.1) |
| 11 | Bouton Pret (saute le minuteur) et boutons generiques | `ui_button_primary_normal`, `_pressed`, `_disabled` (or), `ui_button_secondary_*` (bleu), `ui_button_danger_*` (rouge) | 128 x 128 | 24,24,104,104 | 120 x 44 | oui, 44 px |
| 12 | Panneau generique (fond creme) | `ui_panel_cream_normal`, `ui_panel_blue_normal` | 256 x 256 | 48,48,208,208 | libre | non |

Compte M2 : 6 + 3 + 4 + 5 + 1 + 3 + 4 + 6 + 4 + 6 + 9 + 2 = 53 fichiers. Toutes les tailles sources sont des puissances de 2
et <= 1024.

## Portraits dans la timeline et les cases : 64 px

Les cases de boutique, de banc, de plateau et de timeline affichent le portrait rendu par Blender a **64 x 64 px** ou moins.
C'est la taille de reference du pilier 3 ("lisible en 64 px") et du protocole `docs/reports/legibilite-64px.md`. Le cadre
`ui_timeline_slot_*` laisse une fenetre interieure de 96 x 96 px sur 128 (marge 16) : a l'affichage 64 px, le portrait fait
48 px utiles. Si le test de lisibilite echoue a 48 px, la marge passe a 8 px (fenetre 112) avant de toucher au portrait.

## Couleurs provisoires des etats (brief §15.2, a aligner sur la bible)

| Etat | Couleur |
|---|---|
| normal, bouton principal | `#FFC93C` sur bordure `#1A1A2E` |
| normal, bouton secondaire et panneaux | `#2E7CF6` / fond `#FFF8E7` |
| pressed | meme teinte, luminosite -15 % |
| disabled | desature 70 %, alpha 0,6 |
| selected | contour `#FFC93C` 6 px |
| highlight (aide a la synergie) | lueur `#3DDC5C` |
| invalid (case de plateau interdite) | hachures `#FF4D4D` |
| Mega Combo pulse | `#FF8A00` avec halo `#FFC93C` anime par le client |

## Gabarit de prompt pour un element 9-slice (M2)

```
[SUJET]        : {element} game UI panel, rounded rectangle, bevelled border 12 px, flat center for 9-slice scaling,
                 state {etat}
[STYLE]        : cartoon mobile game UI, thick rounded shapes, bold dark outline #1A1A2E, saturated colors,
                 soft 2-tone shading, glossy highlights, playful, high readability at small size
[PALETTE]      : {palette}
[COMPOSITION]  : centered, 9-slice with margins of {SliceCenter} px, center zone plain and flat
[FOND]         : transparent
[NEGATIFS]     : no text, no letters, no numbers, no logo, no watermark, no Clash Royale UI, no Supercell or Riot asset,
                 no real person, no realistic photo, no gore, no suggestive content, no icon inside
[FORMAT]       : {taille source} png
```

Exemple rempli (`ui_shop_slot_empty.png`) :

```
[SUJET]        : shop slot game UI panel, rounded rectangle, bevelled border 12 px, flat center for 9-slice scaling,
                 state empty
[PALETTE]      : #1B3F8F #2E7CF6 #1A1A2E
[COMPOSITION]  : centered, 9-slice with margins of 32,32,224,224 px, center zone plain and flat
[FOND]         : transparent
[FORMAT]       : 256x256 png
```

## Verification M2

1. `python3 tools/check_textures.py` = 0 (taille <= 1024, PNG).
2. Capture du client avec chaque image appliquee a 3 tailles (min, x2, x4) : aucune deformation des coins (9-slice correct).
3. Mesure des zones tactiles sur un appareil Android d'entree de gamme (`HUMAN_ACTION`, capture avec regle a l'ecran) :
   toutes >= 44 px.
4. Verdict du Directeur artistique.
