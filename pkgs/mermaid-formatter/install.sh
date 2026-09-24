# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

mkdir -p "$out/lib/mermaid-formatter"
cp -R dist package.json "$out/lib/mermaid-formatter/"

makeWrapper @bun@ "$out/bin/mermaidfmt" \
  --add-flags "$out/lib/mermaid-formatter/dist/cli.js"

# Upstream installs the binary under both names; `mermaidfmt` is the
# short one its own docs use.
ln -s "$out/bin/mermaidfmt" "$out/bin/mermaid-formatter"

runHook postInstall
