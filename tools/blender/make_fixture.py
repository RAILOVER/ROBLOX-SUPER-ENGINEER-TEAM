"""Genere assets/meshes/source/fixture_kit.blend: 1 mesh conforme, 1 collision, 2 LODs et 3 meshes volontairement fautifs.
Sert a tester validate_mesh.py et a montrer au Tech artist 3D ce que le gate attend.

    blender -b --python tools/blender/make_fixture.py -- assets/meshes/source/fixture_kit.blend
"""
import sys

import bpy  # type: ignore

out = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)


def cube(name, size=1.0, z=0.5, subdiv=0, ground_origin=True):
    bpy.ops.mesh.primitive_cube_add(size=size, location=(0, 0, z))
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    if subdiv:
        mod = obj.modifiers.new("Subd", "SUBSURF")
        mod.levels = subdiv
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.transform_apply(location=ground_origin, rotation=True, scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    if ground_origin:
        min_z = min(v.co.z for v in obj.data.vertices)
        for v in obj.data.vertices:
            v.co.z -= min_z
    mat = bpy.data.materials.new(f"M_{name}")
    obj.data.materials.append(mat)
    return obj


# Conforme: KIT_Crate_A (48 tris, origine au sol), sa collision (12 tris), LOD1 (12 tris <= 50 %)
cube("KIT_Crate_A", 1.0, 0.5, subdiv=1)
col = cube("KIT_Crate_A_COL", 1.0, 0.5)
col.data.materials.clear()
cube("KIT_Crate_A_LOD1", 1.0, 0.5)

# Fautif 1: trop de triangles pour un KIT (budget 800)
cube("KIT_Boulder_Heavy", 2.0, 1.0, subdiv=4)
# Fautif 2: mauvais nommage
cube("Cube.027", 1.0, 0.5)
# Fautif 3: scale non appliquee + 2 materiaux + pas de collision + origine au centre
bad = cube("PROP_Barrel_B", 1.0, 0.5, ground_origin=False)
bad.scale = (1.0, 1.0, 2.0)
bad.data.materials.append(bpy.data.materials.new("M_second"))

bpy.ops.wm.save_as_mainfile(filepath=out)
print("fixture ecrite:", out)
