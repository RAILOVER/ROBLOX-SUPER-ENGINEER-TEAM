"""Reimporte un FBX dans une scene vide et imprime ce qu'il contient (objets, os, tris, dimensions, actions).
Preuve de relecture du fichier exporte, pas une preuve d'import Roblox:

    blender -b --python tools/blender/inspect_fbx.py -- assets/meshes/export/<slug>/<slug>.fbx
"""
import json
import sys

import bpy  # type: ignore

path = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path)

report = {"file": path, "objects": [], "actions": {}}
for obj in bpy.data.objects:
    entry = {"name": obj.name, "type": obj.type, "dimensions": [round(d, 3) for d in obj.dimensions]}
    if obj.type == "MESH":
        obj.data.calc_loop_triangles()
        entry["triangles"] = len(obj.data.loop_triangles)
        entry["materials"] = [m.name for m in obj.data.materials if m]
        entry["uv_layers"] = len(obj.data.uv_layers)
        entry["vertex_groups"] = [g.name for g in obj.vertex_groups]
    if obj.type == "ARMATURE":
        entry["bones"] = [b.name for b in obj.data.bones]
    report["objects"].append(entry)
armatures = [o for o in bpy.data.objects if o.type == "ARMATURE"]
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
for action in bpy.data.actions:
    start, end = int(action.frame_range[0]), int(action.frame_range[1])
    entry = {"frames": [start, end]}
    if armatures and meshes:
        # preuve que le skinning bouge: boite englobante du mesh evalue au repos et au milieu de l'action
        arm = armatures[0]
        arm.animation_data_create()
        arm.animation_data.action = action
        boxes = []
        for frame in (start, (start + end) // 2):
            bpy.context.scene.frame_set(frame)
            evaluated = meshes[0].evaluated_get(bpy.context.evaluated_depsgraph_get())
            coords = [meshes[0].matrix_world @ v.co for v in evaluated.data.vertices]
            boxes.append([round(max(c.z for c in coords), 3), round(min(c.y for c in coords), 3)])
        entry["max_z_min_y_at_start_and_mid"] = boxes
    report["actions"][action.name] = entry
report["fps"] = bpy.context.scene.render.fps
print("FBX_INSPECT " + json.dumps(report))
