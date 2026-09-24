# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall
install -Dm755 agnix-lsp "$out/bin/agnix-lsp"
install -Dm755 agnix "$out/bin/agnix"
runHook postInstall
