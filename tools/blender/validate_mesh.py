"""Gate technique des meshes. Tourne DANS Blender, sans interface:

    blender -b <fichier.blend> --python tools/blender/validate_mesh.py -- --budgets art/budgets/budgets.yaml --report assets/meshes/reports/<nom>.json [--export assets/meshes/export]

Code de sortie 0 = tous les meshes passent, 1 = au moins un rejet. Le script ne juge pas le style,
il juge les contraintes de art/budgets/budgets.yaml: nommage, triangles, ngons, UV, materiaux,
transforms appliquees, origine, dimensions, collision, chaine de LOD.
Il peut aussi exporter chaque mesh valide en FBX (un fichier par objet, axes Roblox).
"""
from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys

try:
    import bpy  # type: ignore
except ImportError:  # importe par check_repo/check_textures hors Blender, pour load_budgets
    bpy = None

try:
    import bmesh  # type: ignore
except ImportError:  # pragma: no cover
    bmesh = None


def load_budgets(path: str) -> dict:
    """Lecteur YAML minimal (sous-ensemble: dicts, listes inline, scalaires, commentaires)."""
    try:
        import yaml  # type: ignore

        with open(path, "r", encoding="utf-8") as fh:
            return yaml.safe_load(fh)
    except ImportError:
        pass
    root: dict = {}
    stack: list[tuple[int, dict]] = [(-1, root)]
    with open(path, "r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.split(" #", 1)[0].rstrip() if not raw.lstrip().startswith("#") else ""
            if not line.strip():
                continue
            indent = len(line) - len(line.lstrip())
            key, _, value = line.strip().partition(":")
            value = value.strip()
            while stack and indent <= stack[-1][0]:
                stack.pop()
            parent = stack[-1][1]
            if value == "":
                child: dict = {}
                parent[key] = child
                stack.append((indent, child))
            else:
                parent[key] = parse_scalar(value)
    return root


def parse_scalar(value: str):
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        return [parse_scalar(v.strip()) for v in inner.split(",")] if inner else []
    if value.startswith("'") and value.endswith("'"):
        return value[1:-1]
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    if value.lower() in ("true", "false"):
        return value.lower() == "true"
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        return value


def category_of(name: str) -> str:
    return name.split("_", 1)[0]


def lod_index(name: str) -> int | None:
    match = re.search(r"_LOD([0-3])$", name)
    return int(match.group(1)) if match else None


def base_name(name: str) -> str:
    return re.sub(r"_LOD[0-3]$", "", name)


def triangle_count(obj) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def ngon_count(obj) -> int:
    return sum(1 for poly in obj.data.polygons if len(poly.vertices) > 4)


def uv_report(obj, budgets: dict) -> list[str]:
    errors: list[str] = []
    mesh = obj.data
    if not mesh.uv_layers:
        return ["uv: aucune UV map"]
    uv_layer = mesh.uv_layers.active.data
    lo, hi = budgets["uv"]["bounds"]
    tiling = "_TILE" in obj.name
    out_of_bounds = 0
    for loop in uv_layer:
        u, v = loop.uv
        if not (lo - 1e-4 <= u <= hi + 1e-4 and lo - 1e-4 <= v <= hi + 1e-4):
            out_of_bounds += 1
    if out_of_bounds and not tiling:
        errors.append(f"uv: {out_of_bounds} coordonnees hors [{lo}, {hi}] (suffixe _TILE pour les tilables)")
    if bmesh is not None:
        bm = bmesh.new()
        bm.from_mesh(mesh)
        uv_lay = bm.loops.layers.uv.active
        centers = {}
        overlaps = 0
        for face in bm.faces:
            uvs = [loop[uv_lay].uv for loop in face.loops]
            cx = round(sum(p.x for p in uvs) / len(uvs), 3)
            cy = round(sum(p.y for p in uvs) / len(uvs), 3)
            key = (cx, cy)
            if key in centers:
                overlaps += 1
            centers[key] = True
        bm.free()
        ratio = overlaps / max(1, len(mesh.polygons))
        if ratio > budgets["uv"]["max_overlap_ratio"]:
            errors.append(f"uv: {ratio:.1%} de faces UV superposees (max {budgets['uv']['max_overlap_ratio']:.0%})")
    return errors


def validate_object(obj, budgets: dict, names: set[str]) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    name = obj.name
    naming = budgets["naming"]
    is_collision = name.endswith(naming["collision_suffix"])
    logical = name[: -len(naming["collision_suffix"])] if is_collision else name

    if not re.match(naming["mesh_regex"], logical):
        errors.append(f"nommage: '{name}' ne respecte pas {naming['mesh_regex']}")
    cat = category_of(logical)
    tris = triangle_count(obj)
    ngons = ngon_count(obj)

    if is_collision:
        if tris > budgets["collision"]["max_triangles"]:
            errors.append(f"collision: {tris} tris > {budgets['collision']['max_triangles']}")
        if logical not in names:
            errors.append(f"collision: aucun mesh visuel '{logical}' pour '{name}'")
    else:
        budget = budgets["triangles"].get(cat)
        lod = lod_index(logical)
        if budget is not None:
            allowed = budget
            if lod is not None:
                allowed = math.floor(budget * budgets["triangles"]["lod_ratio"][lod])
            if tris > allowed:
                errors.append(f"triangles: {tris} > budget {allowed} ({cat}, LOD{lod if lod is not None else 0})")
        if tris > budgets["triangles"]["roblox_hard_limit"]:
            errors.append(f"triangles: {tris} depasse la limite moteur {budgets['triangles']['roblox_hard_limit']}")
        if ngons > budgets["triangles"]["max_ngons"]:
            errors.append(f"topologie: {ngons} ngons (max {budgets['triangles']['max_ngons']})")
        if budgets["uv"]["required"]:
            errors.extend(uv_report(obj, budgets))
        mats = [slot.material for slot in obj.material_slots if slot.material is not None]
        if len(mats) > budgets["materials"]["max_per_mesh"]:
            errors.append(f"materiaux: {len(mats)} > {budgets['materials']['max_per_mesh']} (atlas obligatoire)")
        if cat in budgets["collision"]["required_for"] and (lod in (None, 0)):
            if f"{base_name(logical)}{naming['collision_suffix']}" not in names:
                errors.append(f"collision: mesh '{base_name(logical)}{naming['collision_suffix']}' manquant")

    if budgets["units"]["apply_transforms"]:
        loc_ok = all(abs(v) < 1e-5 for v in obj.location)
        rot_ok = all(abs(v) < 1e-5 for v in obj.rotation_euler)
        scale_ok = all(abs(v - 1.0) < 1e-5 for v in obj.scale)
        if not (rot_ok and scale_ok):
            errors.append("transforms: rotation/scale non appliquees (Ctrl+A)")
        if not loc_ok:
            warnings.append("transforms: location non nulle, l'export FBX la remet a zero")

    dims = obj.dimensions
    if max(dims) > budgets["units"]["max_dimension_m"]:
        errors.append(f"dimensions: {max(dims):.2f} m > {budgets['units']['max_dimension_m']} m")
    if dims.x <= 0 or dims.y <= 0 or dims.z <= 0:
        errors.append("dimensions: mesh plat ou vide")

    min_z = min(v.co.z for v in obj.data.vertices) if obj.data.vertices else 0.0
    if abs(min_z) > budgets["units"]["origin_tolerance_m"] and cat in ("PROP", "KIT", "ENV") and not is_collision:
        errors.append(f"origine: le point le plus bas est a z={min_z:.3f} m dans le repere local, attendu 0 (origine au sol)")

    return {
        "name": name,
        "category": cat,
        "triangles": tris,
        "ngons": ngons,
        "dimensions_m": [round(d, 3) for d in dims],
        "materials": len(obj.material_slots),
        "errors": errors,
        "warnings": warnings,
        "status": "PASS" if not errors else "REJECT",
    }


def validate_lod_chains(results: list[dict], budgets: dict) -> None:
    by_base: dict[str, dict[int, dict]] = {}
    for res in results:
        if res["name"].endswith(budgets["naming"]["collision_suffix"]):
            continue
        idx = lod_index(res["name"])
        if idx is None:
            idx = 0  # un mesh sans suffixe est le LOD0 de sa chaine
        by_base.setdefault(base_name(res["name"]), {})[idx] = res
    for base, lods in by_base.items():
        if len(lods) == 1 and 0 in lods:
            continue
        if 0 not in lods:
            for res in lods.values():
                res["errors"].append(f"lod: chaine '{base}' sans LOD0")
                res["status"] = "REJECT"
            continue
        lod0 = lods[0]["triangles"]
        for idx, res in lods.items():
            if idx == 0:
                continue
            if res["triangles"] > lod0 * budgets["triangles"]["lod_ratio"][idx]:
                res["errors"].append(f"lod: LOD{idx} a {res['triangles']} tris > {budgets['triangles']['lod_ratio'][idx]:.0%} du LOD0 ({lod0})")
                res["status"] = "REJECT"


def export_fbx(obj, out_dir: str) -> str:
    os.makedirs(out_dir, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    path = os.path.join(out_dir, f"{obj.name}.fbx")
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_ALL",
        bake_space_transform=True,
        object_types={"MESH"},
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        add_leaf_bones=False,
        bake_anim=False,
        path_mode="COPY",
        embed_textures=False,
        axis_forward="-Z",
        axis_up="Y",
    )
    return path


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--budgets", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--export", default=None)
    args = parser.parse_args(argv)

    budgets = load_budgets(args.budgets)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    names = {o.name for o in meshes}
    results = [validate_object(o, budgets, names) for o in meshes]
    validate_lod_chains(results, budgets)

    exported = []
    if args.export:
        for obj, res in zip(meshes, results):
            if res["status"] == "PASS" and not obj.name.endswith(budgets["naming"]["collision_suffix"]):
                exported.append(export_fbx(obj, args.export))

    rejected = [r for r in results if r["status"] == "REJECT"]
    report = {
        "file": bpy.data.filepath,
        "blender": bpy.app.version_string,
        "budgets": args.budgets,
        "meshes": len(results),
        "rejected": len(rejected),
        "exported": exported,
        "results": results,
    }
    os.makedirs(os.path.dirname(os.path.abspath(args.report)), exist_ok=True)
    with open(args.report, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    for res in results:
        flag = "PASS  " if res["status"] == "PASS" else "REJECT"
        print(f"[{flag}] {res['name']:<36} {res['triangles']:>6} tris  {res['dimensions_m']}")
        for err in res["errors"]:
            print(f"         x {err}")
        for warn in res["warnings"]:
            print(f"         ! {warn}")
    print(f"\n{len(results) - len(rejected)}/{len(results)} meshes valides. Rapport: {args.report}")
    return 1 if rejected else 0


if __name__ == "__main__":
    code = main()
    sys.exit(code)
