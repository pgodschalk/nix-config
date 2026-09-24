# shellcheck shell=bash

# package.json declares no `bin` and no `files`, so the default
# `npm pack` install would neither produce an executable nor be
# predictable about what it keeps.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

mkdir -p "$out/lib/dockerhub-mcp-server"
cp -R dist package.json "$out/lib/dockerhub-mcp-server/"

npm prune --omit=dev
cp -R node_modules "$out/lib/dockerhub-mcp-server/"

makeWrapper @node@ "$out/bin/dockerhub-mcp-server" \
  --add-flags "$out/lib/dockerhub-mcp-server/dist/index.js"

runHook postInstall
