# shellcheck shell=bash

# `$src` and `$binaries` are set by Nix.
# shellcheck disable=SC2154
runHook preUnpack
gzip -cd "$src" >"${binaries%% *}"
runHook postUnpack
