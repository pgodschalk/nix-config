# shellcheck shell=bash

# `$srcs` and `$binaries` are set by Nix; a bare `.gz` is one asset.
# shellcheck disable=SC2154
runHook preUnpack
# `-cd` writes to stdout; a plain gunzip would write beside its input in
# the read-only store.
gzip -cd "$srcs" >"${binaries%% *}"
runHook postUnpack
