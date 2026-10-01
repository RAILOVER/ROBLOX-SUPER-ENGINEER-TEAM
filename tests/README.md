# Tests

## Decision en attente (ticket d'architecture, phase P1)

Deux runners sont acceptables; le Producteur tranche avec le 04 et le 09 au premier ticket serveur:

| Runner | Pour | Contre |
|--------|------|--------|
| Jest Lua (`jsdotlua/jest`, Wally) | maintenu, mocks, snapshots, tourne dans Studio et via `run-in-roblox` | plus lourd a installer |
| TestEZ (`Roblox/testez`) | simple, connu | archive, plus de mises a jour |

Logique pure (validators, formules d'economie, courbes): testable hors Studio avec [Lune](https://lune-org.github.io/docs)
(`lune run tests/<fichier>.luau`), installe par `tools/install_toolchain.sh`.

## Convention

- `tests/server/<Module>.spec.luau`, `tests/client/<Module>.spec.luau`, `tests/shared/<Module>.spec.luau`.
- 1 `it(...)` par regle numerotee de la spec, nommee `S-xxxx regle N: <enonce>`.
- `tests/playtest/<scenario>.luau`: bots scriptes (voir `agents/09-qa-reviewer/ROLE.md`).
- La sortie du runner est collee dans la PR. Un test rouge bloque.
