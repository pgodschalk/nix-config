# shellcheck shell=bash

# The binary dispatches on argv[0]: as `tsc` it is the compiler and
# `--lsp --stdio` hangs, as `tsgo` the identical file is a language
# server. A symlink rather than a wrapper, which would set argv[0] to
# itself and give the compiler back.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out/bin"
ln -s @tsc@ "$out/bin/tsgo"
