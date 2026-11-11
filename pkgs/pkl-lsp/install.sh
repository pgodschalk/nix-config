# shellcheck shell=bash

# `$out` and `$src` are set by Nix.
# shellcheck disable=SC2154
runHook preInstall

install -D "$src" "$out/lib/pkl-lsp/pkl-lsp.jar"
makeWrapper @java@ "$out/bin/pkl-lsp" \
  --add-flags "-jar $out/lib/pkl-lsp/pkl-lsp.jar"

runHook postInstall
