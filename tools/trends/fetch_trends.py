#!/usr/bin/env python3
"""Collecte de signaux publics de tendance memes, en lecture seule et sans cle d'API.

Sources (toutes publiques, sans authentification):
  - Wikipedia EN: membres des categories "Internet memes introduced in <annee>"
  - Wikimedia REST: vues par article sur N jours (all-access, agents=user)
  - Imgflip get_memes: templates populaires (optionnel, --imgflip)

Sortie: un markdown avec les donnees brutes et la commande qui le regenere. Ce script ne modifie
jamais la config du jeu: la shortlist et les filtres (brief §7.5) sont des decisions humaines.

Usage:
  python3 tools/trends/fetch_trends.py --years 2025 2026 --days 30 --end 2026-09-30 \
      --extra "Italian brainrot" "Moai" --out docs/reports/trends-2026-10-01-data.md
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import time
import urllib.parse
import urllib.request

UA = {"User-Agent": "battlerot-trends/0.1 (repo RAILOVER/ROBLOX-SUPER-ENGINEER-TEAM; lecture seule)"}
WIKI_API = "https://en.wikipedia.org/w/api.php"
PV_API = "https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/en.wikipedia/all-access/user"


def get_json(url: str, retries: int = 4) -> dict | None:
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as resp:
                return json.load(resp)
        except Exception as exc:  # noqa: BLE001 - on veut continuer sur les autres pages
            if attempt == retries - 1:
                print(f"ERREUR {url}: {exc}", file=sys.stderr)
            time.sleep(3.0 * (attempt + 1))  # l'API Wikimedia repond 429 au-dela de ~100 req/s
    return None


def category_members(year: int) -> list[str]:
    titles: list[str] = []
    params = {
        "action": "query", "list": "categorymembers", "cmlimit": "500", "format": "json",
        "cmtitle": f"Category:Internet memes introduced in {year}", "cmnamespace": "0",
    }
    cont: dict = {}
    while True:
        data = get_json(WIKI_API + "?" + urllib.parse.urlencode({**params, **cont}))
        if not data:
            break
        titles += [m["title"] for m in data["query"]["categorymembers"]]
        cont = data.get("continue", {})
        if not cont:
            break
    return titles


def pageviews(title: str, start: dt.date, end: dt.date) -> int | None:
    time.sleep(0.25)  # politesse : l'API publique limite le debit
    t = urllib.parse.quote(title.replace(" ", "_"), safe="")
    data = get_json(f"{PV_API}/{t}/daily/{start:%Y%m%d}/{end:%Y%m%d}")
    if not data:
        return None
    return sum(item["views"] for item in data.get("items", []))


def imgflip_popular() -> list[str]:
    data = get_json("https://api.imgflip.com/get_memes")
    if not data or not data.get("success"):
        return []
    return [m["name"] for m in data["data"]["memes"][:30]]


def clean(text: str) -> str:
    return text.replace("\u2014", "-").replace("\u2013", "-").replace("|", "/")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--years", type=int, nargs="+", default=[dt.date.today().year - 1, dt.date.today().year])
    ap.add_argument("--days", type=int, default=30)
    ap.add_argument("--end", type=lambda s: dt.date.fromisoformat(s), default=dt.date.today() - dt.timedelta(days=1))
    ap.add_argument("--extra", nargs="*", default=[], help="titres Wikipedia supplementaires a mesurer")
    ap.add_argument("--imgflip", action="store_true")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    start = args.end - dt.timedelta(days=args.days - 1)
    rows: list[tuple[int, str, str]] = []
    for year in args.years:
        members = category_members(year)
        print(f"{year}: {len(members)} pages", file=sys.stderr)
        for title in members:
            views = pageviews(title, start, args.end)
            rows.append((views if views is not None else -1, title, str(year)))
    for title in args.extra:
        views = pageviews(title, start, args.end)
        rows.append((views if views is not None else -1, title, "extra"))
    rows.sort(reverse=True)

    cmd = "python3 tools/trends/fetch_trends.py " + " ".join(sys.argv[1:])
    lines = [
        f"# Donnees brutes de tendance ({start} au {args.end}, {args.days} jours)",
        "",
        "Genere par `tools/trends/fetch_trends.py`. Ne pas editer a la main; regenerer avec :",
        "", "```bash", clean(cmd), "```", "",
        "Source : Wikipedia EN, categories `Internet memes introduced in <annee>` + titres `--extra`;",
        "vues = somme des vues humaines (agents=user, all-access) via l'API Wikimedia REST. -1 = indisponible (page introuvable ou limite de debit 429 de l'API : relancer plus tard).",
        "Une vue Wikipedia mesure la curiosite, pas la popularite sur TikTok : c'est un signal parmi d'autres.",
        "",
        "| Vues " + str(args.days) + " j | Page | Categorie |", "|---|---|---|",
    ]
    for views, title, cat in rows:
        lines.append(f"| {views} | {clean(title)} | {cat} |")
    if args.imgflip:
        lines += ["", "## Imgflip : 30 templates populaires (sans cle)", ""]
        lines += [f"- {clean(n)}" for n in imgflip_popular()]
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    print(f"{len(rows)} lignes -> {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
