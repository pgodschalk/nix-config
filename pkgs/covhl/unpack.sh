# shellcheck shell=bash

# The asset is a bare gzipped binary rather than a tarball: gunzip
# refuses a file whose name does not end in a recognised suffix, and a
# store path does not.
# `$src` is the fetched source, set by Nix.
# shellcheck disable=SC2154
runHook preUnpack
gzip -cd "$src" >covhl
runHook postUnpack
