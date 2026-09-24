# shellcheck shell=bash

# nixpkgs installs Zed's CLI as `zeditor`, to stay clear of ZFS's `zed`
# event daemon -- a clash that cannot happen on macOS.
#
# A symlink rather than a wrapper: the CLI finds the app from its own
# resolved path, and a symlink resolves to the same store file.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out/bin"
ln -s @zeditor@ "$out/bin/zed"
