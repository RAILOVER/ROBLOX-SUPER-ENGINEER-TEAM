# PROCESS.md: phases et portes de validation

Le Producteur est le seul a changer de phase, et uniquement apres un playtest humain documente.

| Phase | Objectif | Entree | Sortie (porte) |
|-------|----------|--------|----------------|
| P0 preparation | former l'equipe, outiller le repo | ce repo | scripts verts, 10 ROLE.md, playbooks, skills, MCP documente |
| P1 greybox | prouver que la boucle est fun avec des cubes | GDD v0 + 3 specs testables | 5 testeurs humains, 60 % veulent rejouer, 0 asset final genere |
| P2 vertical slice | 1 zone finie a la qualite cible | bible de style v1, kit modulaire 1 | 45 fps sur telephone bas de gamme, assets 100 % valides par scripts |
| P3 alpha | contenu complet, economie branchee | specs economie, Game Passes/Dev Products | 0 exploit connu ouvert, DataStore session-lock teste, D1 mesure en test prive |
| P4 soft launch | lancement restreint, telemetrie | AnalyticsService instrumente, miniatures A/B | D1 >= 25 %, bounce < 30 %, plan de mise a jour 4 semaines |
| P5 live ops | mises a jour continues | tableau de bord 10 | 1 update / 2 semaines, A/B documentes |

## Regles de phase

### P1 greybox
- Geometrie: Parts Roblox et couleurs plates. Aucun MeshPart importe, aucune texture.
- UI: rectangles et texte systeme. Pas d'icones.
- Les specs doivent etre mesurables en playtest: "premiere recompense en moins de 30 s" se mesure avec un
  evenement Funnel `onboarding` etape 1 et un chronometre, pas avec une opinion.
- Fin de phase: 5 testeurs humains minimum, formulaire 5 questions, enregistrement des sessions. Le
  Producteur consigne les reponses dans `docs/reviews/P1-<date>.md`.

### P2 vertical slice
- Le Directeur artistique livre la bible de style AVANT le premier asset.
- Chaque mesh passe `validate_mesh.py`, chaque texture `check_textures.py`, puis revue vision du DA.
- Le QA mesure sur appareil bas de gamme (ou emulation Studio: Device Emulator + qualite 1) et publie les chiffres.

### P3 alpha
- Audit securite complet (QA) a partir de la checklist `agents/09-qa-reviewer/checklists/securite.md`.
- Tous les remotes utilisent `src/server/Remotes/RemoteGuard.luau` ou un equivalent revu.
- Sauvegarde: session locking (ProfileStore ou equivalent), `BindToClose`, test de double connexion.

### P4 soft launch
- Mode Beta Roblox tant que les metriques ne sont pas stables.
- Analyste live ops: tableau D1/D7, funnel onboarding, sources/sinks par monnaie.
- Miniature: 2 variantes minimum en A/B des le premier jour.

### P5 live ops
- Chaque update a une hypothese ecrite: "si X change, Y bouge sans degrader Z".
- Le Game designer recoit les propositions de l'Analyste sous forme de tickets, pas de conversation.

## Definition of Done universelle

Un ticket est `done` quand:
1. tous ses `acceptance:` sont coches avec une preuve (sortie de script, test, capture, lien);
2. `check_repo.py` et les scripts concernes renvoient 0;
3. la PR est revue par le QA (code) ou le DA (visuel) selon le type;
4. ce qui n'a pas ete verifie est ecrit noir sur blanc dans la PR.
