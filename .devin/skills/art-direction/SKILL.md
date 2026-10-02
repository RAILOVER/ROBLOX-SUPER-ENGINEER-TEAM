---
name: art-direction
description: Writing and enforcing a style bible for generated 3D and 2D assets, including a vision-model validation grid with thresholds. Use for style bible authoring, prompt templates, and asset verdicts.
sources: [original]
---

# Art direction for generated assets

## When to Load

`03-directeur-artistique` for bible writing and verdicts; `06` and `07` to anticipate what will be checked.

## Quick Reference

### A bible that a model can apply

Every section must end in something checkable: a hex list, a size in meters, a count, a yes/no question. Prose that cannot be turned into a question in the validation grid is removed.

| Section | Checkable form |
|---------|----------------|
| Palette | hex list + max saturation + "90 % of pixels within the palette" |
| Proportions | reference scale (R15 = 1.4 m = 5 studs), door 2.2 m, no detail under 5 cm |
| Detail level | bevel width range, max colors per asset, modeled vs textured list |
| Materials | roughness per family, metalness binary, no mirror reflections |
| Lighting | ClockTime, Brightness, Atmosphere.Density, max 2 post effects |
| UI | corner radius, border width, font, 44 px minimum touch target |
| Forbidden | explicit list (photo textures, pure black, text in textures) |

### Vision validation protocol

1. Inputs: the asset render (3/4 view, neutral light) and one already-accepted reference asset.
2. Ask the grid questions one at a time; record each answer against its threshold.
3. One failed criterion = `REFUSE: <criterion>` with the corrective action. Taste is not a criterion.
4. Write the verdict in the PR. If a case reveals a missing criterion, add it to the bible instead of granting an exception.

### Prompt templates

Lock everything except variables in angle brackets. Always include: style words from the bible, palette hex, "no text", output size. Require 4 generations and pick the one that passes the grid, not the prettiest.

### Pipeline fit

Stylized low-poly, modular kits, flat or lightly textured materials fit `bpy` generation. Organic characters, realistic foliage, cloth do not: characters use player avatars. Choose a direction the pipeline can sustain for 200 assets, not one hero shot.
