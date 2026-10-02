#!/usr/bin/env python3
"""Estime le nombre de manches d'un duel BATTLEROT a partir des degats au joueur (brief §10.7, Config.Duel).

Modele volontairement simple (pas de combat simule, voir T-0015 pour la vraie simulation) :
  - 2 joueurs a `hp` PV ; manches PvE (1, 6, 11) sans degats au joueur ;
  - chaque manche PvP a un perdant tire avec la probabilite `pwin` pour le joueur A ;
  - degats = base + tier_mult * palier + star_mult * etoiles, palier = ceil(manche / 3) plafonne a 5 ;
  - etoiles survivantes = U(1, niveau) unites, dont U(0, n) en 2 etoiles apres la manche 5 ;
  - niveau du joueur = min(8, 2 + manche // 3) ; `tie` = part de manches nulles (demi-degats aux deux).

Usage : python3 tools/sim_duel_length.py [--hp 100] [--base 6] [--tier-mult 4] [--star-mult 2] [--n 5000]
Sortie : mediane / p10 / p90 du nombre de manches pour 3 niveaux d'ecart entre joueurs.
"""
from __future__ import annotations

import argparse
import random
import statistics

PVE_ROUNDS = {1, 6, 11}


def simulate(hp: int, base: int, tier_mult: int, star_mult: int, pwin: float, n: int, tie: float) -> list[int]:
    rng = random.Random(42)
    results: list[int] = []
    for _ in range(n):
        health = [hp, hp]
        rnd = 0
        while min(health) > 0 and rnd < 80:
            rnd += 1
            if rnd in PVE_ROUNDS:
                continue
            tier = min(5, -(-rnd // 3))
            level = min(8, 2 + rnd // 3)
            survivors = rng.randint(1, level)
            stars = survivors + (rng.randint(0, survivors) if rnd > 5 else 0)
            damage = base + tier_mult * tier + star_mult * stars
            if rng.random() < tie:
                health[0] -= damage // 2
                health[1] -= damage // 2
                continue
            loser = 1 if rng.random() < pwin else 0
            health[loser] -= damage
        results.append(rnd)
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--hp", type=int, default=100)
    parser.add_argument("--base", type=int, default=6)
    parser.add_argument("--tier-mult", type=int, default=4)
    parser.add_argument("--star-mult", type=int, default=2)
    parser.add_argument("--n", type=int, default=5000)
    parser.add_argument("--tie", type=float, default=0.02)
    args = parser.parse_args()
    print(f"hp={args.hp} degats = {args.base} + {args.tier_mult} x palier + {args.star_mult} x etoiles, n={args.n}")
    for label, pwin in (("50/50", 0.5), ("65/35", 0.65), ("80/20", 0.8)):
        rounds = simulate(args.hp, args.base, args.tier_mult, args.star_mult, pwin, args.n, args.tie)
        q = statistics.quantiles(rounds, n=10)
        print(f"  ecart {label}: mediane {statistics.median(rounds):.0f} manches, p10 {q[0]:.0f}, p90 {q[-1]:.0f}")


if __name__ == "__main__":
    main()
