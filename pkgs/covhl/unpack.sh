# shellcheck shell=bash

# The asset is a bare gzipped binary rather than a tarball, which
# stdenv's unpacker does not handle, and gunzip would write beside its
# input in the read-only store, so it is decompressed to stdout.
# `$src` is the fetched source, set by Nix.
# shellcheck disable=SC2154
runHook preUnpack
gzip -cd "$src" >covhl
runHook postUnpack
