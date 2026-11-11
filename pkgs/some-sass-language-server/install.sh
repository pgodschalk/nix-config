# shellcheck shell=bash
# The bin script requires ../dist/node-main.js and reads
# ../package.json for --version, so the three keep their layout.

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

mkdir -p "$out/lib/some-sass-language-server"
cp -R bin dist package.json "$out/lib/some-sass-language-server/"

makeWrapper @node@ "$out/bin/some-sass-language-server" \
  --add-flags "$out/lib/some-sass-language-server/bin/some-sass-language-server"

runHook postInstall
