# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out/bin"
makeWrapper @steep@ "$out/bin/steep" --set GEM_PATH @gemPath@
