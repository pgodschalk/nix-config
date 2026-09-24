# shellcheck shell=bash

# `$out` and `$src` are set by Nix.
# shellcheck disable=SC2154
install -Dm755 "$src" "$out/bin/impeccable"
