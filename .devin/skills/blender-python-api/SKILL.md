---
name: blender-python-api
description: Running bpy headless (blender -b), passing arguments, verified Blender 5.x API differences, and the repo's mesh gate. Use for any Blender script in tools/blender or assets/meshes/source.
sources: [original, https://docs.blender.org/api/current/]
---

# Blender Python API, headless

## When to Load

Writing or debugging a `.py` that Blender executes without UI. Pair with `blender-modeling`, `blender-uv-texturing`, `blender-export`.

## Quick Reference

### Invocation (verified with Blender 5.2.1 LTS on Linux)

```bash
blender -b --python script.py -- arg1 arg2            # new empty scene, then script
blender -b file.blend --python script.py -- --flag x   # open file first
```
Script-side arguments: `sys.argv[sys.argv.index("--") + 1:]`. Exit code: `sys.exit(n)` at the end of the script propagates.
`import bpy` only works inside Blender; system `python3` has no `bpy` here.

### Reproducible scene from code

```python
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.5))
obj = bpy.context.active_object
obj.name = obj.data.name = "KIT_Crate_A"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
bpy.ops.object.mode_set(mode="OBJECT")
bpy.ops.wm.save_as_mainfile(filepath="assets/meshes/source/kit.blend")
```

### Facts that bite

- Operators need a context: in background mode most `bpy.ops.mesh.*` require Edit mode and an active object; set `bpy.context.view_layer.objects.active`.
- Blender 4.1+ removed `Mesh.use_auto_smooth`; use `bpy.ops.object.shade_smooth_by_angle()` or the Smooth by Angle modifier.
- Subdivision Surface shrinks a cube (1.0 m -> 0.84 m) and lifts its bottom: re-ground vertices after applying modifiers.
- `mesh.calc_loop_triangles()` then `len(mesh.loop_triangles)` is the triangle count the gate uses.
- FBX for Roblox: `axis_forward="-Z"`, `axis_up="Y"`, `bake_space_transform=True`, `apply_scale_options="FBX_SCALE_ALL"`, one object per file, no embedded textures.
- Units: 1 Blender unit = 1 m. Roblox: 1 m = 3.571 studs (R15 avatar 1.4 m = 5 studs).

### The gate

`tools/blender/validate_mesh.py` reads `art/budgets/budgets.yaml` and rejects: bad names, over-budget triangles, ngons, missing UV, UV out of 0-1, more than 1 material, unapplied transforms, origin not on ground, missing `_COL`, broken LOD ratios. Example with 3 intended failures: `tools/blender/make_fixture.py`.
