#!/usr/bin/env python3
"""Transcrit design/levels/<arena>/layout.json en table Luau pure src/shared/Config/Arenas/<Arena>.luau.

Usage: python3 tools/gen_arena.py            genere (et formate avec stylua si present)
       python3 tools/gen_arena.py --check    echoue si un module genere n'est plus a jour
Le JSON est la source de verite du level designer; le module Luau est lu par ArenaBuilder (serveur)
et par ArenaGeometry (partage, pur, teste sous Lune). Aucune valeur n'est ajoutee ici.
"""
from __future__ import annotations

import glob
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYOUTS = os.path.join(ROOT, "design", "levels", "*", "layout.json")
OUT_DIR = os.path.join(ROOT, "src", "shared", "Config", "Arenas")
IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def module_name(arena_id: str) -> str:
    return "".join(w.capitalize() for w in re.split(r"[^A-Za-z0-9]+", arena_id) if w)


def lstr(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def is_scalar(value) -> bool:
    return isinstance(value, (bool, int, float, str))


def is_flat(value) -> bool:
    """Table sans imbrication profonde : tient sur 1 ligne (stylua la developpe si > 100 colonnes)."""
    if isinstance(value, list):
        return all(is_scalar(v) for v in value)
    if isinstance(value, dict):
        return all(is_scalar(v) or (isinstance(v, list) and is_flat(v)) for v in value.values())
    return False


def key_of(key: str) -> str:
    return key if IDENT.match(key) else f"[{lstr(key)}]"


def emit(value, indent: int) -> str:
    pad = "\t" * (indent + 1)
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return lstr(value)
    if isinstance(value, (list, dict)) and not value:
        return "{}"
    if isinstance(value, list):
        if is_flat(value):
            return "{ " + ", ".join(emit(v, indent) for v in value) + " }"
        return "{\n" + "".join(f"{pad}{emit(v, indent + 1)},\n" for v in value) + "\t" * indent + "}"
    if isinstance(value, dict):
        if is_flat(value):
            return "{ " + ", ".join(f"{key_of(k)} = {emit(v, indent)}" for k, v in value.items()) + " }"
        lines = [f"{pad}{key_of(k)} = {emit(v, indent + 1)},\n" for k, v in value.items()]
        return "{\n" + "".join(lines) + "\t" * indent + "}"
    raise TypeError(f"type non supporte: {type(value)}")


def render(layout: dict, rel_json: str) -> str:
    # Les plans de decor sont sortis en locals pour reduire l'indentation : une Part tient sur 1 ligne.
    header = (
        "--!strict\n"
        f"-- {module_name(layout['id'])} : GENERE par tools/gen_arena.py depuis {rel_json}. Ne pas editer a la main.\n"
        "-- Table pure (aucun type Roblox) : positions en studs [x, y, z], couleurs en hex #RRGGBB.\n\n"
        "local Types = require(script.Parent.Types)\n\n"
    )
    planes = layout.get("planes", {})
    locals_src = "".join(f"local {name}: Types.Plane = {emit(plane, 0)}\n\n" for name, plane in planes.items())
    top = dict(layout)
    if planes:
        top["planes"] = None
    body = "local arenaDef: Types.ArenaDef = {\n"
    for key, value in top.items():
        if key == "planes":
            inner = "".join(f"\t\t{key_of(n)} = {n},\n" for n in planes)
            body += "\tplanes = {\n" + inner + "\t},\n"
        else:
            body += f"\t{key_of(key)} = {emit(value, 1)},\n"
    body += "}\n\nreturn table.freeze(arenaDef)\n"
    return format_with_stylua(header + locals_src + body)


def format_with_stylua(source: str) -> str:
    stylua = shutil.which("stylua") or os.path.expanduser("~/.local/bin/stylua")
    if not os.path.exists(stylua):
        print("stylua absent: sortie non formatee (tools/install_toolchain.sh)", file=sys.stderr)
        return source
    cfg = os.path.join(ROOT, "stylua.toml")
    result = subprocess.run([stylua, "--config-path", cfg, "-"], input=source, text=True, capture_output=True, check=True)
    return result.stdout


def main() -> int:
    check = "--check" in sys.argv
    stale = 0
    for path in sorted(glob.glob(LAYOUTS)):
        with open(path, encoding="utf-8") as fh:
            layout = json.load(fh)
        rel_json = os.path.relpath(path, ROOT)
        out = os.path.join(OUT_DIR, module_name(layout["id"]) + ".luau")
        source = render(layout, rel_json)
        if check:
            current = open(out, encoding="utf-8").read() if os.path.exists(out) else ""
            status = "OK" if current == source else "STALE"
            stale += status == "STALE"
            print(f"{status} {os.path.relpath(out, ROOT)}")
        else:
            os.makedirs(OUT_DIR, exist_ok=True)
            with open(out, "w", encoding="utf-8") as fh:
                fh.write(source)
            print(f"ecrit {os.path.relpath(out, ROOT)} ({source.count(chr(10))} lignes)")
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main())
