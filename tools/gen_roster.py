#!/usr/bin/env python3
"""Genere src/shared/Config/Roster/*.luau et design/roster/lot-L0-fiches.md depuis design/brief/BATTLEROT.md §7.2.

Usage: python3 tools/gen_roster.py   (puis stylua src/shared/Config/Roster)
Le brief est la source de verite des noms; ce script ne fait que la transcrire. Aucun ajout de nom ici.
"""
import re
import unicodedata

BRIEF = "design/brief/BATTLEROT.md"
OUT_DIR = "src/shared/Config/Roster"
FICHES = "design/roster/lot-L0-fiches.md"
COUPLES = [("fraisio", "fraisita"), ("banano", "bananella"), ("pomito", "pomita"), ("myrtilo", "myrtila")]
RARITY = {"Champions": "Champion", "Légendaires": "Legendaire", "Épiques": "Epique", "Rares": "Rare", "Communes": "Commune"}
SUBROLE = {"Couple": "Couple", "Tentation": "Tentation", "Présentatrice": "Presentatrice"}


def ascii_(s: str) -> str:
    return unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()


def slug(n: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", ascii_(n).lower()).strip("-")


def camel(n: str) -> str:
    return "".join(w.capitalize() for w in re.split(r"[^A-Za-z0-9]+", ascii_(n)) if w)


def lstr(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def parse() -> list[dict]:
    text = open(BRIEF, encoding="utf-8").read()
    sec = text[text.index("### 7.2 Roster"):text.index("### 7.3 Stats")]
    rarity = None
    rows = []
    for line in sec.splitlines():
        m = re.match(r"#### (Champions|Légendaires|Épiques|Rares|Communes)", line)
        if m:
            rarity = RARITY[m.group(1)]
            continue
        m = re.match(r"\| (\d+) \| \*\*(.+?)\*\* \| (\d) \| (.+?) \| (.+?) \| (.+?) \| \*(.+?)\* : (.+?) \|", line)
        if not m or rarity is None:
            continue
        num, name, arena, fam, cls, look, skill, skill_text = m.groups()
        sub = None
        fm = re.match(r"Tentafruit \((\w+)\)", fam)
        if fm:
            sub, fam = SUBROLE[fm.group(1)], "Tentafruit"
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append({
            "num": int(num), "name": name, "slug": slug(name), "rarity": rarity, "arena": int(arena),
            "families": [ascii_(f.strip()) for f in fam.split(",")], "subRole": sub, "class": ascii_(cls),
            "skill": skill, "skillText": skill_text.strip(), "look": look.replace(" ⚠", "").strip(),
            "aura": cells[7] if rarity == "Champion" else None,
        })
    assert len(rows) == 42, len(rows)
    return sorted(rows, key=lambda r: r["num"])


def emit(rows: list[dict], module: str) -> str:
    partner = {a: b for a, b in COUPLES}
    partner.update({b: a for a, b in COUPLES})
    out = [
        "--!strict",
        f"-- {module} : GENERE par tools/gen_roster.py depuis design/brief/BATTLEROT.md §7.2. Ne pas editer a la main.",
        "-- Les noms ne se traduisent jamais. Aucun ajout hors pipeline brief §7.4 / §7.5 (validation humaine).",
        "", "return {",
    ]
    for r in rows:
        fams = ", ".join(lstr(f) for f in r["families"])
        cat = "tentafruit" if "Tentafruit" in r["families"] else "brainrot_it"
        out.append(f"\t[{lstr(r['slug'])}] = {{")
        out.append(f"\t\tname = {lstr(r['name'])},")
        out.append(f"\t\trarity = {lstr(r['rarity'])},")
        out.append(f"\t\tarena = {r['arena']},")
        out.append(f"\t\tfamilies = {{ {fams} }},")
        if r["subRole"]:
            out.append(f"\t\tsubRole = {lstr(r['subRole'])},")
        out.append(f"\t\tclass = {lstr(r['class'])},")
        out.append(f"\t\tcategory = {lstr(cat)},")
        out.append(f"\t\tskillId = {lstr(camel(r['skill']))},")
        if r["aura"]:
            out.append(f"\t\taura = {lstr(r['aura'])},")
        out.append("\t\tstatOverrides = {},")
        duo = lstr(partner[r["slug"]]) if r["slug"] in partner else ""
        out.append(f"\t\tduoPartners = {{ {duo} }}," if duo else "\t\tduoPartners = {},")
        out.append("\t},")
    out += ["}", ""]
    return "\n".join(out)


def main() -> None:
    rows = parse()
    brainrot = [r for r in rows if "Tentafruit" not in r["families"]]
    fruits = [r for r in rows if "Tentafruit" in r["families"]]
    open(f"{OUT_DIR}/L0Brainrot.luau", "w", encoding="utf-8").write(emit(brainrot, "Lot L0, brainrots italiens (28)"))
    open(f"{OUT_DIR}/L0Tentafruit.luau", "w", encoding="utf-8").write(emit(fruits, "Lot L0, Tentafruit (14)"))
    lines = [
        "# Lot L0 : fiches (generees)", "",
        "Genere par `python3 tools/gen_roster.py` depuis le brief §7.2. Les textes de competence et d'apparence servent au",
        "Game Designer (fiche detaillee), a la DA (references) et au Tech artist (traits signature). Ne pas editer a la main.", "",
        "| # | Slug | Nom | Rarete | Famille(s) | Classe | skillId | Competence | Apparence |", "|---|---|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        fam = ", ".join(r["families"]) + (f" ({r['subRole']})" if r["subRole"] else "")
        lines.append(f"| {r['num']} | `{r['slug']}` | {r['name']} | {r['rarity']} | {fam} | {r['class']} | `{camel(r['skill'])}` | *{r['skill']}* : {r['skillText']} | {r['look']} |")
    open(FICHES, "w", encoding="utf-8").write("\n".join(lines).replace("—", "-").replace("–", "-") + "\n")
    print(f"{len(brainrot)} brainrots, {len(fruits)} fruits -> {OUT_DIR}, {FICHES}")


if __name__ == "__main__":
    main()
