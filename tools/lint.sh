#!/usr/bin/env bash
# Lint + format check + analyse de types Luau. Utilise par le CI et avant chaque PR.
#   tools/lint.sh          -> verifie
#   tools/lint.sh --fix    -> applique stylua
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$HOME/.local/bin:$PATH"

for tool in selene stylua luau-lsp rojo; do
	command -v "$tool" >/dev/null || { echo "outil manquant: $tool (rokit install ou tools/install_toolchain.sh)"; exit 2; }
done

if [[ "${1:-}" == "--fix" ]]; then
	stylua src
else
	stylua --check src
fi
selene src
rojo sourcemap default.project.json -o sourcemap.json
if [[ ! -f globalTypes.d.luau ]]; then
	curl -fsSL -o globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi
luau-lsp analyze --sourcemap=sourcemap.json --definitions=globalTypes.d.luau --ignore 'Packages/**' src
echo "lint: OK"
