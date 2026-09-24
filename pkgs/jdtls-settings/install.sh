# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out"
cp @formatter@ "$out/formatter.xml"
cp @prefs@ "$out/org.eclipse.jdt.core.prefs"
