#!/usr/bin/env python3
"""Verifie la coherence du repo d'equipe. A lancer avant chaque PR: `python3 tools/check_repo.py`.

Controles:
  1. Tickets: front matter complet (id, title, role, phase, status, acceptance), status = dossier, role connu.
  2. Agents: chaque role a un ROLE.md avec les sections obligatoires.
  3. Skills .devin/skills: front matter name/description, name = nom du dossier, taille raisonnable.
  4. Liens markdown relatifs qui pointent vers des fichiers existants.
  5. Luau: --!strict en tete, globals interdits, longueur de fichier (art/budgets/budgets.yaml).
  6. Rojo: default.project.json valide et chemins existants.
  7. Aucun tiret cadratin / demi-cadratin dans les documents (regle de redaction de l'equipe).
Sortie 0 si tout passe, 1 sinon.
"""
from __future__ import annotations

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
from validate_mesh import load_budgets  # noqa: E402

ROLES = [
    "01-producteur",
    "02-game-designer",
    "03-directeur-artistique",
    "04-dev-serveur",
    "05-dev-client-ui",
    "06-tech-artist-3d",
    "07-artiste-2d",
    "08-level-designer",
    "09-qa-reviewer",
    "10-analyste-liveops",
]
ROLE_SECTIONS = ["## Mission", "## Entrees", "## Sorties", "## Definition of Done", "## Interdits", "## Skills a charger", "## Checklist"]
TICKET_FIELDS = ["id", "title", "role", "phase", "status", "acceptance"]
PHASES = ["P0-preparation", "P1-greybox", "P2-vertical-slice", "P3-alpha", "P4-soft-launch", "P5-live-ops"]
TICKET_STATUS_BY_DIR = {"backlog": "backlog", "in-progress": "in-progress", "review": "review", "done": "done"}
DASHES = "\u2014\u2013"

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def front_matter(text: str) -> dict | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    data: dict = {}
    for line in text[4:end].splitlines():
        if ":" in line and not line.startswith(" "):
            key, _, value = line.partition(":")
            data[key.strip()] = value.strip().strip('"').strip("'")
    return data


def walk_md() -> list[str]:
    out = []
    for base, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "Packages", "upstream", "__pycache__")]
        for name in files:
            if name.endswith(".md"):
                out.append(os.path.join(base, name))
    return sorted(out)


def check_tickets() -> None:
    seen: set[str] = set()
    for folder, expected in TICKET_STATUS_BY_DIR.items():
        path = os.path.join(ROOT, "tickets", folder)
        if not os.path.isdir(path):
            err(f"tickets/{folder} manquant")
            continue
        for name in sorted(os.listdir(path)):
            if not name.endswith(".md"):
                continue
            rel = f"tickets/{folder}/{name}"
            with open(os.path.join(path, name), encoding="utf-8") as fh:
                fm = front_matter(fh.read())
            if fm is None:
                err(f"{rel}: front matter manquant")
                continue
            for field in TICKET_FIELDS:
                if not fm.get(field):
                    err(f"{rel}: champ '{field}' manquant")
            if fm.get("status") != expected:
                err(f"{rel}: status '{fm.get('status')}' mais dossier '{folder}'")
            if fm.get("role") and fm["role"] not in ROLES:
                err(f"{rel}: role inconnu '{fm['role']}'")
            if fm.get("phase") and fm["phase"] not in PHASES:
                err(f"{rel}: phase inconnue '{fm['phase']}'")
            if fm.get("id"):
                if fm["id"] in seen:
                    err(f"{rel}: id duplique '{fm['id']}'")
                seen.add(fm["id"])
                if not name.startswith(fm["id"]):
                    err(f"{rel}: le nom de fichier doit commencer par l'id '{fm['id']}'")


def check_agents() -> None:
    for role in ROLES:
        path = os.path.join(ROOT, "agents", role, "ROLE.md")
        if not os.path.isfile(path):
            err(f"agents/{role}/ROLE.md manquant")
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        for section in ROLE_SECTIONS:
            if section not in text:
                err(f"agents/{role}/ROLE.md: section '{section}' manquante")
        playbook = os.path.join(ROOT, "playbooks", f"{role}.md")
        if not os.path.isfile(playbook):
            err(f"playbooks/{role}.md manquant")


def check_skills() -> None:
    skills_dir = os.path.join(ROOT, ".devin", "skills")
    if not os.path.isdir(skills_dir):
        err(".devin/skills manquant")
        return
    for name in sorted(os.listdir(skills_dir)):
        if not os.path.isdir(os.path.join(skills_dir, name)):
            continue
        skill = os.path.join(skills_dir, name, "SKILL.md")
        if not os.path.isfile(skill):
            err(f".devin/skills/{name}: SKILL.md manquant")
            continue
        with open(skill, encoding="utf-8") as fh:
            text = fh.read()
        fm = front_matter(text)
        if fm is None or not fm.get("name") or not fm.get("description"):
            err(f".devin/skills/{name}/SKILL.md: front matter name/description manquant")
        elif fm["name"] != name:
            err(f".devin/skills/{name}/SKILL.md: name '{fm['name']}' != dossier '{name}'")
        if len(text) > 40000:
            err(f".devin/skills/{name}/SKILL.md: {len(text)} caracteres, deplacer le detail dans references/")


LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s#]+)(#[^)]*)?\)")


def check_links_and_dashes() -> None:
    for path in walk_md():
        rel = os.path.relpath(path, ROOT)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if rel.startswith(".devin/skills/"):
            continue  # contenu vendored, licence et style de l'auteur conserves
        for i, line in enumerate(text.splitlines(), 1):
            if any(ch in line for ch in DASHES):
                err(f"{rel}:{i}: tiret cadratin ou demi-cadratin interdit")
        for match in LINK_RE.finditer(text):
            target = match.group(1)
            if re.match(r"^[a-z]+://", target) or target.startswith("mailto:"):
                continue
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), target))
            if not os.path.exists(resolved):
                err(f"{rel}: lien casse '{target}'")


def check_luau() -> None:
    budgets = load_budgets(os.path.join(ROOT, "art", "budgets", "budgets.yaml"))["luau"]
    forbidden = [re.compile(rf"(?<![\w.:]){re.escape(g)}\s*\(") for g in budgets["forbidden_globals"] if g not in ("_G", "shared")]
    forbidden_names = [g for g in budgets["forbidden_globals"] if g in ("_G", "shared")]
    for base, dirs, files in os.walk(os.path.join(ROOT, "src")):
        for name in files:
            if not name.endswith((".luau", ".lua")):
                continue
            path = os.path.join(base, name)
            rel = os.path.relpath(path, ROOT)
            with open(path, encoding="utf-8") as fh:
                lines = fh.read().splitlines()
            if name.endswith(".lua"):
                err(f"{rel}: extension .lua, utiliser .luau")
            if budgets["strict_mode_required"] and (not lines or not lines[0].startswith("--!strict")):
                err(f"{rel}: '--!strict' attendu en ligne 1")
            if len(lines) > budgets["max_file_lines"]:
                err(f"{rel}: {len(lines)} lignes > {budgets['max_file_lines']}, decouper le module")
            for i, line in enumerate(lines, 1):
                code = line.split("--", 1)[0]
                for rx in forbidden:
                    if rx.search(code):
                        err(f"{rel}:{i}: global interdit '{code.strip()[:40]}', utiliser task.*")
                        break
                for g in forbidden_names:
                    if re.search(rf"(?<![\w.]){g}(?![\w])", code):
                        err(f"{rel}:{i}: '{g}' interdit")


def check_rojo() -> None:
    path = os.path.join(ROOT, "default.project.json")
    try:
        with open(path, encoding="utf-8") as fh:
            project = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        err(f"default.project.json: {exc}")
        return

    def visit(node: dict) -> None:
        for key, value in node.items():
            if key == "$path":
                if isinstance(value, dict):
                    continue  # {"optional": "..."} est tolere absent
                if not os.path.exists(os.path.join(ROOT, value)):
                    err(f"default.project.json: chemin '{value}' introuvable")
            elif isinstance(value, dict):
                visit(value)

    visit(project.get("tree", {}))


def main() -> int:
    check_tickets()
    check_agents()
    check_skills()
    check_links_and_dashes()
    check_luau()
    check_rojo()
    for e in errors:
        print("REJECT", e)
    print(f"check_repo: {len(errors)} erreur(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
