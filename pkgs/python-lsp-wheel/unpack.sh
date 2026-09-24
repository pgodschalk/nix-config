# shellcheck shell=bash

# A wheel is a zip, and `.whl` is not an extension stdenv unpacks by
# itself.
# `$src` is the fetched source, set by Nix.
# shellcheck disable=SC2154
runHook preUnpack
unzip -q "$src" -d wheel
runHook postUnpack
