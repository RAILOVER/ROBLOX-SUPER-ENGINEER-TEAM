#!/usr/bin/env bash
# Installe la toolchain Roblox epinglee dans rokit.toml sur une machine Linux x86_64 sans rokit.
# Blender doit etre installe separement (>= 4.2, teste avec 5.2).
set -euo pipefail
cd "$(dirname "$0")/.."
BIN="${BIN:-$HOME/.local/bin}"
mkdir -p "$BIN"
TMP="$(mktemp -d)"

dl() { # repo pattern
	gh release download --repo "$1" -p "$2" -D "$TMP/$3" --clobber
	unzip -oq "$TMP/$3"/*.zip -d "$TMP/$3/out"
	find "$TMP/$3/out" -maxdepth 1 -type f -exec chmod +x {} \; -exec cp {} "$BIN/" \;
}

ver() { grep "^$1 " rokit.toml | sed -E 's/.*@([0-9.]+)".*/\1/'; }

dl rojo-rbx/rojo "rojo-$(ver rojo)-linux-x86_64.zip" rojo
dl Kampfkarren/selene "selene-$(ver selene)-linux.zip" selene
dl JohnnyMorganz/StyLua "stylua-linux-x86_64.zip" stylua
dl JohnnyMorganz/luau-lsp "luau-lsp-linux-x86_64.zip" luau-lsp
dl lune-org/lune "lune-$(ver lune)-linux-x86_64.zip" lune
dl UpliftGames/wally "wally-v$(ver wally)-linux.zip" wally

for t in rojo selene stylua luau-lsp lune wally; do printf '%-9s ' "$t"; "$BIN/$t" --version; done
echo "Ajouter $BIN au PATH si necessaire."
