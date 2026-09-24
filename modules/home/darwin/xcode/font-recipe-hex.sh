# shellcheck shell=bash

# The font recipe as a flat hex string, which is what `defaults write
# -data` takes. `-An` drops the offset column, `-v` stops od collapsing
# repeated bytes into a `*` line.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
od -An -tx1 -v <@recipe@ | tr -d ' \n' >"$out"
