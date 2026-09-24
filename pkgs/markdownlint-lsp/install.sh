# shellcheck shell=bash
# `npm install` would put the tree under lib/node_modules/<pname>,
# which is not where the server lives -- the entry point is the
# dependency's own lib/index.mjs. `--stdio` is mandatory.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

mkdir -p "$out/lib"
cp -r node_modules "$out/lib/"

makeWrapper @node@ "$out/bin/markdownlint-lsp" \
  --add-flags "$out/lib/node_modules/markdownlint-lsp/lib/index.mjs" \
  --add-flags "--stdio"

runHook postInstall
