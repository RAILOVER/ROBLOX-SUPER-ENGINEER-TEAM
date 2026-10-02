# Templates de prompts (Artiste 2D)

Chaque template est verrouille par le Directeur artistique. L'Artiste 2D ne modifie que les variables
entre chevrons. Le resultat est juge par la grille de validation de la bible de style.

## Texture PBR tilable

```
<sujet, ex: planches de bois peintes> texture seamless tilable, vue du dessus orthographique,
style low-poly stylise, palette <#hex1 #hex2 #hex3>, pas de texte, pas d'ombre portee,
eclairage neutre, 1024x1024
```
Post-traitement obligatoire: verification du tiling (offset 50 %), generation des maps Normal,
Roughness, Metalness, nommage `T_<Nom>_<Map>.png`, puis `python3 tools/check_textures.py`.

## Icone d'objet

```
icone de <objet>, style <bible>, fond transparent, centree, marge 10 %, silhouette lisible a 64 px,
palette <hex>, pas de texte, 512x512
```

## Miniature du jeu (1920x1080)

```
scene de <moment fort du jeu>, 1 personnage Roblox R15 en action au premier plan, regard camera,
<2 elements du jeu reconnaissables>, couleurs saturees de la palette <hex>, contraste eleve,
zone libre de 25 % a droite pour le titre, pas de texte
```
Regle: 2 variantes minimum, A/B via la page du jeu, lecture du CTR par 10-analyste-liveops.

## Icone du jeu (512x512)

```
icone carree, 1 element iconique du jeu, lisible a 64 px, palette <hex>, fond uni, pas de texte
```
