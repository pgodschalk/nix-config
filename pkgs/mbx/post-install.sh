# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
makeWrapper "$out/bin/mbx" "$out/libexec/mbx/cargo" \
  --set MBX_CARGO_SHIM_MODE 1 \
  --set MBX_CARGO_SHIM_PATH "$out/libexec/mbx/cargo"
