# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

mkdir -p "$out/lib/skill-language-server"
cp -R dist package.json "$out/lib/skill-language-server/"

makeWrapper @bun@ "$out/bin/skill-language-server" \
  --add-flags "$out/lib/skill-language-server/dist/main.cjs"

runHook postInstall
