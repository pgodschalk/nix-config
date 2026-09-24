# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
@fzf@ --nushell >"$out"
