# shellcheck shell=bash
# The entry point is the dependency's own bin, which resolves the
# grammar `.wasm` files through `import.meta.resolve`, so the tree is
# copied whole rather than flattened.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

# A directory of its own, so these node_modules do not meet another
# package's in the merged profile.
mkdir -p "$out/lib/cucumber-language-server"
cp -r node_modules "$out/lib/cucumber-language-server/"

makeWrapper @node@ "$out/bin/cucumber-language-server" \
  --add-flags "$out/lib/cucumber-language-server/node_modules/@cucumber/language-server/bin/cucumber-language-server.js"

runHook postInstall
