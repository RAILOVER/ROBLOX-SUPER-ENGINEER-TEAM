# Guide humain : ouvrir BATTLEROT M1 dans Roblox Studio

Les agents n'ont pas Roblox Studio. Voici les 6 etapes a faire sur ton ordinateur (Windows ou macOS), dans l'ordre.
Compter 30 minutes. Tout est deja code ; tu ne modifies rien.

## 1. Installer les 2 outils

- Roblox Studio : https://create.roblox.com/ (bouton "Start Creating").
- Rojo 7.7.0 (synchronise le code du depot vers Studio) : https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0
  Telecharge le zip de ton systeme, place `rojo` (ou `rojo.exe`) dans un dossier de ton PATH.
  Puis dans Studio : onglet Plugins > Manage Plugins > installe "Rojo" (par evaera / LPGhatguy).

## 2. Recuperer le code

```bash
git clone https://github.com/RAILOVER/ROBLOX-SUPER-ENGINEER-TEAM.git
cd ROBLOX-SUPER-ENGINEER-TEAM
git checkout devin/1790906273-battlerot-brief-m0
```

Si la PR 2 est deja fusionnee, `git checkout main` suffit.

## 3. Creer l'experience (ticket T-0019)

Dans Studio : New > Baseplate. File > Save to Roblox As... > nom `BATTLEROT`, prive. Note l'identifiant (URL) dans
`tickets/backlog/T-0019-human-studio-experience.md`.

## 4. Brancher Rojo

Dans le terminal, depuis le dossier du depot :

```bash
rojo serve default.project.json
```

Dans Studio : bouton Rojo > Connect. Verifie dans l'Explorer que `ReplicatedStorage > Shared > Config` et
`ServerScriptService > Server` existent. Supprime la Baseplate d'origine si elle gene (l'arene est construite au Play).

## 5. Jouer

Appuie sur Play (F5). Attendu : l'arene en cubes apparait, le HUD "Connexion au duel..." puis un bot entre en moins
de 5 s, manche 1, timer 20 s, boutique de 5 cartes a 1 or. Deroule ensuite les 32 etapes du ticket
`tickets/backlog/T-0031-human-playtest-m1-studio.md` (tableaux A, B, C) et note ce que tu observes.

Pour emuler un telephone : onglet Test > Device > choisis un iPhone ou un Android en paysage.

## 6. Renvoyer les resultats

Colle dans le ticket T-0031 (section Resultats) : les lignes cochees, les ecarts, 3 captures, la duree chronometree
de 3 combats, et le contenu de la fenetre Output (View > Output) s'il y a du rouge. Puis dis a l'equipe "T-0031
fait" : le Producteur ouvre les tickets de correction et decide du passage en M2.
