# shellcheck shell=bash
# The server imports `@sarvagnan/jsonl-core` by package name, so both
# sit in one node_modules for Node's resolution to find.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

# A directory of its own, so this node_modules does not meet another
# package's in the merged profile.
modules="$out/lib/jsonl-lsp/node_modules/@sarvagnan"
mkdir -p "$modules/jsonl-lsp" "$modules/jsonl-core"
cp -R bin package.json "$modules/jsonl-lsp/"
tar -xzf @core@ -C "$modules/jsonl-core" --strip-components=1

makeWrapper @node@ "$out/bin/jsonl-lsp" \
  --add-flags "$modules/jsonl-lsp/bin/jsonl-lsp.js"

runHook postInstall
