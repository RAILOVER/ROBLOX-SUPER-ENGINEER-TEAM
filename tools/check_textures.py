#!/usr/bin/env python3
"""Gate technique des textures et images UI: nommage, puissance de 2, taille max, jeu PBR complet.

    python3 tools/check_textures.py [--budgets art/budgets/budgets.yaml] [--dir assets/textures] [--ui-dir assets/ui]

Sortie 0 si tout passe, 1 sinon. Ne juge pas le style (c'est le Directeur artistique), juge les contraintes.
"""
from __future__ import annotations

import argparse
import os
import re
import struct
import sys
import zlib

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "blender"))
from validate_mesh import load_budgets  # noqa: E402  (lecteur YAML partage, bpy non requis ici)


def png_size(path: str) -> tuple[int, int] | None:
    with open(path, "rb") as fh:
        header = fh.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        return None
    width, height = struct.unpack(">II", header[16:24])
    return width, height


def is_pow2(n: int) -> bool:
    return n > 0 and (n & (n - 1)) == 0


def check_textures(folder: str, budgets: dict) -> list[str]:
    errors: list[str] = []
    tex = budgets["textures"]
    regex = re.compile(budgets["naming"]["texture_regex"])
    sets: dict[str, set[str]] = {}
    for root, _, files in os.walk(folder):
        for name in sorted(files):
            if name == ".gitkeep":
                continue
            path = os.path.join(root, name)
            ext = name.rsplit(".", 1)[-1].lower()
            if ext not in tex["formats"]:
                errors.append(f"{name}: format .{ext} interdit (autorises: {tex['formats']})")
                continue
            match = regex.match(name)
            if not match:
                errors.append(f"{name}: nommage invalide, attendu T_<Nom>_<Color|Normal|Roughness|Metalness>.png")
            else:
                base = name[: name.rfind("_")]
                sets.setdefault(base, set()).add(match.group(2))
            size = png_size(path)
            if size is None:
                errors.append(f"{name}: PNG illisible")
                continue
            w, h = size
            if tex["power_of_two"] and not (is_pow2(w) and is_pow2(h)):
                errors.append(f"{name}: {w}x{h} n'est pas une puissance de 2")
            if max(w, h) > tex["max_size_px"]:
                errors.append(f"{name}: {w}x{h} > {tex['max_size_px']} px")
    required = set(budgets["materials"]["surface_appearance_maps"])
    for base, maps in sorted(sets.items()):
        missing = required - maps
        if missing:
            errors.append(f"{base}: jeu PBR incomplet, manque {sorted(missing)}")
    return errors


def check_ui(folder: str, budgets: dict) -> list[str]:
    errors: list[str] = []
    tex = budgets["textures"]
    for root, _, files in os.walk(folder):
        for name in sorted(files):
            if name == ".gitkeep":
                continue
            path = os.path.join(root, name)
            if not name.lower().endswith(".png"):
                errors.append(f"ui/{name}: seul le PNG est accepte")
                continue
            size = png_size(path)
            if size is None:
                errors.append(f"ui/{name}: PNG illisible")
                continue
            w, h = size
            if name.startswith("Thumbnail_") and [w, h] != tex["thumbnail_size_px"]:
                errors.append(f"ui/{name}: miniature {w}x{h}, attendu {tex['thumbnail_size_px']}")
            elif name.startswith("GameIcon_") and [w, h] != tex["game_icon_size_px"]:
                errors.append(f"ui/{name}: icone de jeu {w}x{h}, attendu {tex['game_icon_size_px']}")
            elif name.startswith("Icon_") and (w != h or w not in tex["icon_sizes_px"]):
                errors.append(f"ui/{name}: icone {w}x{h}, attendu carre dans {tex['icon_sizes_px']}")
            elif max(w, h) > tex["ui_max_size_px"] and not name.startswith("Thumbnail_"):
                errors.append(f"ui/{name}: {w}x{h} > {tex['ui_max_size_px']} px")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--budgets", default="art/budgets/budgets.yaml")
    parser.add_argument("--dir", default="assets/textures")
    parser.add_argument("--ui-dir", default="assets/ui")
    args = parser.parse_args()
    budgets = load_budgets(args.budgets)
    errors = check_textures(args.dir, budgets) + check_ui(args.ui_dir, budgets)
    for err in errors:
        print("REJECT", err)
    print(f"{len(errors)} erreur(s) texture/UI")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
