# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall
install -Dm755 css-variable-lsp "$out/bin/css-variable-lsp"
runHook postInstall
