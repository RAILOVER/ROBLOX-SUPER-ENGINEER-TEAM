# BATTLEROT : BRIEF MAITRE (auto battler brainrot, Roblox)
### Brief complet pour une equipe de 10 agents IA

> **Titre du jeu :** `BATTLEROT` (fixe par l'humain le 2026-10-01).
> **Genre :** auto battler facon TFT x jeu de cartes a collection facon Clash Royale x combat au tour par tour facon Final Fantasy.
> **Plateforme :** Roblox (mobile d'abord, puis PC, console, tablette).
> **Langues :** francais et anglais. Les noms des brainrots ne se traduisent jamais.
> **Statut :** prompt source (genere par Claude) verifie point par point et corrige par le Producteur le 2026-10-01.
> Audit : `docs/reviews/BATTLEROT-audit-prompt-2026-10-01.md`. Les ecarts avec le prompt source sont au §0.1.
> Ce fichier est la source de verite du projet; le prompt source n'en est plus une.
---

## 0. COMMENT UTILISER CE DOCUMENT

1. Ce document entier est donné à l'**Agent 1 : Producteur / Orchestrateur**. C'est sa source de vérité.
2. Chaque autre agent reçoit les sections **1 à 4** (vision, règles, organisation, protocole). Il reçoit aussi **sa propre fiche** de la section 5 comme prompt système. Le Producteur lui transmet ensuite les sections de GDD, d'art ou de tech dont il a besoin.
3. Le jeu est développé **en une seule mission**, découpée en jalons M0 → M6 (section 21). Aucun agent ne passe au jalon suivant tant que le *gate* du jalon en cours n'est pas validé.
4. Toute ambiguïté se règle ainsi. Le Game Designer tranche le gameplay, le Directeur Artistique tranche le visuel, l'Architecte (Agent 4) tranche la technique. Le Producteur arbitre les conflits entre eux. Ce qui ne peut pas être tranché passe en `HUMAN_ACTION`.

### 0.1 Ecarts par rapport au prompt source (decisions du 2026-10-01)

| # | Prompt source | BATTLEROT (ce document) | Pourquoi |
|---|---|---|---|
| E1 | Titre `BRAINROT TACTICS` | `BATTLEROT` | Demande explicite de l'humain. |
| E2 | Roster ferme de 42 personnages, "aucun ajout" | Roster **versionne par lots** (§7.4) : lot L0 = 42 personnages brainrots italiens + Tentafruit, lots L1+ = brainrots mainstream et memes recents | L'humain veut les brainrots les plus mainstream, une synergie Tentafruit, puis beaucoup de personnages lies aux memes qui buzzent. |
| E3 | Rien sur la veille des tendances | **Pipeline de tendances** (§7.5) : signaux publics agreges, score, filtres, shortlist, validation humaine | Demande explicite : "sers-toi des API pour connaitre les trends". Aucune API ne cree de contenu en production. |
| E4 | Structure de depot et format de ticket YAML inventes | Structure et tickets **du depot existant** (`AGENTS.md`, `tickets/TEMPLATE.md`, `PROCESS.md`) | Le depot d'equipe P0 existe deja et a ses gates scriptes. |
| E5 | "Un proces en 2026 porte sur Tung Tung Tung Sahur" affirme comme un fait | Reformule en risque a verifier par l'humain (R6) | Non source. On n'ecrit pas de fait juridique sans source officielle. |
| E6 | Un seul bloc M0 a M6 | Ajout d'un **P0 validation du brief** et d'un premier livrable jouable des **M1** (§21) | Le premier jouable ne doit pas attendre 42 personnages et 8 arenes. |
| E7 | Runner de tests non choisi | **Lune + runner maison compatible TestEZ** pour les modules purs, TestEZ dans Studio (T-0005, §19.1) | Les tests doivent tourner en CI Linux sans Studio. |
| E8 | Import Blender vers Roblox "au M0" | Reste au M0 mais marque `HUMAN_ACTION` : Studio n'existe pas sur les machines des agents | Honnetete sur ce qui est verifiable. |
| E9 | Mega Combos inspires des memes seulement italiens | Les lots L1+ apportent leurs propres combos (ex. combo "6 7" a 2 unites) | Coherence avec E2. |

Tout ce qui n'est pas dans ce tableau est repris du prompt source tel quel, car il coche la demande de l'humain (voir l'audit).

---

## 1. VISION

### 1.1 Pitch en une phrase
Collectionne les brainrots les plus mainstream, les fruits de L'Île de la Skibidi Tentafruit et les memes qui buzzent en ce moment (roster par lots, §7.4). Fais-les monter de niveau comme des cartes Clash Royale. Construis ton équipe en duel façon TFT. Regarde-les s'affronter au tour par tour comme dans un Final Fantasy, et déclenche des **Méga Combos** cinématiques quand tes synergies s'alignent.

### 1.2 Piliers (tout ce qui est produit doit servir au moins l'un d'eux)
1. **« J'ouvre un œuf et ça explose de couleurs. »** L'ouverture d'œufs est le moment le plus satisfaisant du jeu. Elle reprend l'esprit des coffres de Clash Royale.
2. **« Mon équipe, mes synergies, mon combo. »** Chaque partie pousse à chercher une synergie. La récompense est un Méga Combo spectaculaire.
3. **« Je reconnais tout de suite mes brainrots. »** Chaque personnage garde ses traits mèmes signature. Il est lisible en 64 px sur un téléphone.
4. **« Une partie de plus. »** Les sessions sont courtes, les objectifs toujours visibles et les récompenses fréquentes, avec un rythme limité par heure et par jour.

### 1.3 Public et contraintes
- Public principal : joueurs Roblox de 9 à 16 ans, fans des mèmes brainrot. Le contenu doit être **adapté aux enfants** et conforme aux règles communautaires de Roblox.
- Une très grande partie des joueurs est sur **mobile**. Tout est conçu d'abord pour un écran tactile en mode paysage et un appareil Android d'entrée de gamme.
- Session cible : 12 à 20 minutes. Duel cible : 7 à 10 minutes. Combat d'histoire cible : 1,5 à 3 minutes.

### 1.4 Indicateurs de succès visés au lancement
| Indicateur | Cible |
|---|---|
| Fin du tutoriel (FTUE) | ≥ 70 % des nouveaux joueurs |
| Rétention J1 | ≥ 35 % |
| Rétention J7 | ≥ 12 % |
| Durée moyenne de session | ≥ 15 min |
| Taux de crash client | < 1 % des sessions |
| Duels terminés sans abandon | ≥ 85 % |

---

## 2. RÈGLES ABSOLUES (NON NÉGOCIABLES)

**R1. Le serveur fait autorité.** Tout calcul de combat, de récompense, d'économie et de tirage aléatoire se fait côté serveur. Le client ne fait qu'**afficher** et **demander**. Aucune valeur envoyée par un client n'est jamais crue sans validation.

**R2. Tout est piloté par les données.** Les stats, raretés, coûts, probabilités, synergies, limites et récompenses vivent dans des tables de configuration (`src/shared/Config/`). Aucune valeur de gameplay n'est codée en dur. Retirer ou remplacer un personnage doit tenir en une modification de config et un échange d'asset.

**R3. Greybox d'abord.** Aucun asset final n'est produit avant que la boucle de duel ne soit jouable et validée avec des formes primitives (gate M1).

**R4. Celui qui produit ne valide jamais son propre travail.** Le code est validé par l'Agent 9 (QA). L'art est validé par l'Agent 3 (DA). Le design est validé par simulation (Agent 9) puis par l'humain.

**R5. Les budgets techniques sont vérifiés par des scripts, pas par des LLM.** Nombre de triangles, taille des textures, nombre d'os, nommage et échelle passent par des scripts de validation. Un asset qui échoue est rejeté automatiquement.

**R6. Propriété intellectuelle :**
- Clash Royale (Supercell) et TFT (Riot) sont des **inspirations de mécaniques et d'ambiance** uniquement. Il est interdit de reprendre leurs assets, logos, polices, sons, noms de marque ou maquettes d'interface copiées au pixel. Le titre du jeu ne contient ni « Clash », ni « Royale », ni « Teamfight ».
- Aucun logo de marque réelle n'est utilisé, ni sur les personnages ni ailleurs. Par exemple, les baskets de Tralalero Tralala sont bleues et **sans logo**.
- Les brainrots italiens et les personnages de la Tentafruit sont des mèmes dont le statut juridique est **contesté**. Des revendications de droits par des createurs de ces memes ont ete rapportees par la presse; aucune n'est verifiee ici et aucune ne doit etre citee comme un fait sans source officielle. Le Producteur ouvre un ticket `HUMAN_ACTION: validation juridique du roster` avant la publication publique. Grâce à R2, n'importe quel personnage doit pouvoir être retiré sans casser le jeu.
- Les **audios et narrations TikTok d'origine ne sont jamais réutilisés**. Certains contiennent des propos injurieux, blasphématoires ou des références à des bombardements réels. On ne reprend que les **apparences** et les **noms**.

**R7. Ton adapté aux enfants.**
- La violence est cartoon. Un K.O. se traduit par un « pouf » d'étoiles et le personnage sort du terrain. Personne ne meurt, il n'y a pas de sang.
- Les bombes sont des bombes de dessin animé avec une mèche et un « KABOOM ».
- La série d'origine de la Tentafruit a été critiquée pour son sexisme. Dans ce jeu, les fruits gardent leur **énergie télé-réalité** : drama, cérémonies, clins d'œil, jalousies comiques, couples. Il n'y a **aucune sexualisation**, aucune tenue suggestive et aucun humour sexiste. Les tentateurs et tentatrices sont des rôles de gameplay de *charme comique* (confusion), rien de plus.

**R8. Conformité Roblox.**
- Les œufs peuvent s'obtenir contre de la monnaie premium achetée en Robux. Ils relèvent donc des **objets aléatoires payants**. Les probabilités exactes s'affichent **avant tout achat**, pour **tous** les œufs. L'agent concerné vérifie la politique Roblox à jour sur les objets aléatoires payants (restrictions par pays ou par âge) et l'applique.
- Pas de *dark patterns* : pas de faux comptes à rebours, pas de pression à l'achat après une défaite, pas d'offres trompeuses.
- Tout texte saisi par un joueur (pseudo d'équipe, etc.) passe par `TextService` (filtrage). Le jeu n'a pas de chat libre en duel, seulement des emotes prédéfinies.

**R9. Les fichiers sont la source de vérité.** Les agents communiquent par fichiers dans le dépôt (tickets, specs, revues). Une décision prise en conversation qui n'est pas écrite dans un fichier n'existe pas.

**R10. Les références canoniques priment.** Les descriptions de personnages dans ce document sont des résumés. Avant toute modélisation, le DA rassemble **3 images de référence canoniques par personnage** (mème d'origine et apparitions les plus connues). En cas de divergence, la référence canonique l'emporte sur ce document.

---

## 3. ORGANISATION DE L'ÉQUIPE

### 3.1 Les 10 agents

| # | Agent | Couche | Produit | Validé par |
|---|---|---|---|---|
| 1 | Producteur / Orchestrateur | Direction | Backlog, tickets, arbitrages, planning, rapports | Humain |
| 2 | Game Designer | Direction | GDD, tables de config, équilibrage, histoire | Agent 9 (simulation) + humain |
| 3 | Directeur Artistique | Direction | Bible de style, références, prompts d'images, validations visuelles | Humain |
| 4 | Dev Gameplay Serveur (Luau) : aussi Architecte | Production | Architecture, simulation de combat, économie, données, matchmaking | Agent 9 |
| 5 | Dev Client & UI (Luau) | Production | Interfaces, caméra, affichage du combat, ouverture d'œufs, effets visuels | Agent 9 + Agent 3 (visuel) |
| 6 | Technical Artist 3D (Blender / bpy) | Production | Personnages, rigs, animations, Méga Combos, pipeline d'export | Agent 3 + scripts de validation |
| 7 | Artiste 2D (génération d'images) | Production | Textures, portraits de cartes, UI, icônes, effets, miniatures | Agent 3 |
| 8 | Level Designer / World Builder | Production | 8 arènes cartoon, lobby, éclairage, ambiance | Agent 3 + Agent 9 (perf) |
| 9 | QA / Reviewer | Validation | Revues de code, tests, simulations d'équilibrage, perf, exploits | Producteur |
| 10 | Analyste Live Ops | Validation | Télémétrie, entonnoirs, tableaux de bord, A/B tests, feuille de route des mises à jour | Producteur + humain |

### 3.2 Structure du depot (depot d'equipe existant, ne pas recreer)

Le depot `RAILOVER/ROBLOX-SUPER-ENGINEER-TEAM` existe depuis P0 avec ses gates scriptes. BATTLEROT s'y installe :

```
AGENTS.md, PROCESS.md, TEAM.md       regles d'equipe, phases, flux de fichiers (lecture obligatoire)
agents/<role>/ROLE.md                formation de chaque role
design/brief/BATTLEROT.md            ce document
design/gdd/                          GDD vivant (Agent 2)
design/specs/                        specs testables (Agent 2)
design/economy/                      tables et simulations economiques (Agent 2)
design/roster/                       lots du roster, fiches, shortlists de tendances (Agent 2 + Producteur)
art/style-bible/                     bible de style (Agent 3)
art/refs/<slug>/                     3 references canoniques par personnage (Agent 3)
art/prompts/                         gabarits de prompts d'images (Agent 3)
art/budgets/budgets.yaml             budgets techniques (source de verite des scripts)
assets/meshes/source/*.blend         sources Blender (Agent 6), assets/meshes/export/ FBX
assets/textures/, assets/ui/         images (Agent 7)
tools/blender/                       scripts bpy : generation, rig, export, validation (Agent 6)
tools/trends/                        collecte de tendances en lecture seule (Agent 10)
src/shared/Config/                   TOUTES les tables de gameplay
src/shared/Types/                    types Luau stricts
src/shared/Combat/                   simulation deterministe (partagee pour les replays)
src/server/Services/                 services serveur
src/client/Controllers/              controleurs et UI
tests/unit/                          tests Lune (runner compatible TestEZ)
tests/playtest/                      protocoles de playtest humain
tickets/<status>/T-xxxx.md           tickets (format tickets/TEMPLATE.md)
docs/reviews/                        revues, audits, verdicts
docs/reports/                        rapports QA, perf, equilibrage, tendances, jalons
default.project.json                 projet Rojo
```

### 3.3 Format d'un ticket

Format impose par `tickets/TEMPLATE.md` (front matter `id`, `title`, `role`, `phase`, `status`, `type`, `priority`,
`depends_on`, `spec`, `acceptance`), verifie par `python3 tools/check_repo.py`. Les statuts sont `backlog`,
`in-progress`, `review`, `done`; le dossier reflete le statut. Un ticket = un role.

### 3.4 Protocole de passation
1. Le Producteur crée le ticket avec ses critères d'acceptation **avant** que le travail commence.
2. L'agent producteur livre ses fichiers, passe le statut à `en_revue` et écrit une note de livraison de 5 lignes au maximum dans le ticket.
3. Le validateur écrit `docs/reviews/T-xxxx.md` avec un verdict **VALIDÉ** ou **À CORRIGER**, accompagné d'une liste numérotée de corrections précises et vérifiables.
4. Après **3 itérations** sans validation, le ticket passe en `bloque` et le Producteur arbitre ou escalade à l'humain.
5. Un changement de règle de jeu passe **uniquement** par l'Agent 2. Il met à jour le GDD et la config, puis le Producteur crée les tickets d'impact.

### 3.5 Actions réservées à l'humain (`HUMAN_ACTION`)
- Création de l'expérience Roblox, du groupe, des clés API Open Cloud, des Game Passes et des Developer Products.
- Imports qui exigent Roblox Studio quand l'API ne les couvre pas.
- Validation juridique du roster (R6).
- Playtests avec de vrais joueurs à chaque jalon. **Aucun agent ne peut juger si le jeu est fun.**
- Décision de publication publique, prix en Robux, réponses aux signalements de modération.

---

## 4. PRINCIPES DE TRAVAIL COMMUNS À TOUS LES AGENTS

- Lire les sections de spec citées dans le ticket **avant** de produire.
- Ne jamais inventer un personnage ni ajouter un nom au roster en dehors du pipeline du §7.4 et §7.5. Le roster est versionne par lots dans `src/shared/Config/Roster.luau`; seul le Producteur le modifie, apres validation humaine. Les seuls noms inventes autorises concernent les competences, les objets, les arenes et les ecrans.
- Luau en `--!strict`, typé, testable. Pas de `wait()` déprécié, on utilise `task.*`.
- Chaque livrable est accompagné de **sa preuve** : sortie de test, capture d'écran, rendu, rapport de script de validation.
- En cas de doute sur une API Roblox ou Blender, l'agent vérifie la documentation officielle à jour plutôt que sa mémoire.
- La sortie la plus simple qui satisfait les critères est la meilleure. Pas de sur-ingénierie.

---

## 5. FICHES DES AGENTS (prompts système)

### AGENT 1 : PRODUCTEUR / ORCHESTRATEUR
```
Tu es le Producteur d'un studio de 10 agents IA qui développe un auto battler brainrot sur Roblox.
Ta source de vérité est le document /brief/. Tu ne produis ni code, ni art, ni design : tu organises,
tu arbitres et tu garantis que le jeu sort complet, cohérent et dans les règles.

TES RESPONSABILITÉS
1. Au M0, découper l'intégralité du brief en tickets (format §3.3) avec dépendances et critères
   d'acceptation mesurables. Viser des tickets de 1 à 4 heures de travail d'agent.
2. Ordonnancer : paralléliser ce qui est indépendant (ex. modélisation de 6 brainrots en lot pendant
   que le Dev Serveur code la simulation), sérialiser ce qui dépend d'un gate.
3. Faire respecter R1 à R10. Toute violation renvoie le ticket en "a_corriger".
4. Tenir /reports/etat.md à jour après chaque lot : % par jalon, tickets bloqués, risques, HUMAN_ACTION.
5. Arbitrer les conflits entre agents en citant le brief. Si le brief ne tranche pas,
   préférer l'option la plus simple qui protège les 4 piliers (§1.2), puis la consigner dans le GDD
   via l'Agent 2.
6. À chaque gate (§21), produire /reports/gate_Mx.md : critères, preuves, verdict, et la liste
   des choses que l'humain doit tester à la main.

TU NE PASSES JAMAIS UN GATE SANS : tests verts (Agent 9), validation DA (Agent 3) pour l'art,
rapport de perf sous budget, et accord explicite de l'humain pour M2, M4 et M6.

TU ESCALADES À L'HUMAIN : juridique, argent réel, publication, ou toute décision irréversible.
```

### AGENT 2 : GAME DESIGNER
```
Tu es le Game Designer. Tu possèdes les règles du jeu, les chiffres et l'histoire.
Tu écris pour être implémenté : chaque règle est univoque, chiffrée et testable.

TU PRODUIS
- /design/GDD.md : version vivante des sections 6 à 14 du brief, enrichie et corrigée.
- /src/shared/Config/*.lua : TOUTES les tables (raretés, niveaux, roster, stats, compétences,
  synergies, combos, économie du duel, œufs, récompenses, limites, arènes, histoire). Format de l'annexe A.
- /design/balance/*.csv : exports lisibles des tables.
- /design/story/chapitre_XX.md : scripts des 8 chapitres (dialogues courts, drôles, adaptés aux enfants).
- /reports/equilibrage_vN.md : analyses des simulations fournies par l'Agent 9 et décisions de tuning.

RÈGLES
- Tu respectes le système de raretés et de niveaux calqué sur Clash Royale (§7.1) : 5 raretés,
  niveaux de départ 1/3/6/9/11, niveau max 16, +10 % de stats par niveau.
- Roster versionne (§7.4). Tu peux ajuster les roles, stats et competences, jamais les noms. Tu proposes les fiches des nouveaux lots, l'humain les valide.
- Spec testable : "Le joueur reçoit son premier œuf en moins de 2 minutes", pas "rapidement".
- Tu ne valides jamais un équilibrage sans simulation : tu demandes à l'Agent 9 des runs headless
  (≥ 10 000 duels par configuration) et tu décides sur les chiffres.
- Cibles d'équilibrage : §19.3. Économie : un joueur gratuit actif 20 min/jour atteint l'Arène 4
  en 7 à 10 jours et l'Arène 8 en 6 à 10 semaines (à valider par simulation économique).

INTERDITS : dark patterns (R8), unités achetables uniquement en Robux, contenu non adapté aux enfants.
```

### AGENT 3 : DIRECTEUR ARTISTIQUE
```
Tu es le Directeur Artistique. Tu garantis que tout ce que voit le joueur forme un seul jeu :
cartoon, saturé, rond, juteux, lisible sur mobile, avec l'énergie colorée et addictive des écrans
d'ouverture de coffres de Clash Royale (inspiration, jamais copie).

TU PRODUIS
- /art/bible.md : bible de style complète à partir de §15 (palette hex, formes, proportions,
  matériaux, éclairage, contours, VFX, UI, typographie, règles de stylisation des brainrots).
- /art/refs/<slug>/ : 3 références canoniques par personnage (R10) + fiche de 5 lignes
  "traits signature à conserver" + "ce qu'on stylise".
- /art/prompts/ : gabarits de prompts pour l'Agent 7 (structure, style, palette, négatifs,
  format, taille, fond transparent ou non).
- /reviews/*.md : validations visuelles de chaque asset (3D, 2D, arènes, UI, VFX).

MÉTHODE DE VALIDATION (systématique)
1. Lisibilité : vignette 64×64 px → le personnage est-il reconnaissable ? Silhouette en noir pur :
   reconnaissable ?
2. Cohérence : l'asset posé à côté de 3 assets déjà validés appartient-il au même jeu ?
3. Traits signature : les 3 traits de la fiche sont-ils présents ?
4. Conformité : pas de logo de marque, pas de sexualisation, pas de gore, pas de ressemblance
   pixel-perfect avec un asset Supercell ou Riot.
Tu réponds VALIDÉ ou À CORRIGER avec des corrections précises ("yeux 20 % plus grands",
"saturation du vert −15 %"), jamais "fais mieux".
```

### AGENT 4 : DEV GAMEPLAY SERVEUR & ARCHITECTE (LUAU)
```
Tu es le développeur serveur et l'architecte technique. Tu possèdes la structure du projet,
la simulation de combat, l'économie, les données joueurs, le matchmaking et la sécurité.

TU PRODUIS (spécifications §16)
- Le dépôt Rojo, la structure §3.2, la CI (lint selene, format StyLua, tests).
- CombatSim : simulation déterministe (graine) qui prend deux formations et renvoie un journal
  d'événements (ActionLog). Exécutée côté serveur ; le client ne fait que rejouer le journal.
- DuelService : boutique, or, XP, étoiles, manches, PV, dégâts, fantômes.
- ProgressionService : collection, niveaux, cartes Joker, upgrades.
- EggService : couveuses, cycle d'œufs, éclosion, tirages, probabilités publiées.
- RewardService et LimitsService : récompenses, énergie, plafonds par heure et par jour.
- RankedService : trophées, arènes, ligues, saisons, classements.
- StoryService : chapitres, étoiles, énergie, boss.
- Données : ProfileStore (ou équivalent avec verrouillage de session), schéma versionné + migrations.
- Achats : ProcessReceipt idempotent, historique des reçus.
- Le moteur headless de simulation d'équilibrage pour l'Agent 9 (/tests/sim/).

RÈGLES
- R1 et R2 avant tout. Toute RemoteEvent est validée (types, bornes, état, fréquence).
- Temps : uniquement l'horloge serveur (os.time / DateTime en UTC). Jamais celle du client.
- Aléatoire : Random.new(graine) par combat et par tirage, graine journalisée pour rejouer
  et déboguer.
- Chaque service a des tests unitaires ; la simulation a un test de déterminisme
  (même graine → même journal, octet pour octet).
```

### AGENT 5 : DEV CLIENT & UI (LUAU)
```
Tu es le développeur client. Tu possèdes tout ce que le joueur voit et touche : menus, cartes,
boutique, collection, préparation de duel, affichage du combat, ouverture d'œufs, effets, caméra,
retours haptiques et sonores.

TU PRODUIS (spécifications §9, §10, §11, §13, §14, §15.6 à §15.8, §16)
- Navigation par onglets en bas (Boutique / Collection / COMBAT / Histoire / Classement),
  barre de ressources en haut.
- Écran de duel : boutique 5 emplacements, banc, plateau 2×4 en glisser-déposer, or, XP,
  minuteur, PV des deux joueurs, synergies actives à gauche.
- Lecteur de combat : rejoue l'ActionLog avec animations, timeline des tours, chiffres de dégâts,
  statuts, jauge Méga, bouton MÉGA COMBO, vitesse ×1/×2/×4 (×4 PvE seulement).
- Menu de combat manuel style Final Fantasy (Attaque / Compétence / Garde / Duo / Méga / Auto).
- Séquence d'ouverture d'œuf (storyboard §15.7), écran d'amélioration de carte, cinématiques
  de Méga Combos (lecture des animations et trajectoires caméra fournies par l'Agent 6).

RÈGLES
- Mobile d'abord : zones tactiles ≥ 44 px, lisible sur un écran de 6 pouces, testé en 16:9 et 20:9.
- Chaque bouton réagit en < 100 ms (animation de pression immédiate, même si le serveur répond
  plus tard). États de chargement explicites, jamais d'écran figé.
- Le "juice" est obligatoire : rebonds (Back/Elastic), particules, secousses d'écran
  dosées, sons, vibrations (HapticService) sur les moments clés.
- Le client ne calcule jamais un résultat de gameplay. Il affiche ce que le serveur a décidé.
- Pas de valeur en dur : textes via LocalizationTable (FR/EN), couleurs et tailles via un module de thème.
```

### AGENT 6 : TECHNICAL ARTIST 3D (BLENDER / BPY)
```
Tu es le Technical Artist 3D. Tu pilotes Blender exclusivement par scripts bpy reproductibles.
Tu produis les 42 personnages, leurs rigs, leurs animations, les cinématiques de Méga Combos et
le pipeline d'export vers Roblox.

TU PRODUIS (spécifications §15.2, §15.3, §17)
- /blender/scripts/ : génération procédurale de formes de base, application de la palette,
  contour (inverted hull), rigs gabarits, application d'animations, rendus de portraits,
  export FBX, et validate_asset.py (bloquant, R5).
- Pour chaque personnage : .blend source, FBX LOD0 + LOD1, jeu d'animations, portrait de carte
  rendu (fond transparent, 1024×1024), vignette de validation 64×64, rapport de validation.
- Pour chaque Méga Combo : animation multi-personnages + trajectoire caméra exportée en JSON.

RÈGLES
- Tu stylises les brainrots en cartoon low-poly, mais les traits signature (fiche DA) sont
  sacrés. Un Tralalero Tralala sans ses 3 pattes et ses baskets bleues est rejeté.
- Réutilisation maximale : 6 rigs gabarits (§17.3) partagés, animations de base communes,
  seules les animations signature sont uniques.
- Budgets (§16.6) vérifiés par script avant toute livraison.
- Tu commences par un test d'import complet (un cube riggé et animé → Roblox) au M0 pour verrouiller
  échelle, axes et réglages d'export avant de produire quoi que ce soit.
```

### AGENT 7 : ARTISTE 2D (GÉNÉRATION D'IMAGES)
```
Tu es l'Artiste 2D. Tu utilises les API de génération d'images pour produire tout l'art 2D :
UI, cadres de cartes, icônes, fonds, textures de palette, sprites d'effets, onomatopées,
bandes dessinées de l'histoire, emotes, icône et miniatures du jeu.

TU PRODUIS (spécifications §15, §18)
- Uniquement à partir des gabarits de /art/prompts/ (Agent 3). Tu notes pour chaque image : le
  prompt complet, la graine, le modèle, la taille et la date (fichier .json à côté de l'image).
- Les portraits de personnages ne sont PAS générés en 2D : ils sont rendus depuis Blender
  (Agent 6) pour garantir la cohérence avec la 3D. Tu fais les fonds, cadres et effets autour.
- Tu post-traites : détourage propre (alpha), recadrage, 9-slice (marges SliceCenter
  documentées), planches de sprites pour les effets (grilles compatibles avec le Flipbook des
  ParticleEmitter), compression, tailles en puissances de 2 et ≤ 1024.

RÈGLES
- Pas de texte généré par l'IA dans les images, sauf les onomatopées validées une par une par la DA
  (les textes d'interface sont des TextLabels localisés).
- Pas de logo, pas de marque, pas de style imitant un asset Supercell ou Riot existant.
- Lot de 4 variantes minimum par demande ; tu proposes la meilleure à la DA avec une raison.
```

### AGENT 8 : LEVEL DESIGNER / WORLD BUILDER
```
Tu es le Level Designer. Tu construis dans Blender (scripts bpy) puis dans Roblox les 8 arènes
cartoon, le lobby et les scènes de l'histoire.

TU PRODUIS (spécifications §15.5, §17.6)
- Un kit modulaire par arène (sols, bordures, props, décors de fond, éléments animés).
- Une scène d'arène assemblée : plateau de combat central (2 formations 2×4 face à face),
  décor en 3 plans (proche, moyen, silhouettes lointaines), éclairage, ambiance, 2 à 4 éléments
  animés (vagues, palmiers, hélices, anneaux de Saturne...).
- Le lobby (île de la Tentafruit) : petit, lisible, avec bornes vers les modes de jeu.
- Pour chaque arène : 3 positions de caméra validées (préparation, combat, victoire).

RÈGLES
- La lisibilité du combat prime sur la beauté du décor : rien de saturé ou d'animé derrière
  les unités ne doit gêner la lecture.
- Budgets (§16.6) : l'arène complète tient dans son budget de triangles et de mémoire sur mobile.
- Chaque arène doit être reconnaissable en une seconde sur sa vignette (couleur dominante + prop
  signature).
```

### AGENT 9 : QA / REVIEWER
```
Tu es le QA. Ton travail est de trouver ce qui casse avant les joueurs. Tu ne corriges pas :
tu prouves le problème, tu le documentes, tu renvoies le ticket.

TU PRODUIS (spécifications §19)
- Revues de code de chaque PR : sécurité (R1), données (R2), lisibilité, typage, tests.
- Suites de tests : unitaires, déterminisme de la simulation, économie, limites, achats.
- Simulations headless d'équilibrage (≥ 10 000 duels par lot) avec rapport chiffré.
- Simulation économique (progression de joueurs types sur 90 jours simulés).
- Vérification des probabilités affichées des œufs : 1 000 000 de tirages simulés par type d'œuf,
  écart avec les valeurs affichées < 0,1 point.
- Tests d'exploit : spam de remotes, valeurs négatives, placements invalides, achat sans or,
  double réclamation, manipulation de temps, déconnexion pendant un achat ou une ouverture d'œuf.
- Tests de perf sur profil mobile bas de gamme.
- Bots de playtest scriptés qui jouent des duels complets pour trouver des blocages.

FORMAT D'UN BUG : titre, gravité (bloquant/majeur/mineur), étapes de reproduction exactes,
résultat attendu, résultat obtenu, preuve (log, capture, graine de combat).
```

### AGENT 10 : ANALYSTE LIVE OPS
```
Tu es l'Analyste Live Ops. Tu rends le jeu mesurable dès le premier jour et tu transformes les
données en décisions.

TU PRODUIS (spécifications §20)
- Le plan de télémétrie : liste exhaustive des événements (nom, paramètres, moment de déclenchement),
  implémentée via AnalyticsService (entonnoirs, économie, progression, événements personnalisés).
- Les entonnoirs : FTUE pas à pas, première ouverture d'œuf, premier duel, premier Méga Combo,
  premier achat.
- Le tableau de bord des KPI (§1.4) et les alertes (chute de rétention, inflation d'or, unité
  sur-jouée).
- Le plan d'A/B tests au lancement : icône, miniatures, durée de la phase de préparation,
  récompense du premier jour.
- La feuille de route des 3 premières mises à jour (contenu, événements, saisons), argumentée par
  les données de playtest.

RÈGLES : chaque recommandation cite un chiffre. Pas d'opinion sans donnée.
```

---

## 6. BOUCLES DE JEU

### 6.1 Boucle d'un duel (7 à 10 minutes)
**Préparation** (acheter, vendre, placer, monter des étoiles, choisir les tactiques) → **Combat** au tour par tour, automatique avec interventions → **Résultat** (le perdant de la manche perd des PV) → manche suivante. La partie se termine quand un joueur tombe à 0 PV.

### 6.2 Boucle de session (15 minutes)
Jouer (duel ou histoire) → gagner un œuf, de l'or et des couronnes → **ouvrir l'œuf** → **améliorer** une carte (flèche verte) → ajuster son deck → rejouer.

### 6.3 Boucle méta (semaines)
Trophées → nouvelle arène → nouveaux brainrots débloqués → nouvelles synergies → nouveaux Méga Combos à découvrir (galerie à compléter) → Ligue Brainrot et saisons classées.

### 6.4 Boucle quotidienne
Œuf Couronne (10 couronnes par jour) + 3 quêtes du jour + énergie d'histoire qui se recharge + défi du jour + calendrier de connexion sur 7 jours.

---

## 7. CARTES, RARETÉS, NIVEAUX ET ROSTER

### 7.1 Système de raretés et de niveaux (repris de Clash Royale)

Chaque brainrot est une **carte**. Le joueur en possède des **exemplaires**. Une carte a une **rareté** fixe et un **niveau** qui monte avec des exemplaires et de l'or. Comme dans Clash Royale, la rareté fixe le **niveau de départ**, et c'est le **niveau** qui fixe la puissance. Une Légendaire débloquée commence directement au niveau 9.

| Rareté | Couleur du cadre | Niveau de départ | Niveau max | Coût en duel | Exemplaires dans le pool du duel | Limite par deck |
|---|---|---|---|---|---|---|
| Commune | gris-bleu | 1 | 16 | 1 or | 18 | : |
| Rare | orange | 3 | 16 | 2 or | 15 | : |
| Épique | violet | 6 | 16 | 3 or | 12 | : |
| Légendaire | arc-en-ciel animé | 9 | 16 | 4 or | 10 | : |
| Champion | or brillant | 11 | 16 | 5 or | 9 | **1 seul par deck** |

**Coût d'amélioration (exemplaires requis pour atteindre le niveau indiqué + or)** : calqué sur le barème Clash Royale de 2026. L'or ne dépend que du niveau visé, pas de la rareté :

| Niveau visé | Commune | Rare | Épique | Légendaire | Champion | Or |
|---|---|---|---|---|---|---|
| 2 | 2 | : | : | : | : | 5 |
| 3 | 4 | : | : | : | : | 20 |
| 4 | 10 | 2 | : | : | : | 50 |
| 5 | 20 | 4 | : | : | : | 150 |
| 6 | 50 | 10 | : | : | : | 400 |
| 7 | 100 | 20 | 2 | : | : | 1 000 |
| 8 | 200 | 50 | 4 | : | : | 2 000 |
| 9 | 400 | 100 | 10 | : | : | 4 000 |
| 10 | 800 | 200 | 20 | 2 | : | 8 000 |
| 11 | 1 000 | 300 | 30 | 4 | : | 20 000 |
| 12 | 1 500 | 400 | 50 | 6 | 2 | 25 000 |
| 13 | 2 500 | 550 | 70 | 9 | 5 | 40 000 |
| 14 | 3 500 | 750 | 100 | 12 | 8 | 60 000 |
| 15 | 5 500 | 1 000 | 130 | 14 | 11 | 90 000 |
| 16 | 7 500 | 1 400 | 180 | 20 | 15 | 120 000 |

> L'Agent 2 garde la **forme** de ce barème. Il peut appliquer un **diviseur global d'exemplaires** (`Config.Progression.CopyDivisor`, valeur initiale 1) si la simulation économique montre une progression trop lente pour Roblox. Il ne modifie jamais les niveaux de départ ni le +10 % par niveau.

**Formule de puissance (centrale, utilisée partout) :**
```
Stat(niveau) = Stat_ref × 1,10^(niveau − 11)
```
- `Stat_ref` est la stat au **niveau 11**, dit niveau tournoi. Elle est définie par classe et par rareté (§7.3).
- Exemples : une Commune niveau 1 a ×0,386 ; une Légendaire fraîchement débloquée niveau 9 a ×0,826 ; une carte niveau 16 a ×1,611.
- Les étoiles d'un duel se multiplient par-dessus (§10.4).
- **Modes à niveaux normalisés** (Duel Amical, Duel Rapide) : toutes les cartes sont ramenées au niveau 11. Le Classé et l'Histoire utilisent les **vrais niveaux**.

**Cartes Joker** (équivalent des Jokers de Clash Royale) : une par rareté. Un Joker remplace un exemplaire de n'importe quelle carte de sa rareté. On en obtient sur le Chemin des Trophées, dans le Pass et via les quêtes.

**Exemplaires en surplus** (carte niveau 16) : convertis automatiquement en or. Commune 5, Rare 50, Épique 500, Légendaire 10 000, Champion 20 000.

**Niveau de Coach** : chaque amélioration de carte rapporte de l'XP de compte (barème de l'Agent 2). Le niveau s'affiche sur le profil et dans l'écran de versus. Il ne donne aucun bonus de combat.

### 7.2 Roster de lancement : lot L0 (42 personnages)

Le lot L0 regroupe des personnages **existants** : les brainrots italiens les plus connus et les fruits de *L'Île de la Skibidi Tentafruit*. **Aucune modification de nom.** Les ajouts se font par lots (L1, L2...) selon §7.4 et §7.5, jamais dans ce tableau. Les apparences sont des résumés ; la référence canonique prime (R10). Les lignes marquées ⚠ ont une apparence à confirmer en priorité par la DA.

**Familles :** Mare, Cielo, Caffè, Giungla, Frutta, Macchina, Cosmo, Sahur, Tentafruit (sous-rôles : Couple, Tentation, Présentatrice).
**Classes :** Colosse, Guerrier, Assassin, Artilleur, Soigneur, Mage, Sprinteur.

#### Champions (5) : 1 par deck maximum, chacun a une **Aura de Champion**
| # | Nom | Arène | Familles | Classe | Apparence (traits signature) | Compétence signature | Aura de Champion |
|---|---|---|---|---|---|---|---|
| 1 | **Tralalero Tralala** | 1 | Mare | Sprinteur | Requin gris-bleu à 3 pattes, baskets bleues sans logo | *Sprint Tralala* : 3 charges sur des cibles aléatoires en ignorant la ligne avant ; chaque coup lui donne +10 VIT jusqu'à la fin du combat | Alliés +10 % VIT |
| 2 | **Tung Tung Tung Sahur** | 8 | Sahur | Guerrier | Bûche de bois anthropomorphe tenant une batte en bois | *Tung ! Tung ! Tung !* : 3 coups de batte sur la même cible, le 3e étourdit 1 tour | Ennemis −20 Énergie au début du combat |
| 3 | **Bombardiro Crocodilo** | 5 | Cielo, Macchina | Artilleur | Tête de crocodile sur un corps de bombardier bimoteur à hélices | *Tapis de bombes* : bombes cartoon sur toute une ligne ennemie (choisie en manuel ; la plus remplie en auto) | Alliés Cielo +15 % ATQ |
| 4 | **Ballerina Cappuccina** | 4 | Caffè | Mage | Ballerine en tutu rose et chaussons de pointe, tête = tasse de cappuccino | *Pirouette Cappuccino* : tourbillon qui étourdit la colonne ennemie en face 1 tour et soigne les alliés Caffè de 15 % de leurs PV max | Alliés +5 Énergie par tour |
| 5 | **Poirita** | 3 | Tentafruit (Présentatrice) | Mage | Poire présentatrice avec micro et fiches | *Cérémonie d'élimination* : l'ennemi à la plus haute ATQ ou MAG quitte le combat 2 tours, puis revient avec −20 % de stats | La synergie Tentafruit compte +1 unité |

> Pour les Champions, la colonne **Arène** indique leur arène thématique. Ils ne tombent des œufs qu'à partir de l'Arène 6 (Tung Tung Tung Sahur : Arène 8). Avant, on les obtient par le choix du chapitre 4 de l'Histoire et par l'Œuf Champion du Chemin des Trophées (§12.3).

#### Légendaires (7)
| # | Nom | Arène | Familles | Classe | Apparence | Compétence signature |
|---|---|---|---|---|---|---|
| 6 | **Cappuccino Assassino** | 4 | Caffè | Assassin | Tasse de café ninja, deux katanas, bandeau | *Espresso fatal* : se téléporte en ligne arrière et frappe la cible la plus faible (critique garanti) ; s'il met K.O., il devient Invisible 1 tour |
| 7 | **Brr Brr Patapim** | 6 | Giungla | Colosse | Créature-arbre de la forêt au visage de singe à long nez, grands pieds ⚠ | *Racines Patapim* : Provocation 2 tours + enracine la ligne avant ennemie (−50 % VIT) |
| 8 | **Lirilì Larilà** | 6 | Giungla, Cosmo | Mage | Éléphant au corps de cactus, en sandales, associé à une horloge | *Arrêt du temps* : repousse tous les ennemis de 30 % dans la timeline. Passif : ses épines renvoient 20 % des dégâts de mêlée |
| 9 | **La Vacca Saturno Saturnita** | 7 | Cosmo | Colosse | Vache dont le corps est la planète Saturne avec ses anneaux | *Anneaux de Saturne* : bouclier de 20 % de ses PV max à tous les alliés + gravité (ennemis −15 % VIT 2 tours) |
| 10 | **Bombombini Gusini** | 5 | Cielo | Sprinteur | Oie avec des ailes d'avion de chasse | *Piqué supersonique* : frappe la ligne arrière ; rejoue immédiatement en cas de critique (1 fois par tour) |
| 11 | **Girafa Celestre** | 7 | Cosmo, Frutta | Artilleur | Girafe au torse de pastèque, 3 pattes en bottes de cuir, casque d'astronaute | *Pluie de météores* : 5 météores sur des cibles aléatoires |
| 12 | **Cocofanto Elefanto** | 6 | Frutta, Giungla | Colosse | Bébé éléphant fusionné avec une noix de coco poilue | *Charge de coco* : charge la ligne avant, étourdit 1 cible, gagne un bouclier de 25 % de ses PV max |

#### Épiques (9)
| # | Nom | Arène | Familles | Classe | Apparence | Compétence signature |
|---|---|---|---|---|---|---|
| 13 | **Chimpanzini Bananini** | 2 | Frutta, Giungla | Guerrier | Chimpanzé qui sort d'une banane | *Peau de banane* : coup + la cible a 50 % de chances de perdre son prochain tour. Passif *Indestructible* : survit une fois par combat à un coup fatal avec 1 PV |
| 14 | **Espressona Signora** | 4 | Caffè | Soigneur | Dame-espresso, sœur de Ballerina Cappuccina ⚠ | *Shot d'espresso* : soigne l'allié le plus blessé de 30 % et avance son tour de 25 % dans la timeline |
| 15 | **Frigo Camelo** | 5 | Macchina | Colosse | Chameau-réfrigérateur en bottes | *Souffle glacé* : Ralenti sur la ligne avant ennemie 2 tours, +30 % DEF pour lui 2 tours |
| 16 | **Svinino Bombondino** | 5 | Macchina | Artilleur | Cochon-bombe | *Kaboom !* : explose (gros dégâts de zone), tombe K.O., puis se reconstitue à 30 % de PV 2 tours plus tard (1 fois par combat) |
| 17 | **Talpa di Ferro** | 5 | Macchina | Assassin | Taupe mécanique en fer avec foreuse | *Forage* : disparaît sous terre 1 tour (intouchable), puis ressort sous la ligne arrière avec un coup puissant |
| 18 | **Bombardiere Lucertola** | 5 | Cielo, Macchina | Artilleur | Lézard-avion bombardier ⚠ | *Raid éclair* : 3 petites bombes, chacune applique Brûlure |
| 19 | **Fraisita** | 3 | Tentafruit (Couple) | Mage | Fraise anthropomorphe ⚠ | *Confessionnal* : la cible devient Exposée (+25 % de dégâts reçus) pendant 2 tours |
| 20 | **Cerisa** | 3 | Tentafruit (Tentation) | Assassin | Cerise anthropomorphe ⚠ | *Clin d'œil* : Charme 1 tour (la cible attaque son propre camp) |
| 21 | **Citronello** | 3 | Tentafruit (Tentation) | Mage | Citron anthropomorphe ⚠ | *Acidité* : −30 % DEF et RES sur la ligne ciblée pendant 2 tours |

#### Rares (10)
| # | Nom | Arène | Familles | Classe | Apparence | Compétence signature |
|---|---|---|---|---|---|---|
| 22 | **Bobrito Bandito** | 2 | Giungla | Artilleur | Castor bandit, chapeau, mitraillette cartoon | *Rafale de bandit* : 6 tirs sur des cibles aléatoires (projectiles stylisés cartoon) |
| 23 | **Glorbo Fruttodrillo** | 1 | Mare, Frutta | Colosse | Crocodile fusionné avec un fruit ⚠ | *Mâchoire juteuse* : Provocation 1 tour + morsure avec 30 % de vol de vie |
| 24 | **Orangutini Ananasini** | 2 | Giungla, Frutta | Guerrier | Orang-outan dans un ananas | *Ananas piquant* : coup + gagne Épines (renvoie 15 %) 2 tours |
| 25 | **Tigrrullini Watermellini** | 2 | Frutta | Guerrier | Tigre-pastèque ⚠ | *Griffes juteuses* : 2 coups, chacun applique Saignement |
| 26 | **Bananita Dolfinita** | 1 | Mare, Frutta | Soigneur | Dauphin dans une banane | *Éclaboussure* : soigne toute une ligne alliée de 15 % |
| 27 | **Boneca Ambalabu** | 1 | Mare, Macchina | Colosse | Pneu de voiture surmonté d'une tête de ouaouaron, sur deux jambes humaines | *Rebond de pneu* : rebondit sur 3 ennemis + Provocation 1 tour |
| 28 | **Chef Crabracadabra** | 1 | Mare | Mage | Crabe chef cuisinier magicien ⚠ | *Recette magique* : la cible est Ralentie et Exposée 2 tours |
| 29 | **Fraisio** | 3 | Tentafruit (Couple) | Guerrier | Fraise anthropomorphe ⚠ | *Coup de cœur* : coup puissant, +25 % de dégâts si Fraisita est vivante dans son équipe |
| 30 | **Litchita** | 3 | Tentafruit (Tentation) | Mage | Litchi anthropomorphe ⚠ | *Parfum de litchi* : Endort 1 cible pendant 1 tour |
| 31 | **Pasteco** | 3 | Tentafruit (Tentation) | Colosse | Pastèque anthropomorphe ⚠ | *Videur de la villa* : Provocation 2 tours + bouclier de 20 % de ses PV max |

#### Communes (11) : deck de départ
| # | Nom | Arène | Familles | Classe | Apparence | Compétence signature |
|---|---|---|---|---|---|---|
| 32 | **Tim Cheese** | 0 | Giungla | Sprinteur | Petit personnage-fromage ⚠ | *Grignotage* : 2 attaques rapides |
| 33 | **Trippi Troppi** | 0 | Mare | Assassin | Chat au corps de crevette | *Bond de crevette* : saute en ligne arrière et frappe |
| 34 | **Burbaloni Luliloli** | 0 | Mare, Frutta | Soigneur | Capybara dans une noix de coco ⚠ | *Zen capybara* : retire les statuts négatifs d'un allié + petit soin |
| 35 | **Ta Ta Ta Ta Sahur** | 0 | Sahur | Mage | Variante Sahur ⚠ (référence obligatoire avant modélisation) | *Ta-ta-ta-ta !* : réveille les alliés Endormis ; 50 % de chances d'Endormir 1 ennemi 1 tour |
| 36 | **Banano** | 0 | Tentafruit (Couple) | Colosse | Banane anthropomorphe ⚠ | *Muscles de la villa* : Provocation 1 tour + bouclier léger |
| 37 | **Bananella** | 0 | Tentafruit (Couple) | Artilleur | Banane anthropomorphe ⚠ | *Lancer de peau* : dégâts + 25 % de chances de faire glisser la cible (perd son tour) |
| 38 | **Pomito** | 0 | Tentafruit (Couple) | Guerrier | Pomme anthropomorphe ⚠ | *Croque-pomme* : dégâts + se soigne de 50 % des dégâts infligés |
| 39 | **Pomita** | 0 | Tentafruit (Couple) | Soigneur | Pomme anthropomorphe ⚠ | *Compote réconfortante* : soin de 25 % sur l'allié le plus blessé |
| 40 | **Myrtilo** | 0 | Tentafruit (Couple) | Artilleur | Myrtille anthropomorphe ⚠ | *Grêle de myrtilles* : petits dégâts sur tous les ennemis |
| 41 | **Myrtila** | 0 | Tentafruit (Couple) | Soigneur | Myrtille anthropomorphe ⚠ | *Smoothie* : petit soin + 20 Énergie à un allié |
| 42 | **Kiwina** | 0 | Tentafruit (Tentation) | Sprinteur | Kiwi anthropomorphe ⚠ | *Kiwi express* : joue 2 fois à son premier tour |

**Couples officiels de la Tentafruit :** Fraisio + Fraisita, Banano + Bananella, Pomito + Pomita, Myrtilo + Myrtila.

**Interactions spéciales (tirées du lore, à afficher dans la fiche de la carte) :**
- **Fraisio craque pour Cerisa.** Si Cerisa est dans l'équipe adverse, son *Clin d'œil* sur Fraisio dure 2 tours. Si elle est dans la même équipe que lui, Fraisio gagne +20 % ATQ, et Fraisita (si présente) devient *Jalouse* : +20 % MAG, rouge de colère.
- **Le remplaçant.** Pasteco a été remplacé par Citronello dans la série. Si les deux sont dans la même équipe et que Pasteco est mis K.O., Citronello gagne +30 % à toutes ses stats.
- **Les sœurs.** Ballerina Cappuccina et Espressona Signora ensemble : +10 % de soins reçus pour les deux.
- **Les frères.** Bombardiro Crocodilo et Bombombini Gusini ensemble : +10 % VIT pour les deux.

### 7.3 Stats de référence (niveau 11, 1 étoile)

Gabarit par **classe**, multiplié ensuite par le **coefficient de rareté**. L'Agent 2 affine chaque unité de ±15 % maximum autour de ce gabarit, en fonction de sa compétence.

| Classe | PV | ATQ | MAG | DEF | RES | VIT | Portée | Coût de compétence |
|---|---|---|---|---|---|---|---|---|
| Colosse | 1 400 | 70 | 30 | 60 | 50 | 80 | Mêlée | 100 |
| Guerrier | 1 100 | 110 | 30 | 40 | 35 | 95 | Mêlée | 90 |
| Assassin | 800 | 140 | 30 | 25 | 25 | 120 | Mêlée (ignore la ligne avant) | 80 |
| Artilleur | 750 | 120 | 60 | 20 | 30 | 100 | Distance | 100 |
| Soigneur | 800 | 50 | 110 | 30 | 45 | 105 | Distance | 70 |
| Mage | 750 | 40 | 130 | 25 | 45 | 100 | Distance | 100 |
| Sprinteur | 850 | 100 | 30 | 30 | 30 | 140 | Mêlée | 80 |

Coefficient de rareté (puissance « par or » du duel, comme dans TFT) : Commune ×1,00, Rare ×1,10, Épique ×1,22, Légendaire ×1,36, Champion ×1,50.
Chance de critique de base : 10 % (Assassin 20 %). Multiplicateur de critique : ×1,5.

### 7.4 Roster extensible : lots et categories

Le roster n'est pas ferme. Il est **versionne par lots** dans `src/shared/Config/Roster.luau` (une entree par personnage, champ `lot`), et chaque lot a sa fiche dans `design/roster/`. Un personnage se retire en une modification de config et un echange d'asset (R2).

| Lot | Contenu | Categorie (`category`) | Etat |
|---|---|---|---|
| L0 | Les 42 personnages du §7.2 : 28 brainrots italiens mainstream + 14 fruits de la Tentafruit | `brainrot_it`, `tentafruit` | Fige le 2026-10-01, a valider par l'humain |
| L1 | Memes recents a forte audience, personnages a creer autour du phenomene (voir `design/roster/lot-L1-memes-recents.md`) | `meme_trend` | Shortlist proposee, en attente de validation humaine |
| L2+ | Un lot par saison de 28 jours (Ligue, §12.3), 4 a 8 personnages | `meme_trend` ou `brainrot_it` | Produit par le pipeline §7.5 |

Regles des lots :
1. **Synergie Tentafruit unique.** La famille Tentafruit (§8.1) reste la synergie signature du lot L0. Les lots suivants ne s'y ajoutent pas, sauf fruits reellement issus de la serie.
2. **Chaque lot apporte sa famille.** Un lot L1+ introduit au moins une famille de synergie (ex. famille `Viral`) et au moins un Mega Combo a 2 unites, pour que le nouveau contenu s'integre a la boucle de duel (pilier 2).
3. **Un meme = un personnage original inspire du phenomene.** On reprend l'idee et le nom tel qu'il circule (si le nom n'est pas une marque), jamais l'image, la video, l'audio, le logo ou le texte protege d'origine. Le cas type : "6 7" est un geste et un chiffre; le personnage BATTLEROT est une creature a deux visages qui balance les mains, pas une reproduction d'une personne reelle.
4. **Personnes reelles exclues.** Aucun personnage n'est base sur une personne reelle identifiable (enfants devenus memes, streamers, personnalites politiques, chanteurs). Les memes de ce type sont rejetes a l'etape 5 du §7.5.
5. **Validation en 4 signatures.** Un personnage entre dans la config seulement avec : fiche Game Designer (famille, classe, competence, stats dans ±15 % du gabarit), fiche DA (3 references, traits signature, note de moderation), avis QA (simulation d'equilibrage dans les cibles §19.3), accord ecrit de l'humain (ticket `HUMAN_ACTION`).
6. **Retrait sans casse.** Si un personnage doit etre retire (droit, moderation, tendance eteinte), ses cartes sont converties en Jokers de meme rarete et l'or depense est rembourse; le combo qu'il portait est remplace par un combo du meme lot.

### 7.5 Pipeline de tendances memes (Agent 10, lecture seule)

Objectif : savoir quels memes buzzent **en ce moment** pour proposer les lots L1+. Le pipeline ne touche jamais au jeu en production; il produit un rapport et une shortlist que des humains lisent.

1. **Collecte** de signaux publics avec `tools/trends/fetch_trends.py` : pages Wikipedia des categories "Internet memes introduced in <annee>" et leurs vues sur 30 jours (API Wikimedia, sans cle), templates populaires Imgflip (sans cle). Sources a cle (Reddit, YouTube, Giphy, TikTok, X, Google Trends) listees dans `public-apis/public-apis` : activees seulement si l'humain fournit une cle, jamais commitee.
2. **Agregation et deduplication** des noms (alias, graphies "6-7", "67", "six seven").
3. **Score de tendance** = vues 30 jours normalisees + presence multi-sources + recence (date d'apparition). Seuil de shortlist : top 25.
4. **Filtre contenu** : rejet de tout meme sexuel, violent reel, politique, religieux, haineux, drogue, ou lie a un fait divers ou a un deces.
5. **Filtre personnes reelles et marques** : rejet des memes qui sont une personne identifiable, un produit, une entreprise, une oeuvre protegee (film, jeu, serie) ou un logo.
6. **Rapport** `docs/reports/trends-<date>.md` : donnees brutes, scores, decisions de filtre, shortlist, avec la commande qui le regenere.
7. **Shortlist** vers le Game Designer et la DA : fiche de personnage original par meme retenu (§7.4 regle 3).
8. **Validation humaine** (ticket `HUMAN_ACTION`) avant toute entree dans `Roster.luau` et avant tout asset.
9. **Fraicheur** : un rapport par saison au minimum; un meme retenu doit avoir moins de 12 mois et une audience encore croissante ou stable sur 30 jours.

Interdits : appeler une API externe depuis le client Roblox; appeler une API de tendance depuis le serveur de jeu en temps reel; ajouter un personnage parce qu'une API le classe "trending"; stocker une cle d'API dans le depot.

---

## 8. SYNERGIES

Une synergie s'active quand le **nombre d'unités différentes** (les doublons ne comptent pas) d'une famille ou d'une classe sur le plateau atteint un palier. Le panneau de gauche de l'écran de duel affiche chaque synergie avec son compteur et ses paliers, colorés en bronze, argent, or puis prisme pour le dernier palier.

### 8.1 Familles
| Famille | Membres | Paliers | Effets |
|---|---|---|---|
| **Mare** | Tralalero Tralala, Trippi Troppi, Glorbo Fruttodrillo, Bananita Dolfinita, Boneca Ambalabu, Chef Crabracadabra, Burbaloni Luliloli | 2 / 4 / 6 | (2) Les alliés Mare régénèrent 3 % de leurs PV max au début de chacun de leurs tours. (4) 6 % + immunité à Brûlure. (6) *Raz-de-marée* : au début du combat, une vague inflige 12 % de leurs PV max à tous les ennemis et les Ralentit 1 tour. |
| **Cielo** | Bombardiro Crocodilo, Bombombini Gusini, Bombardiere Lucertola | 2 / 3 | (2) *Volants* : les alliés Cielo peuvent cibler la ligne arrière, et la mêlée ennemie ne peut pas les cibler tant qu'un allié non volant est en ligne avant. (3) *Escadrille* : toutes les 6 actions alliées, bombardement automatique de la ligne ennemie la plus remplie (60 % de l'ATQ moyenne des Cielo). |
| **Caffè** | Ballerina Cappuccina, Cappuccino Assassino, Espressona Signora | 2 / 3 | (2) Alliés Caffè +15 VIT. (3) *Double shot* : quand un allié Caffè met un ennemi K.O., il rejoue immédiatement (1 fois par tour). |
| **Giungla** | Brr Brr Patapim, Lirilì Larilà, Cocofanto Elefanto, Chimpanzini Bananini, Orangutini Ananasini, Bobrito Bandito, Tim Cheese | 2 / 4 / 6 | Bouclier en début de combat sur les alliés Giungla : (2) 10 % des PV max, (4) 20 %, (6) 35 % + *Repousse* : le premier allié Giungla mis K.O. revient à 30 % de PV (1 fois par combat). |
| **Frutta** | Girafa Celestre, Cocofanto Elefanto, Chimpanzini Bananini, Orangutini Ananasini, Tigrrullini Watermellini, Glorbo Fruttodrillo, Bananita Dolfinita, Burbaloni Luliloli | 2 / 4 / 6 | (2) Alliés Frutta +10 % ATQ et MAG. (4) +20 % et +15 % de soins reçus. (6) +35 % + *Macédoine* : chaque soin reçu par un allié Frutta soigne aussi l'allié le plus blessé à hauteur de 30 % du montant. |
| **Macchina** | Bombardiro Crocodilo, Frigo Camelo, Svinino Bombondino, Talpa di Ferro, Bombardiere Lucertola, Boneca Ambalabu | 2 / 4 | (2) Alliés Macchina +20 DEF et RES. (4) +40 + *Surchauffe* : quand une Macchina est mise K.O., elle explose et inflige 10 % de ses PV max aux ennemis de sa colonne. |
| **Cosmo** | La Vacca Saturno Saturnita, Girafa Celestre, Lirilì Larilà | 2 / 3 | (2) Au début du combat, l'ennemi le plus rapide recule de 20 % dans la timeline. (3) Tous les ennemis reculent de 20 % + alliés Cosmo +20 MAG. |
| **Sahur** | Tung Tung Tung Sahur, Ta Ta Ta Ta Sahur | 2 | *Réveil à l'aube* : au début du combat, 2 ennemis aléatoires sont Endormis 1 tour. |
| **Tentafruit** | Les 14 fruits | 2 / 4 / 6 | (2) *Caméras en direct* : alliés Tentafruit +15 % d'Énergie gagnée. (4) *Cérémonie* : toutes les 6 actions alliées, l'allié qui a infligé le plus de dégâts devient *Élu de la soirée* (+20 % à toutes ses stats pendant 2 tours). (6) *Prime time* : la Jauge Méga se remplit 50 % plus vite. |

**Sous-rôles de la Tentafruit**
| Sous-rôle | Membres | Paliers | Effets |
|---|---|---|---|
| **Couple** | Fraisio, Fraisita, Banano, Bananella, Pomito, Pomita, Myrtilo, Myrtila | Couples **complets** : 1 / 2 / 3 | (1) *Lien d'amour* : quand un partenaire subit des dégâts, l'autre gagne 10 Énergie ; l'action Duo est débloquée (§11.3). (2) Membres de couples +15 % PV. (3) *Couple de l'année* : la première action Duo de chaque couple ne coûte pas d'Énergie. |
| **Tentation** | Cerisa, Litchita, Kiwina, Pasteco, Citronello | 1 / 2 / 3 | Les attaques des Tentateurs et Tentatrices ont (1) 15 %, (2) 25 %, (3) 35 % de chances d'appliquer Charme 1 tour. Au palier 3, un ennemi Charmé subit aussi +20 % de dégâts. |
| **Présentatrice** | Poirita | : | Effet porté par son Aura de Champion. |

### 8.2 Classes
| Classe | Membres | Paliers | Effets |
|---|---|---|---|
| **Colosse** | Brr Brr Patapim, La Vacca Saturno Saturnita, Cocofanto Elefanto, Frigo Camelo, Glorbo Fruttodrillo, Boneca Ambalabu, Banano, Pasteco | 2 / 4 / 6 | (2) Colosses +20 % PV. (4) +40 % + tous les alliés +10 % PV. (6) +60 % + la première Provocation de chaque Colosse dure 1 tour de plus. |
| **Guerrier** | Tung Tung Tung Sahur, Chimpanzini Bananini, Orangutini Ananasini, Tigrrullini Watermellini, Fraisio, Pomito | 2 / 4 | (2) Guerriers : 10 % de vol de vie. (4) 20 % de vol de vie + 15 % ATQ. |
| **Assassin** | Cappuccino Assassino, Talpa di Ferro, Cerisa, Trippi Troppi | 2 / 3 | (2) Assassins +15 % de chances de critique et critiques à ×1,75. (3) +30 % + le premier coup de chaque Assassin est toujours critique. |
| **Artilleur** | Bombardiro Crocodilo, Girafa Celestre, Svinino Bombondino, Bombardiere Lucertola, Bobrito Bandito, Bananella, Myrtilo | 2 / 4 | (2) +15 % de dégâts de zone. (4) +30 % + les attaques de base touchent aussi une cible adjacente à 40 %. |
| **Soigneur** | Espressona Signora, Bananita Dolfinita, Burbaloni Luliloli, Pomita, Myrtila | 2 / 3 | (2) +20 % de soins. (3) +40 % + les soins en excès deviennent un bouclier. |
| **Mage** | Ballerina Cappuccina, Poirita, Lirilì Larilà, Chef Crabracadabra, Citronello, Litchita, Fraisita, Ta Ta Ta Ta Sahur | 2 / 4 | (2) Mages +20 MAG. (4) +40 MAG + compétences 15 % moins chères en Énergie. |
| **Sprinteur** | Tralalero Tralala, Bombombini Gusini, Tim Cheese, Kiwina | 2 / 3 | (2) Sprinteurs +20 VIT. (3) +35 VIT + 15 % de chances de rejouer après une attaque de base. |

> **Aide à la synergie (obligatoire, pilier 2)** : quand le joueur touche une carte de la boutique ou du banc, les synergies qu'elle ferait progresser s'illuminent dans le panneau. Le nombre d'unités manquantes pour le prochain palier s'affiche (« +1 pour Mare 4 ! »).

---

## 9. MÉGA COMBOS

### 9.1 La Jauge Méga
- Une jauge **par équipe**, de 0 à 100. Elle repart de 0 à chaque combat.
- +4 à chaque action d'un allié qui appartient à au moins une synergie active. +8 quand un allié est mis K.O. ×1,5 avec Tentafruit (6).
- Quand la jauge est pleine **et** que les membres d'un combo sont vivants et en jeu, le bouton **MÉGA COMBO** apparaît et pulse. S'il y a plusieurs combos possibles, un appui long ouvre le choix ; un appui simple lance le plus puissant.
- Chaque combo est utilisable **1 fois par combat**. La jauge retombe ensuite à 0.
- En PvP, le combo se déclenche automatiquement après 8 secondes sans action du joueur, pour éviter qu'un joueur absent soit pénalisé.

### 9.2 Liste des Méga Combos
Les combos marqués **MVP** sont obligatoires au jalon M3. Les autres arrivent au M3 si le budget le permet, sinon à la première mise à jour.

| ID | Nom | Condition (unités vivantes en jeu) | Effet | Brief d'animation (Agent 6) | MVP |
|---|---|---|---|---|---|
| C01 | **Trio Originale** | Tralalero Tralala + Tung Tung Tung Sahur + Bombardiro Crocodilo | 250 % de l'ATQ moyenne à tous les ennemis + Étourdit tous les ennemis 1 tour | Tralalero traverse l'arène en sprint et soulève le sable. Bombardiro passe en rase-mottes et lâche une bombe cartoon géante. Tung Tung Tung Sahur la renvoie d'un coup de batte, onomatopée « TUNG! ». Explosion arc-en-ciel. | ✅ |
| C02 | **Escadrille Bombardini** | Bombardiro Crocodilo + Bombombini Gusini | 180 % ATQ sur toute la ligne arrière + Brûlure. Si Bombardiere Lucertola est présent : un passage de plus (×1,3) | Vol en formation en V, looping, pluie de bombes à mèche | ✅ |
| C03 | **Coppia Caffè** | Ballerina Cappuccina + Cappuccino Assassino | Pirouette + 6 coups de katana sur l'ennemi le plus fort (300 % ATQ), puis les alliés Caffè rejouent | Duo dansé et combattu, éclaboussures de mousse de lait, éclairs de katana | |
| C04 | **Sorelle Caffè** | Ballerina Cappuccina + Espressona Signora | Soin de 40 % à toute l'équipe + VIT +20 pendant 3 tours | Les deux sœurs servent une tournée géante de cafés à l'équipe | |
| C05 | **Déclaration d'amour** | Un couple complet (Fraisio + Fraisita, Banano + Bananella, Pomito + Pomita ou Myrtilo + Myrtila) | Les deux partenaires gagnent un bouclier de 30 % et un soin de 25 %, puis frappent ensemble une cible (200 %) | Cœurs, feux d'artifice, pose finale propre à chaque couple (1 gabarit d'animation, 4 variantes de pose). Si Poirita est en jeu, elle commente au micro en arrière-plan. | ✅ |
| C06 | **Cérémonie de la villa** | Poirita + 2 unités Tentation | L'ennemi le plus fort quitte le combat 3 tours + Charme sur 2 ennemis pendant 1 tour | Feu de camp nocturne, Poirita lit ses fiches, clins d'œil comiques des tentateurs | |
| C07 | **Il Tempo si Ferma** | Lirilì Larilà + La Vacca Saturno Saturnita + Girafa Celestre | Le temps s'arrête : les alliés jouent 2 tours d'affilée sans que les ennemis agissent | Horloge géante, anneaux de Saturne qui figent l'écran en sépia, météores suspendus | ✅ |
| C08 | **Macedonia** | 3 unités Frutta + 2 unités Tentafruit | Soin de 30 % à toute l'équipe + 150 % MAG en zone sur tous les ennemis | Bol géant de salade de fruits qui tombe sur l'arène. C'est le combo qui fait le pont entre les deux univers. | |
| C09 | **Giungla Indistruttibile** | Chimpanzini Bananini + Brr Brr Patapim + Cocofanto Elefanto | 220 % ATQ sur la ligne avant ennemie + bouclier de 20 % pour toute l'équipe | Ruée dans la jungle, lianes, peaux de banane | |
| C10 | **Sahur all'alba** | Tung Tung Tung Sahur + Ta Ta Ta Ta Sahur | Tous les ennemis Endormis 1 tour + alliés +40 Énergie | Lever de soleil orange, rythmes de percussions, onomatopées « TUNG TUNG TUNG » et « TA TA TA TA » | ✅ |
| C11 | **Officina Kaboom** | Svinino Bombondino + Talpa di Ferro + Frigo Camelo | 200 % ATQ sur tous les ennemis + Ralenti 2 tours | Talpa creuse des tunnels, Svinino s'y glisse, Frigo gèle la sortie, explosions en chaîne | |
| C12 | **Festa al Mare** | Tralalero Tralala + Trippi Troppi + Bananita Dolfinita | 160 % ATQ sur tous les ennemis + soin de 20 % aux alliés Mare | Vague géante surfée par Tralalero | |
| C13 | **Triangle de la Tentafruit** | Fraisio + Fraisita + Cerisa | 250 % sur une cible ennemie, mais Fraisio est étourdi 1 tour (gag) | Drama télé-réalité comique : Fraisita jalouse, Cerisa fait un clin d'œil, Fraisio prend la gifle cartoon de la colère qui part sur l'ennemi | |

### 9.3 Règles des cinématiques
- Version complète de 4 à 6 secondes. Version PvP condensée de 2,5 secondes au maximum. La **toute première fois** qu'un compte voit un combo, la version complète est jouée, même en PvP : c'est un moment fort.
- Bandes noires cinéma, bannière au nom du combo (gros texte contouré, rebond), onomatopée, secousse d'écran, vibration.
- En PvE, on peut passer la cinématique après la première vue.
- **Galerie des Méga Combos** dans la Collection : les combos non découverts s'affichent en silhouette avec leur condition cachée (« ??? + ??? + Tung Tung Tung Sahur »). Les combos découverts peuvent être rejoués. C'est un objectif de collection.

---

## 10. LE DUEL (BOUCLE TFT)

### 10.1 Deck
- **10 cartes**, 1 Champion maximum. 3 decks sauvegardables.
- Le deck définit le **pool de la boutique** du joueur : chaque carte du deck y entre avec le nombre d'exemplaires de §7.1. Chaque joueur a son propre pool.

### 10.2 Déroulé
- Chaque joueur commence avec **100 PV**.
- Manches **1, 6 et 11** : PvE contre une troupe neutre. La manche 1 oppose trois Tim Cheese niveau 1, les suivantes sont plus fortes. Récompense : +3 or et 1 exemplaire gratuit d'une carte du deck.
- Les autres manches : PvP contre l'adversaire.
- Phase de préparation : 20 secondes aux manches 1 à 3, 30 secondes ensuite (valeurs en config, testées en A/B). Si les deux joueurs appuient sur « Prêt », le minuteur saute.

### 10.3 Économie du duel
| Élément | Valeur |
|---|---|
| Or de départ | 3 |
| Revenu de base (dès la manche 2) | 5 |
| Intérêts | +1 par tranche de 10 or possédée, max +5 |
| Séries (victoires ou défaites consécutives) | 2-3 : +1 ; 4 : +2 ; 5 et plus : +3 |
| Victoire de manche | +1 |
| Relancer la boutique | 2 or |
| Acheter 4 XP | 4 or |
| Vendre | 1★ = coût ; 2★ = 3 × coût − 1 ; 3★ = 9 × coût − 1 |

### 10.4 Étoiles
- 3 exemplaires identiques en 1★ fusionnent automatiquement en 2★ (×1,8 PV, ATQ et MAG). Trois 2★ donnent un 3★ (×3,24).
- La fusion marche depuis le banc et le plateau, avec une animation de fusion très « juicy ».
- Les 3★ de Légendaires et de Champions passent en **version dorée** avec un effet spécial permanent.

### 10.5 Niveau du joueur, plateau et boutique
- Niveau de départ 2. +2 XP automatiques par manche.
- XP pour passer au niveau suivant : 2→3 : 4 ; 3→4 : 6 ; 4→5 : 10 ; 5→6 : 20 ; 6→7 : 32 ; 7→8 : 48.
- Unités sur le plateau = niveau du joueur (max 8). Banc : 6 places.
- La boutique a 5 emplacements. Probabilités par coût selon le niveau :

| Niveau | 1 or | 2 or | 3 or | 4 or | 5 or |
|---|---|---|---|---|---|
| 2 | 100 % | 0 | 0 | 0 | 0 |
| 3 | 75 % | 25 % | 0 | 0 | 0 |
| 4 | 55 % | 30 % | 15 % | 0 | 0 |
| 5 | 45 % | 33 % | 20 % | 2 % | 0 |
| 6 | 30 % | 40 % | 25 % | 5 % | 0 |
| 7 | 19 % | 30 % | 35 % | 15 % | 1 % |
| 8 | 15 % | 20 % | 35 % | 25 % | 5 % |

Si le deck ne contient aucune carte du coût tiré, l'emplacement prend le coût disponible le plus proche en dessous.

### 10.6 Plateau
- **2 lignes × 4 colonnes** : ligne avant et ligne arrière, face à la formation adverse, comme dans un Final Fantasy vu de 3/4.
- Glisser-déposer entre banc et plateau. Les règles de ciblage (§11.4) rendent le placement stratégique.
- Chaque unité a un **préréglage tactique** (§11.7) qui se règle d'un tap : Agressif, Équilibré ou Prudent.

### 10.7 Dégâts au joueur et fin de partie
- Le perdant d'une manche perd : 2 + palier + somme des étoiles des unités ennemies survivantes. Le palier vaut ⌈manche ÷ 3⌉, plafonné à 5.
- En cas d'égalité (§11.10), les deux joueurs perdent la moitié de ce montant.
- La partie s'arrête quand un joueur atteint 0 PV. Durée visée : 8 à 11 manches. Un abandon compte comme une défaite.

### 10.8 Adversaires fantômes (anti-file d'attente vide)
- En Duel Rapide et en Classé, si aucun adversaire n'est trouvé en 15 secondes, le joueur affronte un **fantôme**. Un fantôme est la suite de plateaux réellement joués par un autre joueur de la même tranche de trophées (±100), enregistrée manche par manche et rejouée par le serveur.
- L'écran de versus affiche clairement **« Fantôme de <pseudo> »**. Le joueur fantôme ne gagne ni ne perd de trophées.

### 10.9 Emotes
8 emotes prédéfinies (stickers animés de brainrots, fournis par l'Agent 7), 5 secondes de recharge. Un bouton coupe les emotes de l'adversaire. Pas de texte libre.

---

## 11. COMBAT AU TOUR PAR TOUR (STYLE FINAL FANTASY)

### 11.1 Principe
Le combat se joue **au tour par tour sur une timeline**, comme dans Final Fantasy X. Il se déroule **automatiquement par défaut** (c'est un auto battler) et le joueur **intervient** : Méga Combo, ordre de focus, tactiques. En mode Histoire, un **mode manuel complet** permet de choisir chaque action.

### 11.2 Timeline
- Chaque unité a une jauge d'initiative. À chaque tick, la jauge augmente de sa VIT. À 1 000, l'unité agit et sa jauge repart à 0.
- La jauge de départ vaut 0 à 200 (tirage avec la graine du combat) + 2 × VIT. Égalités : la plus haute VIT joue d'abord, puis les camps alternent.
- L'interface affiche les **10 prochaines actions** avec les portraits en haut de l'écran. En mode manuel, survoler une action montre comment l'ordre changerait.

### 11.3 Actions
| Action | Effet | Énergie |
|---|---|---|
| **Attaque** | 100 % ATQ physique (Mages et Soigneurs : 80 % MAG magique) | +20 |
| **Compétence** | Compétence signature (§7.2) | Coûte son prix (§7.3) |
| **Garde** | −50 % de dégâts subis jusqu'à son prochain tour ; ce prochain tour arrive 30 % plus tôt | +30 |
| **Duo** | Disponible si un partenaire Duo est vivant (couple complet, frères, sœurs ou partenaire d'un combo à 2) et que les deux ont au moins 50 Énergie : attaque conjointe de 2 × 120 % sur une cible. Le partenaire ne perd pas son tour. | −50 chacun |
| **Méga Combo** | Action d'équipe (§9), insérée avant la prochaine action alliée | Jauge Méga |

Chaque unité commence le combat avec **20 Énergie** (maximum 100). Une unité gagne aussi +10 Énergie quand elle subit des dégâts (une fois par action ennemie).

### 11.4 Ciblage et formation
- **Mêlée** : ne peut viser que la ligne avant ennemie tant qu'elle contient une unité, puis la ligne arrière.
- **Distance** : n'importe quelle cible.
- **Assassins** et **Volants** (Cielo 2) : peuvent viser la ligne arrière.
- **Provocation** : force les attaques et compétences à cible unique de l'ennemi à viser la source.
- « En face » désigne la même colonne.

### 11.5 Formules
```
Dégâts  = Puissance × Stat_attaque × 100 / (100 + Stat_défense) × Variance[0,95-1,05] × Critique(×1,5) × Modificateurs
          (physique : ATQ contre DEF ; magique : MAG contre RES ; arrondi à l'entier, minimum 1)
Soins   = Puissance × MAG × (1 + bonus de soins)
```
Les modificateurs regroupent Exposé, Garde, synergies, auras et étoiles. Ils sont multiplicatifs et listés dans un ordre fixe documenté dans le code.

### 11.6 Statuts
| Statut | Effet | Remarque |
|---|---|---|
| Étourdi | Perd son prochain tour | Contrôle |
| Endormi | Perd ses tours ; se réveille s'il subit des dégâts | Contrôle |
| Charme | Attaque son propre camp pendant 1 tour | Contrôle |
| Hors-combat | Retiré du terrain (Poirita) | Contrôle ; les boss y sont immunisés |
| Ralenti | −30 % VIT | |
| Enraciné | −50 % VIT | |
| Brûlure | Perd 5 % de ses PV max par tour | |
| Saignement | Perd 4 % de ses PV max par tour, cumulable 3 fois | |
| Exposé | +25 % de dégâts subis | |
| Bouclier | Absorbe des dégâts | |
| Provocation | Attire les attaques à cible unique | |
| Invisible | Ne peut pas être ciblé | |
| Épines | Renvoie un pourcentage des dégâts de mêlée | |

**Anti-enchaînement :** après un contrôle, l'unité est immunisée aux contrôles pendant 1 tour. Les boss résistent à 50 % aux contrôles.

### 11.7 Tactiques automatiques (inspirées des Gambits de Final Fantasy XII)
- **Agressif** : compétence dès qu'elle est prête, vise l'ennemi le plus faible en PV, jamais de Garde.
- **Équilibré** (par défaut) : compétence dès qu'elle est prête. Exception : un Soigneur garde sa compétence tant qu'aucun allié n'est sous 70 % de PV. Garde si l'unité est sous 25 % de PV et qu'un Soigneur allié est vivant.
- **Prudent** : Garde sous 40 % de PV, soins prioritaires, compétences défensives prioritaires.
- Logique de classe par défaut : le Soigneur vise l'allié le plus blessé, l'Assassin la ligne arrière la plus faible, l'Artilleur la ligne la plus remplie, le Colosse protège la cible la plus attaquée.
- **Tactiques avancées** (Histoire, débloquées au chapitre 3) : éditeur de 4 règles « si… alors… » par unité.

### 11.8 Mode manuel (Histoire uniquement)
À chaque tour d'une unité alliée, un menu façon Final Fantasy s'ouvre : **Attaque / Compétence / Garde / Duo / Méga / Auto**. Le joueur choisit sa cible d'un tap. Il a 15 secondes, sinon la tactique automatique joue à sa place. Un bouton global bascule Auto/Manuel. Vitesse ×1, ×2 ou ×4.

### 11.9 Interventions en PvP
- Bouton **MÉGA COMBO** (§9.1).
- **Ordre de focus**, 1 fois par combat : un tap sur un ennemi et toutes les unités alliées le ciblent pendant 2 tours, quand les règles de ciblage le permettent.
- Vitesse fixe ×2. Chaque animation d'action dure 0,8 seconde au maximum. Un combat dure 20 à 35 secondes.

### 11.10 Limites de durée
Après 40 actions, **Mort subite** : dégâts +25 % cumulés à chaque action. À 60 actions, la manche est déclarée égale.

### 11.11 Résultat et journal
- Une équipe sans unité active perd. L'écran de fin affiche le MVP de la manche (dégâts, soins) et des étoiles tournent au-dessus des unités K.O.
- `CombatSim` produit un **ActionLog** : `{t, acteur, action, cibles, valeurs, statuts, jauges}`. Le client le rejoue. Le même journal sert aux replays (Duel Amical) et au débogage par graine.

---

## 12. MODES DE JEU

### 12.1 Mode Histoire (PvE)

**Prémisse.** Poirita, la présentatrice de *L'Île de la Skibidi Tentafruit*, découvre que des brainrots italiens ont débarqué sur l'île. Elle lance une saison spéciale : le joueur devient un **coach** qui recrute des brainrots et des fruits, puis affronte le champion de chaque zone. La finale a lieu à l'aube, au Village du Sahur.

**Format.** 8 chapitres de 10 niveaux.
- Niveaux 1 à 9 : **combats d'Escouade**. Le joueur choisit jusqu'à 6 unités de sa collection, les place en formation 2×4 et combat en auto ou en manuel. Les synergies s'appliquent.
- Niveau 5 de chaque chapitre : **duel court contre une IA** au format TFT (6 manches, 40 PV), qui entraîne au duel.
- Niveau 10 : **boss** à phases.

| Ch. | Arène | Boss | Mécanique du boss | Récompense de fin de chapitre |
|---|---|---|---|---|
| 1 | Plage de Tralalero | Tralalero Tralala | Sous 50 % de PV, *Sprint infini* : agit 2 fois par tour | Œuf Magique |
| 2 | Jungle Bananini | Chimpanzini Bananini | *Indestructible* ×3 : survit 3 fois avec 1 PV ; il faut l'Exposer pour briser ses protections | Œuf Magique |
| 3 | Villa de la Tentafruit | Poirita, entourée de Cerisa et Citronello | Une cérémonie toutes les 4 actions retire ton meilleur allié pendant 2 tours | Œuf Magique + **Tactiques avancées** débloquées |
| 4 | Piazza del Caffè | Cappuccino Assassino et Ballerina Cappuccina (duo) | Déclenchent *Coppia Caffè* à 30 % de PV | **Choix d'un Champion : Tralalero Tralala ou Ballerina Cappuccina** |
| 5 | Officina Bombardini | Bombardiro Crocodilo | Bombardements de ligne annoncés 1 tour à l'avance (il faut se mettre en Garde) | Œuf Épique |
| 6 | Forêt de Patapim | Brr Brr Patapim | 3 racines à détruire, sinon toute l'équipe reste Enracinée | Œuf Épique |
| 7 | Anneaux de Saturne | La Vacca Saturno Saturnita | La gravité inverse l'ordre de la timeline toutes les 5 actions | Œuf Épique |
| 8 | Village du Sahur | Tung Tung Tung Sahur (boss final) | À « l'heure du Sahur », toutes les 6 actions, triple frappe sur toute la ligne avant ; en phase 2 il appelle Ta Ta Ta Ta Sahur | Œuf Légendaire + titre « Coach de l'aube » |

- **Étoiles par niveau :** 1★ pour une victoire, 2★ avec au plus 1 allié K.O., 3★ sans aucun K.O. et sous une limite d'actions propre au niveau. 3★ sur tout un chapitre donne un Œuf Magique bonus (ch. 1 à 4) ou un Œuf Épique bonus (ch. 5 à 8).
- **Énergie :** 1 par niveau, 2 par boss. Un niveau déjà gagné peut être rejoué pour des récompenses réduites (or et quelques cartes).
- **Niveaux ennemis :** de 1-3 au chapitre 1 jusqu'à 10-12 au chapitre 8 (calibrage par l'Agent 2 via la simulation économique).
- **Mode Difficile :** débloqué après le chapitre 8. Ennemis +2 niveaux, récompenses ×1,5.
- **Défi du jour :** un combat avec un modificateur tournant (« Communes uniquement », « Que des Mare », « Tout le monde est Exposé »…). Récompense : un Œuf d'Or, une fois par jour.
- **Narration :** 2 à 4 cases de bande dessinée au début et à la fin de chaque chapitre (images de l'Agent 7, bulles en TextLabels localisés, pas de voix). Ton : télé-réalité et absurde italien, humour adapté aux enfants.

### 12.2 Mode Versus (simple)
- **Duel Amical** : entre amis, dans le même serveur ou sur invitation. Niveaux normalisés à 11. Pas de trophées ni de récompenses, hors progression des quêtes de type « joue un duel ». Replay disponible à la fin.
- **Duel Rapide** : matchmaking public, niveaux normalisés à 11, pas de trophées. Récompenses : 50 % de l'or du Classé et des couronnes. Soumis aux plafonds de §13.5.

### 12.3 Mode Classé
**Trophées** (comme dans Clash Royale)
- Gain en cas de victoire = borne[20 ; 40](30 + (trophées adverses − trophées du joueur) ÷ 12).
- Perte en cas de défaite = borne[20 ; 40](30 + (trophées du joueur − trophées adverses) ÷ 12).
- Matchmaking : ±100 trophées, élargi de 50 toutes les 5 secondes. On cherche aussi un niveau moyen de deck à ±1 quand c'est possible. Fantôme après 15 secondes (§10.8).

**Arènes**
| Arène | Nom | Seuil | Plancher (on ne retombe pas en dessous) |
|---|---|---|---|
| 1 | Plage de Tralalero | 0 | oui |
| 2 | Jungle Bananini | 300 | oui |
| 3 | Villa de la Tentafruit | 600 | oui |
| 4 | Piazza del Caffè | 1 000 | oui |
| 5 | Officina Bombardini | 1 400 | oui |
| 6 | Forêt de Patapim | 1 800 | non |
| 7 | Anneaux de Saturne | 2 300 | non |
| 8 | Village du Sahur | 3 000 | non |

**Chemin des Trophées** : une récompense tous les 50 à 100 trophées jusqu'à 3 000 (or, cartes, Jokers, œufs, gemmes, emotes, cadres). Le tableau détaillé est fait par l'Agent 2. Il inclut **un Œuf Champion à 2 300 trophées**.

**Ligue Brainrot** (à partir de 3 000 trophées)
- Saisons de 28 jours. Rangs : Bois, Bronze, Argent, Or, Platine, Diamant (3 divisions chacun), puis Maître et **Légende Brainrot**.
- Points de Ligue visibles. MMR caché (Elo ou Glicko-2) pour le matchmaking.
- Réinitialisation douce en fin de saison : retour au rang inférieur.
- Récompenses de saison selon le rang : œufs, cadre de carte de saison et titre. Le top 100 mondial reçoit une emote exclusive.

**Classements** : mondial (top 100, mis à jour toutes les 5 minutes) et amis.

---

## 13. ŒUFS, ÉCONOMIE, RÉCOMPENSES ET LIMITES

### 13.1 Monnaies et ressources
Or (monnaie courante), Gemmes (premium, à gagner ou à acheter), Énergie (Histoire), Couronnes (objectif quotidien, à ne pas confondre avec les ★ des unités ni les étoiles de l'Histoire), Trophées, Points de Ligue, Cartes Joker, XP de Coach.

### 13.2 Couveuses (l'équivalent des emplacements de coffres)
- **4 couveuses.** Une seule éclosion à la fois. Le Pass Brainrot permet de mettre l'œuf suivant en file d'attente.
- Une victoire en Classé donne un œuf **si une couveuse est libre**. Sinon, le message « Couveuses pleines ! » s'affiche et le joueur reçoit quand même son or.
- Accélérer une éclosion coûte 1 gemme par tranche de 10 minutes restantes (minimum 1).

### 13.3 Cycle d'œufs
Comme le cycle de coffres de Clash Royale : une séquence fixe de **240 œufs** tirée une fois par compte avec une graine. Elle contient 180 Argent, 52 Or, 4 Magiques, 2 Géants, 1 Épique et 1 Légendaire. La position du compte dans le cycle est sauvegardée.

### 13.4 Types d'œufs
Valeurs pour l'Arène 1. Le contenu est multiplié par (1 + 0,15 × (arène − 1)), arrondi.

| Œuf | Source | Éclosion | Cartes | Or | Garanties | Visuel |
|---|---|---|---|---|---|---|
| Œuf de Bois | Tutoriel | 5 s | 3 | 10 | : | Coquille en bois cartoon |
| Œuf d'Argent | Cycle | 3 h | 12 | 40-60 | : | Argenté, reflets bleus |
| Œuf d'Or | Cycle, défi du jour | 8 h | 36 | 130-170 | 1 Rare | Doré, brillant |
| Œuf Magique | Cycle, histoire | 12 h | 100 | 400-500 | 4 Rares + 2 Épiques | Violet étoilé, flotte et tourne |
| Œuf Géant | Cycle | 12 h | 250 | 900-1 100 | 25 Rares | Énorme, déborde de l'écran |
| Œuf Épique | Cycle, boutique | 12 h | 15 | 0 | 15 Épiques | Cristal violet |
| Œuf Légendaire | Cycle, histoire, ligue | 24 h | 1 | 0 | 1 Légendaire | Arc-en-ciel animé |
| Œuf Champion | Chemin des Trophées, ligue | 24 h | 1 | 0 | 1 Champion | Or massif avec couronne |
| Œuf Couronne | 10 couronnes par jour | Immédiat | 20 | 150 | 1 Rare ; 3 % de chances de Légendaire | Bleu royal, couronne en relief |
| Œuf d'Aventure | 1re victoire d'un niveau d'histoire | Immédiat (n'occupe pas de couveuse) | 10 | 60 | : | Vert feuillage |

**Probabilités par carte** (hors garanties) : Commune 76 %, Rare 20 %, Épique 3,6 %, Légendaire 0,35 %, Champion 0,05 %.
- Les Légendaires ne tombent qu'à partir de l'Arène 4, les Champions à partir de l'Arène 6 (Tung Tung Tung Sahur à partir de l'Arène 8). Avant cela, leur part est reportée sur la rareté inférieure disponible.
- Le tirage se fait parmi les cartes débloquées par l'arène du joueur. Une carte débloquée mais **jamais obtenue** a un poids ×2, pour accélérer la découverte.
- **Avant tout achat d'œuf, et dans l'info-bulle de chaque œuf, les probabilités exactes sont affichées** (R8). L'Agent 9 vérifie qu'elles correspondent au tirage réel.

### 13.5 Récompenses et limites (combats limités par heure et par jour)
| Source | Récompense | Limite |
|---|---|---|
| Victoire en Classé | 1 œuf (si couveuse libre) + 15 × arène en or + 1 à 3 couronnes + trophées | Or et œufs : **5 victoires récompensées par heure glissante, 20 par jour.** Au-delà, on joue toujours pour les trophées et les quêtes. |
| Victoire en Duel Rapide | 50 % de l'or du Classé + couronnes | Partage les plafonds du Classé |
| Histoire | Or + cartes + Œuf d'Aventure (1re victoire d'un niveau) | **Énergie : 10 max, +1 toutes les 12 minutes** (5 combats par heure). Boss = 2. Recharge en gemmes : 2 fois par jour maximum. |
| Défi du jour | Œuf d'Or | 1 par jour |
| Quêtes | Or, gemmes, Jokers | 3 par jour + 1 par semaine |
| Œuf Couronne | Voir §13.4 | 1 par jour |

- Couronnes d'une victoire en duel : 3 si le joueur termine avec au moins 50 PV, 2 s'il en a au moins 20, 1 sinon.
- Réinitialisation quotidienne à heure fixe UTC (configurable), avec un compte à rebours visible.
- **Compteurs honnêtes et visibles :** « Récompenses de duel : 3/5 cette heure : prochaine dans 18 min ». Jamais de limite cachée.
- Toutes ces valeurs sont dans `Config.Limits` (R2).

### 13.6 Boutique
- **Offres du jour :** 6 cartes à acheter en or, avec un prix qui augmente à chaque achat (Commune 10 or puis +10, Rare 100 puis +100, Épique 1 000 puis +1 000, Légendaire 40 000, une par jour, à partir de l'Arène 4).
- **Œufs en gemmes :** Magique, Géant, Épique, Légendaire. Probabilités affichées avant l'achat.
- **Packs de gemmes** (Developer Products).
- **Cosmétiques :** cadres de cartes, emotes, effets alternatifs d'ouverture d'œuf, bannières de profil.

### 13.7 Monétisation Roblox
- **Game Pass « Couveuse VIP »** : une 5e couveuse.
- **Pass Brainrot** (Developer Product par saison de 28 jours) : piste gratuite + piste premium (œufs, gemmes, Jokers, cosmétiques, file d'attente d'éclosion).
- **Pack de départ** (achat unique à prix réduit).
- **Principes :** aucune unité exclusive payante. Le Duel Amical et le Duel Rapide normalisent les niveaux. L'argent accélère la progression, il ne débloque pas de puissance inaccessible.
- Les prix en Robux sont une `HUMAN_ACTION`.

---

## 14. TUTORIEL, QUÊTES ET SOCIAL

### 14.1 Les 6 premières minutes (FTUE)
| Temps | Étape | Objectif |
|---|---|---|
| 0:00 | Arrivée sur la plage du lobby. Poirita accueille le joueur dans une bulle de BD (10 s, passable). | Ton et univers |
| 0:15 | Histoire 1-1 en **manuel guidé** : Banano, Bananella et Trippi Troppi contre deux Tim Cheese. Une main animée montre Attaque, puis Compétence. | Comprendre le tour par tour |
| 1:15 | Victoire → **Œuf de Bois** (5 s) → première ouverture guidée (« Touche ! Touche ! Touche ! ») | Premier œuf en moins de 2 minutes |
| 2:00 | Première amélioration : flèche verte, gros bouton, feu d'artifice | Comprendre les niveaux |
| 2:30 | Histoire 1-2 en **auto**, découverte du bouton Auto et de la vitesse | Comprendre l'auto battler |
| 3:30 | **Duel tutoriel** contre une IA (4 manches, 30 PV) : acheter, placer, fusionner 3 exemplaires en 2★, activer Tentafruit 2 et le couple Banano + Bananella. **Premier Méga Combo garanti** (*Déclaration d'amour*) à la manche 3. | Le moment « waouh » |
| 5:30 | Récompense : Œuf d'Argent immédiat + déblocage du Classé et de l'Arène 1 | Lancer la boucle |
| 6:00 | Quêtes du jour affichées, liberté totale | |

Chaque étape est une étape d'entonnoir analytique (§20).

### 14.2 Quêtes
3 quêtes par jour (par exemple : « Gagne 2 duels », « Déclenche 1 Méga Combo », « Améliore 1 carte », « Termine 3 niveaux d'histoire ») et 1 quête par semaine. Une relance gratuite par jour.

### 14.3 Calendrier de connexion
7 jours, avec un Œuf Magique au jour 7. Le calendrier avance à chaque connexion, **sans remise à zéro** si le joueur rate un jour.

### 14.4 Social (v1)
Amis Roblox listés, invitation en Duel Amical, replays, profil (deck favori, combos découverts, meilleure arène), classement entre amis. Les clans sont hors périmètre de la v1, mais le schéma de données les prévoit.

### 14.5 Accessibilité
- Les raretés se distinguent aussi par une **forme d'icône**, pas seulement par la couleur (daltonisme).
- Option de taille de texte.
- Option « réduire les secousses et les flashs ».

---

## 15. DIRECTION ARTISTIQUE (base de la bible de l'Agent 3)

### 15.1 Intention
**Cartoon saturé, rond, juteux, lisible.** On reprend l'énergie visuelle des jeux mobiles de Supercell (couleurs franches, interfaces épaisses, récompenses qui explosent à l'écran) **sans copier un seul asset**.
- Les mèmes d'origine sont des images IA semi-réalistes. On les **traduit en jouets cartoon** : formes simplifiées, traits signature exagérés de 20 à 30 %, couleurs plates, ombrage en 2 tons, contour foncé.
- Langage de formes : rondeurs pour l'amical, angles réservés aux armes, aux boss et aux accents agressifs.
- Pas de photoréalisme, pas de textures photo, pas de matériaux PBR réalistes.

### 15.2 Palette
| Usage | Hex |
|---|---|
| Bleu UI principal | `#2E7CF6` |
| Bleu UI foncé | `#1B3F8F` |
| Or / bouton principal | `#FFC93C` |
| Orange action | `#FF8A00` |
| Vert amélioration | `#3DDC5C` |
| Rouge alerte | `#FF4D4D` |
| Crème (fonds de panneaux) | `#FFF8E7` |
| Contour du texte | `#1A1A2E` |

| Famille | Accent | Rareté | Couleur | Forme d'icône |
|---|---|---|---|---|
| Mare | `#2EC4F1` | Commune | `#8FA6C1` | Rond |
| Cielo | `#8EC5FF` | Rare | `#F28C28` | Losange |
| Caffè | `#8B5A3C` | Épique | `#A44CF2` | Étoile |
| Giungla | `#3CB44B` | Légendaire | Dégradé arc-en-ciel animé | Hexagone |
| Frutta | `#FF5E7E` | Champion | `#FFC93C` + couronne | Couronne |
| Macchina | `#8A9AA9` | | | |
| Cosmo | `#6C3CE0` | | | |
| Sahur | `#FF9F43` | | | |
| Tentafruit | `#FF7AC6` | | | |

### 15.3 Personnages
- **Tailles à l'écran** (hauteur en studs) : Commune 4,5-5,5 ; Rare et Épique 5-6 ; Légendaire 6-7 ; Champion 7-8 ; boss ×2.
- **Lisibilité :** silhouette reconnaissable en noir pur, personnage reconnaissable en vignette de 64 px.
- **Ombrage :** couleurs de la palette partagée + dégradé vertical léger + contour foncé (inverted hull) teinté de la couleur de famille assombrie.
- **Tentafruit :** le fruit est le corps, avec des bras et jambes cartoon et des accessoires de télé-réalité adaptés aux enfants (lunettes de soleil, colliers de fleurs, t-shirts, shorts, micro et fiches pour Poirita). Les membres d'un même couple portent un **accessoire assorti** (bracelet, foulard), pour qu'on repère les couples d'un coup d'œil.
- **Version dorée 3★** (Légendaires et Champions) : variante de palette or et blanc + particules permanentes discrètes.
- Chaque personnage a une **pose signature** utilisée sur sa carte, à l'ouverture d'œuf et à la victoire.

### 15.4 Cartes
Portrait rendu depuis Blender (vue de 3/4, éclairage cartoon : principal, contre-jour, appoint), fond aux couleurs de la famille, **cadre de rareté**, coût en or en haut à gauche, icônes de familles et de classe en bas, barre « Niv. X », barre d'exemplaires (verte et pleine avec une flèche qui rebondit quand l'amélioration est possible), pastille « NOUVEAU » pour les cartes jamais consultées.

### 15.5 Arènes (Agent 8)
| # | Arène | Heure et lumière | Props signature | Éléments animés |
|---|---|---|---|---|
| 1 | Plage de Tralalero | Midi, soleil franc | Sable doré, eau turquoise, palmiers, sculpture géante d'une basket bleue (sans logo), bouées | Vagues, palmiers qui oscillent, mouettes |
| 2 | Jungle Bananini | Matin, rais de lumière | Régimes de bananes géants, lianes, ruines italiennes envahies de végétation | Cascade, lianes qui se balancent |
| 3 | Villa de la Tentafruit | Coucher de soleil | Villa de télé-réalité, piscine en forme de cœur, transats, projecteurs de plateau, feu de camp de cérémonie, guirlandes | Projecteurs qui balaient, flammes, reflets de piscine |
| 4 | Piazza del Caffè | Fin d'après-midi dorée | Place italienne cartoon, fontaine en forme de tasse, terrasses, machines à espresso géantes | Vapeur des machines, pigeons, auvents qui flottent |
| 5 | Officina Bombardini | Ciel clair et venteux | Base aérienne-atelier, hangars, piste, grues, bombes cartoon décoratives désamorcées | Hélices, manche à air, drapeaux |
| 6 | Forêt de Patapim | Crépuscule brumeux | Arbres anciens aux visages endormis, horloge prise dans un tronc, champignons lumineux | Lucioles, brume, aiguilles de l'horloge |
| 7 | Anneaux de Saturne | Espace, lumière violette | Plateforme flottante, Saturne géante en fond, astéroïdes | Anneaux qui tournent, astéroïdes en orbite lente, particules en apesanteur |
| 8 | Village du Sahur | Avant l'aube, du bleu-violet vers l'orange | Village cartoon sur pilotis, lanternes, grands tambours de bois | Le ciel s'éclaircit pendant le combat, lanternes qui vacillent |

- **Village du Sahur :** représentation respectueuse et festive d'un village à l'aube. Aucun symbole religieux, aucune moquerie culturelle.
- **Règle de composition :** plateau de combat central dégagé, décor en 3 plans, contraste plus faible et saturation −15 % derrière les unités pour garder le combat lisible.
- **Lobby :** l'Île de la Tentafruit (plage, villa, quai), avec des bornes vers Combat, Histoire et Classement.

### 15.6 Interface (inspiration Clash Royale, jamais copie)
- **Écran principal :** l'arène actuelle en diorama en fond, avec les brainrots du deck en animation idle. Énorme bouton jaune **COMBAT !** au centre. Les 4 couveuses au-dessus de la barre d'onglets. En haut : niveau de Coach, trophées, or et gemmes.
- **Typographies Roblox :** `LuckiestGuy` pour les titres et les chiffres, `FredokaOne` pour le texte courant, contour `UIStroke` de 2 à 4 px en `#1A1A2E` et ombre portée.
- **Boutons :** 9-slice avec biseau et ombre basse. À la pression, échelle 0,92 puis retour en *Back easing* sur 0,12 s.
- **Chiffres :** compteurs qui défilent quand une valeur change. Pastilles de notification rouges qui rebondissent.
- **Transitions :** glissements et rebonds de 0,2 à 0,35 s. Jamais de coupe sèche.

### 15.7 Ouverture d'œuf (storyboard obligatoire, le moment le plus important du jeu)
| Temps | Ce qui se passe |
|---|---|
| 0,0 s | L'écran s'assombrit. L'œuf (modèle 3D) tombe du ciel et rebondit sur un piédestal (« boing »), avec un nuage de poussière. |
| 0,6 s | Compteur « Cartes restantes : 36 » en haut. **Indice d'anticipation :** l'œuf luit selon la meilleure rareté qu'il contient (halo violet pour Épique, arc-en-ciel qui pulse et petite cloche pour Légendaire, rayons dorés et couronne fantôme pour Champion). |
| À chaque tap | L'œuf tremble, se fissure (3 états de fissures de plus en plus marqués), courte vibration. Une carte jaillit en tournoyant et se retourne. Une bulle « ×12 » éclate. La barre d'exemplaires se remplit, avec une flèche verte qui rebondit si l'amélioration devient possible. |
| Carte nouvelle | Bannière « NOUVEAU ! », feu d'artifice à la couleur de la rareté. **Le brainrot apparaît en 3D au-dessus de la carte et fait sa pose signature**, avec son onomatopée. |
| Légendaire ou Champion | Ralenti, flash blanc (désactivable), rayons, la musique bascule sur un stinger, secousse, confettis arc-en-ciel. Le nom s'écrit en grand, lettre par lettre. |
| Or | Pluie de pièces qui volent jusqu'au compteur d'or, qui défile. |
| Fin | Récapitulatif : grille des cartes obtenues triées par rareté, boutons « Améliorer » qui brillent. |

Un double tap accélère l'ouverture. Les cartes nouvelles et les raretés Légendaire et Champion sont **toujours** montrées en entier.

### 15.8 Effets et retours
- Coups, critiques (texte « CRIT! » qui saute), soins (feuilles ou mousse de lait selon la famille), icônes de statut au-dessus des têtes, K.O. (pouf d'étoiles), fusions 2★ et 3★ (étincelles qui convergent), amélioration de niveau (explosion de lumière).
- **Onomatopées en images** (Agent 7, validées une par une par la DA) : « TUNG! », « TRALALA! », « KABOOM! », « BRR BRR! », « PATAPIM! », « SPLASH! », « CRAC! », « DING! ».
- Chiffres de dégâts : blancs (normal), jaunes et plus gros (critique), verts (soin), bleus (bouclier).

### 15.9 Audio
- Musique entraînante : mandoline italienne, percussions, basses légères. Un thème par arène, plus des stingers (victoire, défaite, Légendaire, Méga Combo).
- Effets cartoon (pops, boings, whooshes, pièces).
- Sources : bibliothèque sous licence du Creator Store Roblox ou création commandée par l'humain. **Jamais d'audio TikTok d'origine.** Pas de voix dans la v1.

---

## 16. SPÉCIFICATIONS TECHNIQUES ROBLOX (Agents 4 et 5)

### 16.1 Outillage
- **Rojo** pour synchroniser `/src` avec Studio, **Wally** pour les paquets, **selene** pour le lint, **StyLua** pour le formatage.
- Tests : TestEZ ou Jest-Lua. La simulation de combat est un module Luau pur, sans dépendance aux instances Roblox, qui tourne aussi avec **Lune** (runtime Luau autonome) pour les simulations d'équilibrage en masse.
- Si un serveur MCP pour Roblox Studio est disponible, il sert aux opérations dans le moteur (inspection, tests en jeu, imports).

### 16.2 Architecture
- **Serveur (services)** : PlayerDataService, ProgressionService, EggService, ShopService, DuelService, MatchmakingService, RankedService, StoryService, RewardService, LimitsService, QuestService, PurchaseService, AnalyticsService (enveloppe), ModerationService.
- **Client (contrôleurs)** : NavigationController, CollectionController, DeckController, DuelPrepController, CombatPlayerController, EggOpeningController, StoryController, CameraController, AudioController, HapticsController, ThemeController.
- **Partagé** : `Config/*`, `Types`, `Combat/CombatSim`, `Combat/Formulas`, `Rng`, `Net` (schéma unique de toutes les remotes).
- **Réseau** : un seul module `Net` déclare chaque remote avec son schéma de paramètres. Chaque appel est validé (types, bornes, état du joueur, phase du duel) et limité en fréquence (par défaut 10 requêtes par seconde et par joueur, plus strict sur les achats).

### 16.3 Où se joue un duel
1. **Priorité 1 :** adversaire dans le même serveur, appariement instantané. Le duel tourne sur ce serveur, chaque client affiche l'arène **localement** (clonée depuis ReplicatedStorage, pas répliquée dans Workspace).
2. **Priorité 2 :** file globale via MemoryStoreService (par tranche de trophées), puis serveur de duel réservé (`ReserveServer` + téléportation des deux joueurs), retour au hub à la fin.
3. **Priorité 3 :** fantôme après 15 secondes (§10.8).

### 16.4 Données joueur
- **ProfileStore** (ou équivalent avec verrouillage de session) + autosauvegarde + sauvegarde à la déconnexion.
- Schéma versionné avec migrations testées :
```
Profile {
  version, createdAt,
  coach { xp, level },
  currencies { gold, gems, energy, energyUpdatedAt, crowns, crownsDay },
  cards { [slug] = { level, copies, seen } }, jokers { [rarete] = n },
  decks { [1..3] = { slugs[10] } }, activeDeck,
  eggs { slots[4|5], hatchingIndex, queue, cycleSeed, cycleIndex },
  ranked { trophies, bestTrophies, arena, trophyRoadClaimed[], league { season, rank, division, lp, mmr } },
  story { [chapitre] = { [niveau] = etoiles } }, storyHard {...},
  limits { pvpWinsTimestamps[], dailyPvpWins, dailyResetAt, gemRefillsToday },
  quests { daily[], weekly, rerollUsed }, calendar { day, lastClaim },
  combosDiscovered { [comboId] = true }, cosmetics {...}, settings {...},
  purchases { receipts { [receiptId] = timestamp } }, stats {...}
}
```
- Traiter les **demandes d'effacement de données** que Roblox transmet aux développeurs.

### 16.5 Achats
`ProcessReceipt` idempotent : on vérifie l'identifiant de reçu dans `purchases.receipts`, on accorde l'achat, on sauvegarde, puis seulement on renvoie `PurchaseGranted`. Possession des Game Passes vérifiée côté serveur et mise en cache.

### 16.6 Budgets de performance (vérifiés par scripts, R5)
| Élément | Budget |
|---|---|
| Personnage LOD0 (contour compris) | Commune ≤ 3 000 triangles ; Rare et Épique ≤ 4 500 ; Légendaire ≤ 6 000 ; Champion ≤ 7 500 ; boss ≤ 12 000 |
| LOD1 (boutique, banc, plans lointains) | ≤ 35 % du LOD0 |
| Os par rig | ≤ 40 |
| Matériaux par personnage | 1 (2 avec le contour) |
| Textures | Palette partagée 256×256 + 1 texture ≤ 512×512 par personnage (1 024 pour Champions et boss) |
| Arène complète | ≤ 80 000 triangles visibles, ≤ 30 textures uniques |
| Combat complet (16 unités + arène + effets) | ≥ 30 FPS stables sur l'appareil Android d'entrée de gamme de référence ; viser 60 FPS sur PC |
| Mémoire client | Cible indicative < 800 Mo, à confirmer au M1 par mesure réelle |
| Particules actives en combat | ≤ 40 émetteurs simultanés |
| ActionLog | ≤ 30 Ko par combat |
| Premier écran jouable | ≤ 15 s sur mobile (préchargement progressif) |

- **Contours :** inverted hull dans le mesh. Pas d'instances `Highlight` en masse, car leur nombre simultané est limité.
- **Pooling** des BillboardGui de dégâts et des émetteurs de particules.
- **Éclairage :** technologie choisie au M1 sur mesure de perf (ShadowMap ou Future), ColorCorrection avec saturation légèrement relevée, Bloom léger.

### 16.7 Sécurité (vérifiée par l'Agent 9)
Aucune confiance dans le client pour l'or, les PV, les placements, les tirages, le temps et les récompenses. Le serveur vérifie la phase du duel pour chaque action de préparation. Les achats sont refusés si l'or est insuffisant. Les récompenses ne sont réclamables qu'une fois (identifiant unique de récompense). Toute anomalie est journalisée.

### 16.8 Assets et localisation
- Upload via l'**API Open Cloud Assets** pour les types qu'elle prend en charge (modèles, images…). Ce qu'elle ne couvre pas (certaines animations, par exemple) passe par Studio, avec le serveur MCP de Studio si disponible, sinon en `HUMAN_ACTION`. `assets/manifest.json` fait la correspondance slug → assetId. Tous les uploads passent par la modération Roblox : prévoir les délais.
- LocalizationTable FR/EN pour tous les textes. Les noms des brainrots et des fruits ne se traduisent pas.

### 16.9 Rendu du combat
Unités = modèles riggés (MeshPart avec os) animés par `AnimationController` + `Animator`. Caméra scriptée (3 positions par arène + trajectoires des Méga Combos). Interface de combat en ScreenGui. Lecture de l'ActionLog avec une file d'événements cadencée par la vitesse choisie.

---

## 17. PIPELINE BLENDER (Agents 6 et 8)

### 17.1 Test d'import au M0 (avant toute production)
Un cube riggé à 2 os avec une animation de 30 images → export FBX → import dans Roblox. On vérifie l'échelle (hauteur en studs), les axes, le skinning et l'animation. Les réglages validés sont consignés dans `/blender/scripts/export_settings.md` et deviennent la référence unique.

### 17.2 Procédure pour chaque personnage
1. Lire la fiche DA et les 3 références canoniques.
2. Choisir le rig gabarit (§17.3).
3. Blockout procédural en bpy (primitives, métaballs converties en mesh, modificateurs), puis remaillage et décimation contrôlés, normales lissées. Le style est « low-poly lisse ».
4. UV : dépliage automatique, puis placement des îlots sur les cases de la **palette partagée 256×256**. Les détails (yeux, motifs, rayures) vont dans la texture propre au personnage.
5. Contour : duplication, Solidify avec normales inversées, matériau foncé, épaisseur de 1,5 à 3 % de la taille.
6. Rig : armature gabarit, poids automatiques, scripts de correction, planche de poses de test rendue pour la DA.
7. Animations : application du jeu partagé du gabarit et création des animations signature.
8. LOD1 par décimation à 35 %.
9. Rendus : portrait de carte 1 024×1 024 sur fond transparent, silhouette 64×64, turntable de 8 images pour la DA.
10. `validate_asset.py`, puis export FBX.

### 17.3 Les 6 rigs gabarits (affectation proposée, ajustable par l'Agent 6 avec accord de la DA)
| Gabarit | Personnages |
|---|---|
| R1 Bipède | Tung Tung Tung Sahur, Ta Ta Ta Ta Sahur, Ballerina Cappuccina, Cappuccino Assassino, Espressona Signora, Boneca Ambalabu, Poirita et tous les fruits de la Tentafruit |
| R2 Quadrupède | La Vacca Saturno Saturnita, Frigo Camelo, Cocofanto Elefanto, Lirilì Larilà, Tigrrullini Watermellini, Svinino Bombondino |
| R3 Tripède à queue | Tralalero Tralala, Girafa Celestre |
| R4 Volant | Bombardiro Crocodilo, Bombombini Gusini, Bombardiere Lucertola |
| R5 Créature basse | Trippi Troppi, Chef Crabracadabra, Talpa di Ferro, Glorbo Fruttodrillo, Bananita Dolfinita |
| R6 Primate et assimilés | Chimpanzini Bananini, Orangutini Ananasini, Brr Brr Patapim, Bobrito Bandito, Burbaloni Luliloli, Tim Cheese |

### 17.4 Jeu d'animations par personnage (30 images par seconde)
Idle (boucle 2 s), Idle sur le banc (plus calme), Entrée (1 s), Attaque (≤ 0,8 s), Compétence (≤ 1,2 s), Coup reçu (0,3 s), Garde (0,5 s), K.O. (pouf, 0,8 s), Victoire (boucle 2 s), Pose signature (1,5 s), Duo (gabarit partagé entre partenaires).

### 17.5 Cinématiques des Méga Combos
Scène Blender qui référence les .blend des personnages, caméra animée. Livrables :
- une animation FBX par personnage impliqué ;
- `camera_path.json` : position, rotation et FOV pour chaque image, dans l'espace local de l'arène ;
- `events.json` : image → effet visuel, son, onomatopée, secousse, vibration ;
- une version longue (4 à 6 s) et une version courte (≤ 2,5 s, par coupes) ;
- une jouabilité dans **n'importe quelle arène** (cadrage neutre, sans dépendre du décor).

### 17.6 Arènes et œufs
- **Arènes :** kit modulaire par scripts, assemblage depuis un `layout.json`, props répétés qui partagent le même mesh, collisions simplifiées (Box ou Hull, CanCollide désactivé sur le décor), export par groupes.
- **Œufs :** les 10 œufs sont des modèles 3D simples de l'Agent 6 (coquilles avec 3 états de fissures). Leurs icônes 2D sont des rendus de ces modèles.

### 17.7 `validate_asset.py` (bloquant)
Vérifie : nombre de triangles par LOD, nombre d'os, nombre de matériaux, tailles de textures, échelle (hauteur cible ±10 %), géométrie non-manifold, normales, chevauchement d'UV hors palette, nommage `BR_<slug>_<LOD>`, transformations appliquées, cadence des animations, durée maximale de chaque animation. Il écrit un rapport JSON. Un code de sortie non nul bloque la livraison.

---

## 18. PIPELINE D'IMAGES GÉNÉRÉES (Agents 3 et 7)

### 18.1 Inventaire
- Cadres de cartes (5 raretés), dos de carte.
- Icônes : 9 familles + 3 sous-rôles, 7 classes, 5 raretés (avec leur forme), 6 monnaies, 13 statuts, 6 actions de combat, 5 onglets.
- Boutons et panneaux 9-slice (6 couleurs × états normal, pressé, désactivé), rubans, bannières.
- Fonds : écran principal, 8 écrans de chargement, cases de BD de l'histoire (8 chapitres × 4 à 8 cases).
- Planches de sprites d'effets : étincelles, étoiles, fumée cartoon, explosion cartoon, feuilles, mousse de café, éclaboussures, cœurs, confettis, rayons.
- Onomatopées (§15.8), 8 emotes (à partir des rendus 3D, retouchées).
- Textures répétables des arènes (sable, eau, herbe, pavés, métal, bois) en 512×512.
- Icône du jeu 512×512 et 3 à 5 miniatures 1920×1080 pour l'A/B test.

### 18.2 Gabarit de prompt (rempli par la DA dans `/art/prompts/`)
```
[SUJET]        : <description précise de l'élément, sans nom de marque>
[STYLE]        : cartoon mobile game UI, thick rounded shapes, bold dark outline, saturated colors,
                 soft 2-tone shading, glossy highlights, playful, high readability at small size
[PALETTE]      : <hex de la bible>
[COMPOSITION]  : <centré / 9-slice avec marges de X px / planche N×M>
[FOND]         : transparent | <couleur unie>
[NÉGATIFS]     : no text, no letters, no logo, no watermark, no realistic photo, no gore,
                 no suggestive content, no existing game assets
[FORMAT]       : <taille en puissance de 2, ≤ 1024>
```

### 18.3 Post-traitement et livraison
Détourage propre, recadrage, marges 9-slice documentées (`SliceCenter`), planches de sprites en grilles compatibles avec le Flipbook des ParticleEmitter, compression, puissances de 2. Chaque image est livrée avec un `.json` à côté (prompt, graine, modèle, date, ticket).

### 18.4 Icône et miniatures
De gros visages de brainrots expressifs (Tralalero Tralala contre Tung Tung Tung Sahur, un œuf qui explose de lumière), un contraste fort, aucun petit texte, l'énergie d'une affiche de jeu mobile. Conformes aux règles Roblox (rien de trompeur sur le contenu du jeu).

---

## 19. QA, TESTS ET ÉQUILIBRAGE (Agent 9)

### 19.1 Tests unitaires obligatoires

Runner (decision T-0005) : fichiers `*.spec.luau` avec l'API `describe` / `it` / `expect` de TestEZ, executes par `lune run tests/run.luau` en CI (modules purs : Config, Combat, Progression, Eggs). Les tests qui ont besoin du moteur Roblox (DataStore, Remotes) tournent dans Studio avec TestEZ et sont marques `HUMAN_ACTION` tant qu'aucune machine Studio n'est branchee a la CI.
Formules de dégâts et de soins, montée de niveau (§7.1), comptage des synergies (les doublons ne comptent pas), probabilités de la boutique, fusions d'étoiles, économie du duel (intérêts, séries), dégâts au joueur, limites (fenêtre glissante d'une heure, plafond quotidien, réinitialisation), régénération de l'énergie (horloge serveur), cycle d'œufs, tirages, idempotence des achats, migrations de données.

### 19.2 Déterminisme
Même graine + mêmes formations = ActionLog identique, vérifié par un hash, sur 1 000 combats aléatoires. Le même test tourne dans Roblox et dans Lune.

### 19.3 Cibles d'équilibrage (simulations headless de 10 000 duels par lot, IA de duel heuristique qui achète vers des synergies)
| Mesure | Cible |
|---|---|
| Taux de victoire d'une composition type contre le reste du champ | ≤ 55 % |
| Taux de victoire au palier maximal de chaque synergie | entre 45 % et 58 % |
| Présence de chaque unité en fin de partie | entre 3 % et 25 % (Champions ≤ 35 %) |
| Part des Méga Combos dans les dégâts totaux | ≤ 20 % en moyenne |
| Duels avec au moins un Méga Combo | entre 60 % et 80 % |
| Durée moyenne d'un duel | 8 à 11 manches |
| Durée moyenne d'un combat (×2) | 20 à 35 s |
| Combats terminés en égalité (60 actions) | < 2 % |
| Effet d'un écart d'un niveau de carte en Classé | Mesuré et rapporté (environ 60 % de victoires attendu pour le deck de plus haut niveau, comme dans Clash Royale) |

### 19.4 Simulation économique (90 jours simulés)
5 profils : gratuit 10 min par jour, gratuit 30 min par jour, gratuit 90 min par jour, petit acheteur, gros acheteur. On mesure les trophées, l'arène, le niveau moyen du deck, les cartes débloquées, l'or et les gemmes. On compare aux cibles de l'Agent 2 et on détecte les **murs de progression** (plus de 5 jours sans progrès notable).

### 19.5 Probabilités des œufs
1 000 000 de tirages simulés par type d'œuf. L'écart avec les probabilités affichées doit rester inférieur à 0,1 point.

### 19.6 Tests d'exploit
Spam de remotes, valeurs négatives ou NaN, placements hors plateau, achat sans or, vente d'une unité qui n'existe pas, double réclamation d'une récompense, manipulation de l'heure, déconnexion pendant un achat, une ouverture d'œuf ou une téléportation, deux sessions simultanées sur le même compte.

### 19.7 Performance
MicroProfiler et Developer Console sur l'appareil de référence. Un rapport par arène : FPS (moyenne et 1 % les plus bas), mémoire, triangles, nombre de draw calls observés.

### 19.8 Bots de playtest
Deux bots jouent 500 duels complets en passant par les vraies remotes, sur un serveur de test. Résultat attendu : aucun blocage, aucun état incohérent, aucune erreur serveur.

### 19.9 Régressions
Chaque bug corrigé reçoit un test qui l'aurait détecté.

### 19.10 Critères de sortie
0 bug bloquant. 0 bug majeur sur l'économie, les achats ou les données. Au plus 10 bugs mineurs connus, documentés.

---

## 20. LIVE OPS ET ANALYTICS (Agent 10)

### 20.1 Événements à instrumenter
- **Entonnoir FTUE** : `session_start`, `tuto_fight1_start`, `tuto_fight1_win`, `egg_wood_opened`, `first_upgrade`, `tuto_duel_start`, `first_mega_combo`, `tuto_duel_end`, `ranked_unlocked`.
- **Économie** : chaque source et chaque dépense d'or et de gemmes (type d'objet, contexte).
- **Progression** : niveau d'histoire commencé, gagné ou perdu ; arène atteinte ; rang de ligue.
- **Personnalisés** : `duel_end` (manches, résultat, synergies finales, unités, combos utilisés, fantôme ou non), `combo_triggered`, `combo_discovered`, `egg_opened` (type, meilleure rareté), `card_upgraded`, `limit_reached` (type), `energy_empty`, `matchmaking_wait`, `purchase`.

### 20.2 Tableaux de bord et alertes
KPI de §1.4, entonnoir FTUE étape par étape, taux de présence et de victoire par unité et par synergie, inflation de l'or (stock moyen par arène), temps d'attente du matchmaking, part des duels contre fantômes. Alertes : chute de J1 de plus de 5 points, unité présente dans plus de 35 % des fins de partie, temps d'attente médian supérieur à 20 s.

### 20.3 A/B tests au lancement
Icône (3 variantes), miniature (3), durée de préparation (25 s contre 30 s), cadeau du jour 1 (Œuf Magique contre 200 gemmes). On utilise les outils d'expérimentation du Creator Hub quand ils existent, sinon une affectation par hash du UserId.

### 20.4 Feuille de route des 3 premières mises à jour (à confirmer par les données)
- **MAJ 1 (semaine 2)** : Méga Combos restants, équilibrage, défi du week-end.
- **MAJ 2 (semaine 5)** : nouvelle saison de Ligue et de Pass, événement à durée limitée « La Nuit du Sahur ».
- **MAJ 3 (semaine 9)** : clans ou mode 2v2, selon les données d'engagement social.
- Tout nouveau personnage doit être un brainrot ou un fruit **existant**, validé juridiquement (R6).

### 20.5 Rituel
Rapport hebdomadaire dans `docs/reports/liveops_semaine_N.md` : 3 constats chiffrés, 3 recommandations, 1 expérience à lancer.

---

## 21. JALONS ET GATES

| Jalon | Contenu | Gate (tout doit être vrai) |
|---|---|---|
| **P0 : Validation du brief** | Audit du prompt, corrections, roster L0 fige, decision du runner, tickets M0/M1, rapport de tendances v1 | L'humain valide ce document et le lot L0 |
| **M0 : Cadrage** | Dépôt + CI, tickets complets, GDD v1, config v1, bible v1, 42 dossiers de références canoniques, test d'import Blender → Roblox, gabarits de prompts | L'humain valide le GDD et la bible |
| **M1 : Greybox** | CombatSim déterministe, DuelService, préparation et lecteur de combat avec des formes colorées, 10 unités en greybox (stats + compétences), 4 synergies, 1 Méga Combo placeholder, première simulation d'équilibrage, mesure de perf de référence | Duel complet jouable de bout en bout contre l'IA et entre 2 joueurs ; tests verts ; **l'humain trouve la boucle fun en playtest** |
| **M2 : Vertical slice** | Arène 1 finale, les 11 Communes + les 4 Rares de l'Arène 1 + Tralalero Tralala en version finale, chapitre 1 de l'histoire, ouverture d'œuf finale, collection et amélioration, Duel Amical, Méga Combo C05 final, FTUE complète | FTUE ≤ 6 min ; ≥ 30 FPS sur mobile de référence ; validation DA ; **accord de l'humain** |
| **M3 : Contenu** | 42 personnages, 8 arènes, 8 chapitres, les 5 Méga Combos MVP (les 13 si possible), tous les œufs | Toutes les validations DA ; tous les budgets respectés ; simulation d'équilibrage dans les cibles de §19.3 |
| **M4 : Méta** | Classé (trophées, arènes, Chemin des Trophées, Ligue, saisons), matchmaking + fantômes, quêtes, calendrier, boutique, limites, Pass, achats en environnement de test, télémétrie complète | Simulation économique dans les cibles ; tests d'achats et d'exploits verts ; **accord de l'humain** |
| **M5 : Polish et QA** | Perf, localisation anglaise, accessibilité, polish du « juice », 500 duels de bots, corrections | Critères de §19.10 ; bêta fermée avec de vrais joueurs (`HUMAN_ACTION`) |
| **M6 : Lancement** | Publication (`HUMAN_ACTION`), tableaux de bord, A/B tests, feuille de route | 7 jours de données et rapport KPI ; **accord de l'humain** |


**Premier livrable jouable = M1** : un duel complet (2 joueurs ou joueur contre IA) avec 10 unites greybox, 4 synergies, 1 Mega Combo placeholder, dans une arene en Parts. Tout ce qui exige Roblox Studio (import FBX, publication, DataStore reel, test sur appareil) est `HUMAN_ACTION` : les agents preparent, l'humain execute et renvoie les captures.

---

## 22. LIVRABLES FINAUX

1. L'expérience Roblox publiée, ou prête à publier si l'humain n'a pas encore donné son accord.
2. Le dépôt complet : code, config, scripts Blender, sources `.blend`, images avec leurs `.json`, `manifest.json`.
3. Le GDD final, la bible finale, les rapports d'équilibrage, d'économie, de perf, de QA et d'analytics.
4. `docs/reports/final.md` : ce qui est fait, chaque écart avec ce brief et sa raison, les bugs connus, les `HUMAN_ACTION` restantes, les recommandations pour la suite.

---

## ANNEXE A : SQUELETTE DE CONFIGURATION (Luau)

```lua
--!strict
-- src/shared/Config/Rarities.lua
return {
	Commune    = { startLevel = 1,  duelCost = 1, poolCopies = 18, color = "#8FA6C1", icon = "circle",  deckLimit = nil, statCoef = 1.00 },
	Rare       = { startLevel = 3,  duelCost = 2, poolCopies = 15, color = "#F28C28", icon = "diamond", deckLimit = nil, statCoef = 1.10 },
	Epique     = { startLevel = 6,  duelCost = 3, poolCopies = 12, color = "#A44CF2", icon = "star",    deckLimit = nil, statCoef = 1.22 },
	Legendaire = { startLevel = 9,  duelCost = 4, poolCopies = 10, color = "RAINBOW", icon = "hexagon", deckLimit = nil, statCoef = 1.36 },
	Champion   = { startLevel = 11, duelCost = 5, poolCopies = 9,  color = "#FFC93C", icon = "crown",   deckLimit = 1,   statCoef = 1.50 },
}
```

```lua
--!strict
-- src/shared/Config/Progression.lua
return {
	MaxLevel = 16,
	StatGrowthPerLevel = 1.10,       -- Stat(niv) = Stat_ref * 1.10^(niv - 11)
	ReferenceLevel = 11,
	CopyDivisor = 1,                 -- seul levier autorisé sur le barème d'exemplaires
	GoldToReach = { [2]=5, [3]=20, [4]=50, [5]=150, [6]=400, [7]=1000, [8]=2000, [9]=4000,
		[10]=8000, [11]=20000, [12]=25000, [13]=40000, [14]=60000, [15]=90000, [16]=120000 },
	CopiesToReach = {
		Commune    = { [2]=2, [3]=4, [4]=10, [5]=20, [6]=50, [7]=100, [8]=200, [9]=400, [10]=800,
			[11]=1000, [12]=1500, [13]=2500, [14]=3500, [15]=5500, [16]=7500 },
		Rare       = { [4]=2, [5]=4, [6]=10, [7]=20, [8]=50, [9]=100, [10]=200, [11]=300,
			[12]=400, [13]=550, [14]=750, [15]=1000, [16]=1400 },
		Epique     = { [7]=2, [8]=4, [9]=10, [10]=20, [11]=30, [12]=50, [13]=70, [14]=100, [15]=130, [16]=180 },
		Legendaire = { [10]=2, [11]=4, [12]=6, [13]=9, [14]=12, [15]=14, [16]=20 },
		Champion   = { [12]=2, [13]=5, [14]=8, [15]=11, [16]=15 },
	},
	SurplusToGold = { Commune = 5, Rare = 50, Epique = 500, Legendaire = 10000, Champion = 20000 },
}
```

```lua
--!strict
-- src/shared/Config/Brainrots.lua (extrait : 2 entrées sur 42)
return {
	["tralalero-tralala"] = {
		name = "Tralalero Tralala",          -- jamais traduit
		rarity = "Champion",
		arena = 1,
		families = { "Mare" },
		class = "Sprinteur",
		rig = "R3",
		skill = "SprintTralala",
		aura = "VagueDeVitesse",
		statOverrides = { VIT = 1.10 },       -- ±15 % max autour du gabarit de classe
		duoPartners = {},
		comboIds = { "C01", "C12" },
		signatureTraits = { "requin", "3 pattes", "baskets bleues sans logo" },
	},
	["banano"] = {
		name = "Banano",
		rarity = "Commune",
		arena = 0,
		families = { "Tentafruit" },
		subRole = "Couple",
		class = "Colosse",
		rig = "R1",
		skill = "MusclesDeLaVilla",
		statOverrides = {},
		duoPartners = { "bananella" },
		comboIds = { "C05" },
		signatureTraits = { "banane anthropomorphe", "accessoire de couple assorti à Bananella" },
	},
}
```

```lua
--!strict
-- src/shared/Config/Limits.lua
return {
	DailyResetUtcHour = 0,
	Pvp = { RewardedWinsPerRollingHour = 5, RewardedWinsPerDay = 20 },
	Energy = { Max = 10, RegenMinutes = 12, StoryLevelCost = 1, BossCost = 2, GemRefillsPerDay = 2 },
	CrownEggPerDay = { CrownsRequired = 10, EggsPerDay = 1 },
	DailyChallenge = { PerDay = 1 },
	EggSlots = { Base = 4, WithVipPass = 5, SimultaneousHatching = 1 },
}
```

```lua
--!strict
-- src/shared/Config/Combos.lua (extrait)
return {
	C01 = {
		name = "Trio Originale",
		requires = { all = { "tralalero-tralala", "tung-tung-tung-sahur", "bombardiro-crocodilo" } },
		effect = { kind = "DamageAll", power = 2.5, stat = "ATQ_avg", status = { id = "Etourdi", turns = 1 } },
		cinematic = { long = "C01_long", short = "C01_short" },
		mvp = true,
	},
	C05 = {
		name = "Déclaration d'amour",
		requires = { anyPair = { {"fraisio","fraisita"}, {"banano","bananella"}, {"pomito","pomita"}, {"myrtilo","myrtila"} } },
		effect = { kind = "CoupleStrike", shield = 0.30, heal = 0.25, power = 2.0 },
		cinematic = { long = "C05_long", short = "C05_short", variantByPair = true },
		mvp = true,
	},
}
```

---

## ANNEXE B : PREMIÈRES ACTIONS DU PRODUCTEUR (à exécuter dès réception)

1. Lire ce document en entier et lister dans `docs/reports/questions_M0.md` chaque ambiguïté qu'il contient, avec la décision proposée.
2. Demander à l'Agent 4 de créer le dépôt (§3.2), la CI et le projet Rojo vide.
3. Demander à l'Agent 6 le test d'import Blender → Roblox (§17.1). **Rien d'autre en 3D tant qu'il n'est pas validé.**
4. Demander à l'Agent 3 les 42 dossiers de références canoniques, en commençant par les personnages marqués ⚠, puis la bible v1.
5. Demander à l'Agent 2 le GDD v1 et la config v1 complète (42 personnages, 13 combos, toutes les tables).
6. Demander à l'Agent 10 le plan de télémétrie v1, pour que les événements soient codés dès le M1.
7. Créer les tickets `HUMAN_ACTION` : création de l'expérience et des clés API, validation juridique du roster, choix de l'appareil Android de référence, recrutement de playtesteurs.
8. Découper M1 en tickets et lancer le travail en parallèle : simulation de combat (Agent 4), UI greybox (Agent 5), stats et compétences des 10 unités greybox (Agent 2), harnais de simulation (Agent 9).
9. Publier `docs/reports/etat.md` et attendre la validation du gate M0 par l'humain.

**Fin du brief. Le jeu doit donner envie d'ouvrir « juste un œuf de plus ». Chaque décision se juge à l'aune des 4 piliers.**