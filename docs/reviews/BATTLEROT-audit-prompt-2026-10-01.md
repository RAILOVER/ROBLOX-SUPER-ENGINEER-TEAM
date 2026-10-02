# Audit du prompt BATTLEROT (2026-10-01)

Objet : le prompt genere par Claude (1 417 lignes, "PROMPT MAITRE : AUTO BATTLER BRAINROT") compare point par point
a la demande de l'humain. Le prompt source n'est pas pris comme source de verite : chaque ligne de la demande est
verifiee, et ce qui manque ou contredit la demande a ete corrige dans `design/brief/BATTLEROT.md` (voir son §0.1).

Legende : OK = couvert par le prompt source tel quel; CORRIGE = couvert apres modification; AJOUTE = absent du prompt
source, ajoute au brief.

## 1. La demande d'origine (prompt a Claude)

| # | Demande de l'humain | Verdict | Ou dans le brief | Preuve / remarque |
|---|---|---|---|---|
| 1 | Auto battler style TFT | OK | §10 (deck, manches, or, interets, boutique, etoiles, plateau 2x4, PV joueur) | Boucle TFT complete et chiffree (ex. probabilites de boutique par niveau). |
| 2 | Mode Histoire | OK | §12.1 | 8 chapitres x 10 niveaux, boss a mecanique, etoiles, energie, defi du jour, BD de narration. |
| 3 | Mode Versus simple pour l'instant | OK | §12.2 | Duel Amical + Duel Rapide, niveaux normalises a 11. |
| 4 | Champions LoL remplaces par des brainrots | OK | §7.2 | 28 brainrots italiens dans le lot L0. |
| 5 | Quelques fruits de l'ile de la Tentafruit | OK | §7.2, §8.1 | 14 fruits (Poirita + 4 couples + 5 tentateurs), noms verifies sur Wikipedia FR (article "Fruit Love Island" / "L'Ile de la Skibidi Tentafruit"). Maronito, Prunello, Mandarino, Raisino, Cocotier existent aussi dans la serie : reserve pour un lot ulterieur. |
| 6 | Arenes cartoonesques faites sur Blender | OK | §15.5, §17.6 | 8 arenes, kit modulaire bpy, plateau central + 3 plans de decor, `layout.json`. |
| 7 | Mix TFT x jeu de cartes style Clash Royale, raretes | OK | §7.1 | 5 raretes, niveaux de depart 1/3/6/9/11, max 16, Jokers, surplus en or. |
| 8 | Puissance calculee selon rarete ET niveau (systeme Clash Royale) | OK | §7.1, §7.3 | Stat(niv) = Stat_ref x 1,10^(niv-11); coefficient de rarete x1,00 a x1,50; baremes d'exemplaires et d'or par niveau. |
| 9 | Synergies entre chaque brainrot | OK | §8 | 9 familles + 7 classes, paliers chiffres, sous-roles Tentafruit, interactions de lore. Aide "+1 pour Mare 4 !". |
| 10 | Combat au tour par tour style Final Fantasy, plusieurs actions | OK | §11 | Timeline d'initiative, Attaque / Competence / Garde / Duo / Mega Combo, energie, statuts, tactiques type Gambits, mode manuel en Histoire. |
| 11 | Mega Combos sur synergie avec animations Blender | OK | §9, §17.5 | Jauge par equipe, 13 combos, cinematiques 4 a 6 s + version courte 2,5 s, camera_path.json, events.json. |
| 12 | Systeme de ranked | OK | §12.3 | Trophees, 8 arenes-seuils, Chemin des Trophees, Ligue a 3 000, saisons 28 j, MMR cache. |
| 13 | PvE qui debloque des oeufs (= coffres Clash Royale) | OK | §12.1, §13.2 a §13.4 | Oeufs par chapitre, couveuses (4), cycle de 240 oeufs, 10 types. |
| 14 | Recompenses PvP et PvE avec combats limites par heure / jour | OK | §13.5 | 5 victoires PvP recompensees par heure glissante, 20 par jour; energie Histoire 10 max, +1 / 12 min. |
| 15 | Visuels d'ouverture tres colores, cote addictif et fun, "copier le style Clash Royale" | CORRIGE | §15.7, R6, R8 | Le brief reprend l'energie (storyboard d'ouverture, particules, rebonds) mais interdit la copie d'assets et les dark patterns : c'est la seule facon d'etre publiable sur Roblox et de ne pas se faire retirer. La demande est respectee dans l'esprit, pas au pixel. |
| 16 | Prompt giga long et complet pour tout faire en un prompt | OK | tout le document | 1 466 lignes apres correction; decoupe en jalons P0, M0 a M6. |

## 2. Le changement "tres important" du 2026-10-01

| # | Demande | Verdict | Ou | Preuve / remarque |
|---|---|---|---|---|
| 17 | Ne pas se limiter a la Tentafruit ou aux brainrots italiens | CORRIGE | §7.4 | Le prompt source disait "roster ferme, aucun ajout" (3 occurrences). Remplace par un roster versionne par lots. |
| 18 | Les brainrots les plus mainstream | OK | §7.2 | Tralalero Tralala, Tung Tung Tung Sahur, Bombardiro Crocodilo, Ballerina Cappuccina, Cappuccino Assassino, Lirili Larila, Chimpanzini Bananini, Trippi Troppi, Bombombini Gusini, Brr Brr Patapim, La Vacca Saturno Saturnita... Tous ont une page Wikipedia EN (categorie "Internet memes introduced in 2025"), ce qui est un bon proxy de "mainstream". |
| 19 | Une synergie autour de la Tentafruit | OK | §8.1 | Famille Tentafruit (2/4/6) + sous-roles Couple, Tentation, Presentatrice. Regle 1 du §7.4 : elle reste unique. |
| 20 | Ensuite plein de personnages lies aux memes qui buzzent en ce moment | AJOUTE | §7.4, §7.5, `design/roster/lot-L1-memes-recents.md` | Lot L1 : shortlist de 8 personnages originaux inspires de memes de 2025-2026, puis un lot par saison. Le prompt source n'en avait aucun. |
| 21 | Se servir des API pour connaitre les tendances memes | AJOUTE | §7.5, `tools/trends/fetch_trends.py`, `docs/reports/trends-2026-10-01.md` | Pipeline en lecture seule, sans cle, reproductible. Les API a cle du catalogue public-apis sont listees et desactivees tant qu'aucune cle n'est fournie. |
| 22 | Six Seven comme exemple, mais des personnages encore plus recents | AJOUTE | lot L1 | "6-7" : 187 605 vues Wikipedia sur 30 jours, meme de fin 2025. Plus recents dans la shortlist : Punch (fevrier 2026), Jimothy (juillet 2026), pingouin nihiliste (janvier 2026). Six Seven est propose, pas pre-valide : il passe les 4 signatures du §7.4. |
| 23 | Organisation de l'equipe = cartes style Clash Royale, combat = TFT x Final Fantasy | OK | §7.1 (collection), §10 (duel TFT), §11 (combat FF) | Les trois couches sont separees et chacune a sa section chiffree. |
| 24 | Le jeu s'appelle BATTLEROT | CORRIGE | en-tete | 2 occurrences de `BRAINROT TACTICS` remplacees. |
| 25 | Executer avec l'equipe de 10 agents, API seulement si besoin | OK | §3, §5, §7.5 | Fiches des 10 agents conservees; les API sont reservees au pipeline de tendances (Agent 10). |

## 3. Problemes trouves dans le prompt source (au-dela de la demande)

| # | Probleme | Gravite | Correction |
|---|---|---|---|
| P1 | Structure de depot et format de ticket inventes, incompatibles avec le depot P0 existant (`tickets/<status>/*.md`, `check_repo.py`) | Haute | §3.2 et §3.3 reecrits pour pointer sur le depot existant. |
| P2 | "Un proces en 2026 porte notamment sur Tung Tung Tung Sahur" presente comme un fait, sans source | Moyenne | Reformule en risque a verifier (R6, `HUMAN_ACTION` validation juridique). |
| P3 | Test d'import Blender vers Roblox exige au M0 alors que les agents n'ont pas Studio | Moyenne | Reste au M0, marque `HUMAN_ACTION` (§21). |
| P4 | Runner de tests non tranche (T-0005 ouvert depuis P0) | Moyenne | Decision : Lune + runner compatible TestEZ en CI; TestEZ dans Studio pour le reste (§19.1). |
| P5 | Rien ne garantit un premier jouable avant le contenu complet | Moyenne | P0 ajoute, premier jouable fixe au M1 (§21). |
| P6 | Tirets cadratins partout (interdits par `check_repo.py`) | Basse | Remplaces automatiquement a l'import. |
| P7 | Chemins `/reports/`, `/reviews/` hors depot | Basse | Remplaces par `docs/reports/`, `docs/reviews/`. |

## 4. Ce que cet audit ne verifie pas

- L'equilibrage chiffre du prompt (stats, paliers, probabilites) n'est pas valide : il le sera par les simulations du QA (§19.3) a partir du M1.
- Le statut juridique des noms de brainrots et de la Tentafruit n'est pas verifie : `HUMAN_ACTION`.
- L'audience TikTok reelle des memes n'est pas mesuree (API a cle) : seules les vues Wikipedia et Imgflip, publiques et sans cle, ont ete lues.

## 5. Sources consultees

- Catalogue `public-apis/public-apis` (clone local) : entrees Imgflip, justmeme.wtf, Memesio, Giphy, Reddit, TikTok, YouTube, TrendsMCP, X.
- API Wikimedia pageviews et API MediaWiki (categories, extraits), sans cle.
- Imgflip `get_memes` et justmeme.wtf `trending` (sans cle) : templates classiques (Drake, Distracted Boyfriend...) utiles pour l'UI d'emotes, pas pour des personnages recents.
- Know Your Meme `/memes/trending` : 404 le 2026-10-01; Reddit JSON public : 403 sans identifiants. Non utilises.
