# shellcheck shell=bash

# `$srcs` and `$binaries` are set by Nix; a bare file is one asset.
# shellcheck disable=SC2154
runHook preUnpack
cp "$srcs" "${binaries%% *}"
runHook postUnpack
