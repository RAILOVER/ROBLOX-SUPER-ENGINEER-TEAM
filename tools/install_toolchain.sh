#!/usr/bin/env bash
# Installe la toolchain Roblox epinglee dans rokit.toml sur une machine Linux x86_64 sans rokit.
# Telechargements directs par tag GitHub (pas besoin de `gh` ni d'authentification).
# Blender doit etre installe separement (>= 4.2, teste avec 5.2).
set -euo pipefail
cd "$(dirname "$0")/.."
BIN="${BIN:-$HOME/.local/bin}"
mkdir -p "$BIN"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ver() { grep "^$1 " rokit.toml | sed -E 's/.*@([0-9.]+)".*/\1/'; }

dl() { # nom repo tag asset
	local name="$1" repo="$2" tag="$3" asset="$4"
	local url="https://github.com/$repo/releases/download/$tag/$asset"
	mkdir -p "$TMP/$name"
	curl -fsSL --retry 3 -o "$TMP/$name/$asset" "$url" || { echo "echec telechargement $url" >&2; exit 1; }
	unzip -oq "$TMP/$name/$asset" -d "$TMP/$name/out"
	find "$TMP/$name/out" -maxdepth 1 -type f -name "$name*" -exec chmod +x {} \; -exec cp {} "$BIN/$name" \;
}

dl rojo rojo-rbx/rojo "v$(ver rojo)" "rojo-$(ver rojo)-linux-x86_64.zip"
dl selene Kampfkarren/selene "$(ver selene)" "selene-$(ver selene)-linux.zip"
dl stylua JohnnyMorganz/StyLua "v$(ver stylua)" "stylua-linux-x86_64.zip"
dl luau-lsp JohnnyMorganz/luau-lsp "$(ver luau-lsp)" "luau-lsp-linux-x86_64.zip"
dl lune lune-org/lune "v$(ver lune)" "lune-$(ver lune)-linux-x86_64.zip"
dl wally UpliftGames/wally "v$(ver wally)" "wally-v$(ver wally)-linux.zip"

for t in rojo selene stylua luau-lsp lune wally; do printf '%-9s ' "$t"; "$BIN/$t" --version; done
echo "Ajouter $BIN au PATH si necessaire (export PATH=\"$BIN:\$PATH\")."
