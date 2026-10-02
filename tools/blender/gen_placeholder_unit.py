"""Genere une unite placeholder (primitives, 1 materiau, armature 2 os, 3 actions) et l'exporte en FBX.
Tourne DANS Blender, jamais avec le Python systeme:

    blender -b --python tools/blender/gen_placeholder_unit.py -- --slug tralalero-tralala --out assets/meshes/source/

Sorties: <out>/<slug>.blend, <export>/<slug>/<slug>.fbx, un resume JSON sur stdout (tris, dimensions, tailles, duree).
Echelle: 1 unite Blender = 1 stud, personnage de HEIGHT_STUDS de haut, pieds a z = 0, face vers -Y
(axe -Z de Roblox apres export). Le mesh est nomme CHAR_<Slug> pour passer tools/blender/validate_mesh.py.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys
import time

import bpy  # type: ignore

FPS = 24
HEIGHT_STUDS = 5.0
ROOT_BONE = "Root"
BODY_BONE = "Body"
HIP_Z = 1.6  # vertices below this height follow Root, the rest follow Body


def box(name: str, size: tuple[float, float, float], center: tuple[float, float, float], bevel: float = 0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.active_object
    obj.name = obj.data.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def pyramid(name: str, radius: float, depth: float, center: tuple[float, float, float], tilt=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)):
    """Pyramide a base carree alignee sur X/Y, pointe vers +Z, puis inclinee de `tilt` (radians, XYZ)."""
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=radius, radius2=0.0, depth=depth, end_fill_type="TRIFAN", location=center, rotation=(0.0, 0.0, math.pi / 4))
    obj = bpy.context.active_object
    obj.name = obj.data.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler = tilt
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return obj


def build_tralalero_tralala() -> list:
    """Requin gris-bleu a 3 pattes et baskets. Traits signature: aileron de requin, 3 baskets."""
    parts = [
        box("body", (1.6, 3.4, 1.4), (0.0, 0.1, 2.3), bevel=0.25),
        box("head", (1.4, 1.5, 1.2), (0.0, -2.0, 2.5), bevel=0.2),
        pyramid("snout", 0.7, 1.0, (0.0, -3.1, 2.4), tilt=(math.pi / 2, 0.0, 0.0), scale=(1.0, 0.8, 1.0)),
        box("eye_L", (0.25, 0.25, 0.25), (0.65, -2.4, 2.9)),
        box("eye_R", (0.25, 0.25, 0.25), (-0.65, -2.4, 2.9)),
        # trait signature 1: aileron dorsal + nageoire caudale
        pyramid("fin_dorsal", 0.9, 2.0, (0.0, 0.3, 3.9), tilt=(-math.pi / 12, 0.0, 0.0), scale=(0.25, 1.0, 1.0)),
        pyramid("fin_tail", 0.7, 1.6, (0.0, 2.2, 3.3), tilt=(-math.pi / 5, 0.0, 0.0), scale=(0.2, 1.0, 1.0)),
    ]
    # trait signature 2: 3 pattes et 3 baskets (R3 Tripede a queue)
    for suffix, x, y in (("FL", 0.7, -0.9), ("FR", -0.7, -0.9), ("B", 0.0, 1.1)):
        parts.append(box(f"leg_{suffix}", (0.36, 0.36, 1.3), (x, y, 1.1)))
        parts.append(box(f"shoe_{suffix}", (0.7, 1.2, 0.45), (x, y - 0.15, 0.35), bevel=0.08))
        parts.append(box(f"sole_{suffix}", (0.8, 1.3, 0.16), (x, y - 0.15, 0.08)))
    return parts


BUILDERS = {"tralalero-tralala": build_tralalero_tralala}


def pascal(slug: str) -> str:
    return "".join(part.capitalize() for part in slug.split("-"))


def join_and_clean(parts: list, name: str):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = obj.data.name = name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    verts = obj.data.vertices
    min_z = min(v.co.z for v in verts)
    max_z = max(v.co.z for v in verts)
    factor = HEIGHT_STUDS / (max_z - min_z)
    for v in verts:
        v.co.x *= factor
        v.co.y *= factor
        v.co.z = (v.co.z - min_z) * factor
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.shade_flat()
    return obj


def add_material(obj, name: str, color=(0.42, 0.52, 0.62, 1.0)):
    obj.data.materials.clear()
    mat = bpy.data.materials.new(f"M_{name}")
    mat.diffuse_color = color
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.8
    obj.data.materials.append(mat)
    return mat


def add_armature(mesh_obj, name: str):
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    arm = bpy.context.active_object
    arm.name = arm.data.name = f"RIG_{name}"
    root = arm.data.edit_bones[0]
    root.name = ROOT_BONE
    root.head = (0.0, 0.0, 0.0)
    root.tail = (0.0, 0.0, HIP_Z)
    body = arm.data.edit_bones.new(BODY_BONE)
    body.head = (0.0, 0.0, HIP_Z)
    body.tail = (0.0, 0.0, HEIGHT_STUDS * 0.8)
    body.parent = root
    body.use_connect = True
    bpy.ops.object.mode_set(mode="OBJECT")

    root_group = mesh_obj.vertex_groups.new(name=ROOT_BONE)
    body_group = mesh_obj.vertex_groups.new(name=BODY_BONE)
    for v in mesh_obj.data.vertices:
        (root_group if v.co.z < HIP_Z else body_group).add([v.index], 1.0, "REPLACE")
    mesh_obj.parent = arm
    mod = mesh_obj.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    return arm


def key_pose(arm, frame: int, loc: dict | None = None, rot_deg: dict | None = None) -> None:
    for bone_name in (ROOT_BONE, BODY_BONE):
        pb = arm.pose.bones[bone_name]
        pb.rotation_mode = "XYZ"
        pb.location = (loc or {}).get(bone_name, (0.0, 0.0, 0.0))
        rx, ry, rz = (rot_deg or {}).get(bone_name, (0.0, 0.0, 0.0))
        pb.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
        pb.keyframe_insert("location", frame=frame)
        pb.keyframe_insert("rotation_euler", frame=frame)


def make_action(arm, name: str, keys: list[tuple[int, dict, dict]]):
    """keys: liste de (frame, {bone: (x, y, z)}, {bone: (rx, ry, rz) en degres}).
    Repere local des os (os verticaux, roll 0): Y local = +Z monde, Z local = -Y monde (vers l'avant du personnage)."""
    action = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = action
    for frame, loc, rot in keys:
        key_pose(arm, frame, loc, rot)
    action.use_frame_range = True
    action.frame_start = keys[0][0]
    action.frame_end = keys[-1][0]
    for layer in action.layers:  # Blender 4.4+: actions a couches et slots
        for strip in layer.strips:
            for channelbag in strip.channelbags:
                for fcurve in channelbag.fcurves:
                    fcurve.extrapolation = "CONSTANT"
    return action


def make_actions(arm) -> list:
    r, b = ROOT_BONE, BODY_BONE
    idle = make_action(arm, "Idle", [
        (1, {}, {}),
        (20, {b: (0.0, 0.12, 0.0)}, {b: (3.0, 0.0, 0.0)}),
        (40, {}, {}),
    ])
    attack = make_action(arm, "Attack", [
        (1, {}, {}),
        (6, {r: (0.0, 0.0, -0.5)}, {b: (12.0, 0.0, 0.0)}),
        (12, {r: (0.0, 0.0, 1.2)}, {b: (-25.0, 0.0, 0.0)}),
        (24, {}, {}),
    ])
    hit = make_action(arm, "Hit", [
        (1, {}, {}),
        (4, {r: (0.0, 0.0, -0.6)}, {b: (20.0, 0.0, 8.0)}),
        (10, {r: (0.0, 0.0, -0.3)}, {b: (10.0, 0.0, -5.0)}),
        (20, {}, {}),
    ])
    arm.animation_data.action = idle
    return [idle, attack, hit]


def export_fbx(mesh_obj, arm, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        global_scale=1.0,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        bake_space_transform=False,  # l'option casse les armatures (doc Blender), on garde les axes -Z/Y
        object_types={"ARMATURE", "MESH"},
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        add_leaf_bones=False,
        use_armature_deform_only=True,
        bake_anim=True,
        bake_anim_use_all_bones=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=True,
        bake_anim_force_startend_keying=True,
        bake_anim_simplify_factor=0.0,
        path_mode="AUTO",
        embed_textures=False,
        axis_forward="-Z",
        axis_up="Y",
    )


def render_preview(mesh_obj, path: str) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.film_transparent = True
    scene.render.filepath = path
    target = (0.0, 0.0, HEIGHT_STUDS / 2)
    bpy.ops.object.camera_add(location=(10.0, -10.0, 7.0))
    cam = bpy.context.active_object
    cam.data.lens = 50
    bpy.ops.object.empty_add(location=target)
    aim = bpy.context.active_object
    track = cam.constraints.new("TRACK_TO")
    track.target = aim
    track.track_axis = "TRACK_NEGATIVE_Z"
    track.up_axis = "UP_Y"
    scene.camera = cam
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)
    bpy.data.objects.remove(aim)


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--slug", required=True, choices=sorted(BUILDERS))
    parser.add_argument("--out", default="assets/meshes/source/")
    parser.add_argument("--export", default="assets/meshes/export/")
    parser.add_argument("--preview", action="store_true", help="rendu 3/4 Workbench 512 px a cote du FBX")
    args = parser.parse_args(argv)

    started = time.perf_counter()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.unit_settings.scale_length = 1.0

    name = pascal(args.slug)
    mesh_obj = join_and_clean(BUILDERS[args.slug](), f"CHAR_{name}")
    add_material(mesh_obj, name)
    arm = add_armature(mesh_obj, name)
    actions = make_actions(arm)
    scene.frame_start, scene.frame_end = 1, int(actions[0].frame_end)

    blend_path = os.path.abspath(os.path.join(args.out, f"{args.slug}.blend"))
    fbx_path = os.path.abspath(os.path.join(args.export, args.slug, f"{args.slug}.fbx"))
    export_fbx(mesh_obj, arm, fbx_path)
    preview_path = None
    if args.preview:
        preview_path = os.path.join(os.path.dirname(fbx_path), f"{args.slug}_preview.png")
        render_preview(mesh_obj, preview_path)
    os.makedirs(os.path.dirname(blend_path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=blend_path, compress=True)

    mesh_obj.data.calc_loop_triangles()
    summary = {
        "slug": args.slug,
        "mesh": mesh_obj.name,
        "triangles": len(mesh_obj.data.loop_triangles),
        "ngons": sum(1 for p in mesh_obj.data.polygons if len(p.vertices) > 4),
        "materials": len(mesh_obj.data.materials),
        "dimensions_studs": [round(d, 3) for d in mesh_obj.dimensions],
        "bones": [b.name for b in arm.data.bones],
        "actions": {a.name: [int(a.frame_start), int(a.frame_end)] for a in actions},
        "fps": FPS,
        "blend": blend_path,
        "blend_bytes": os.path.getsize(blend_path),
        "fbx": fbx_path,
        "fbx_bytes": os.path.getsize(fbx_path),
        "preview": preview_path,
        "seconds": round(time.perf_counter() - started, 2),
        "blender": bpy.app.version_string,
    }
    print("GEN_SUMMARY " + json.dumps(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main())
