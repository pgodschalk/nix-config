# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out"
@mise@ activate nu >"$out/mise.nu"

if grep --quiet --fixed-strings "$PATH" "$out/mise.nu"; then
  echo "mise activate embedded the build's PATH in mise.nu" >&2
  exit 1
fi
