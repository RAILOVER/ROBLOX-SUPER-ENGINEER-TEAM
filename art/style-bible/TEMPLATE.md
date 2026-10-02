# Bible de style: <Nom du jeu>  (v0.x)

Document de reference du Directeur artistique. Tout asset est compare a cette bible par un modele de
vision AVANT d'etre accepte. Les contraintes chiffrees sont dans `art/budgets/budgets.yaml`.

## 1. Direction en une phrase

Ex: "low-poly stylise, formes rondes, 3 couleurs dominantes, lumiere chaude de fin de journee".

## 2. Palette

| Role | Hex | Usage | Interdit pour |
|------|-----|-------|---------------|
| Primaire | #xxxxxx | | |
| Secondaire | #xxxxxx | | |
| Accent | #xxxxxx | elements interactifs | decor |
| Neutre clair / fonce | | | |

Saturation max, contraste min (texte UI: 4.5:1).

## 3. Formes et proportions

- Echelle de reference: avatar R15 = 5 studs = 1.4 m. Porte = 2.2 m. Caisse = 1 m.
- Silhouettes lisibles a 30 m. Pas de detail < 5 cm.
- Angles: biseau de 2 a 5 cm sur toutes les aretes visibles. Pas d'arete vive.

## 4. Niveau de detail

Ce qui est modelise vs ce qui est texture. Nombre de couleurs par asset. Usage du bruit.

## 5. Materiaux

Roughness par famille (bois 0.7, metal 0.3), metalness binaire, pas de reflets miroir.

## 6. Lumiere et ambiance

ClockTime, Brightness, Atmosphere.Density, palette de brouillard, 2 effets post max.

## 7. UI

Rayon des coins, epaisseur des bordures, police, taille minimale tactile (44 px), iconographie.

## 8. References

5 a 10 images de reference avec ce qu'on retient de chacune. Aucune reference d'un style qu'on ne vise pas.

## 9. Interdits

Liste explicite (ex: textures photo, gradients lourds, noir pur, texte dans les textures).

## 10. Grille de validation vision (utilisee par le DA)

| Critere | Question posee au modele de vision | Seuil |
|---------|------------------------------------|-------|
| Palette | Les couleurs dominantes sont-elles dans la palette ? | 90 % des pixels |
| Proportions | L'echelle correspond-elle a la reference ? | oui/non |
| Detail | Y a-t-il du detail < 5 cm ? | non |
| Coherence | Cet asset serait-il a sa place a cote de <asset de reference> ? | oui |
