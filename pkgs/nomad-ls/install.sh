# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall
install -Dm755 nomad-ls "$out/bin/nomad-ls"
runHook postInstall
