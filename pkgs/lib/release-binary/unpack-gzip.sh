# shellcheck shell=bash

# `$src` and `$binaries` are set by Nix.
# shellcheck disable=SC2154
runHook preUnpack
# `-cd` writes to stdout; a plain gunzip would write beside its input in
# the read-only store.
gzip -cd "$src" >"${binaries%% *}"
runHook postUnpack
