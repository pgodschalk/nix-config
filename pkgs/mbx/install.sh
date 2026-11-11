# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall
install -Dm755 mbx "$out/bin/mbx"
makeWrapper "$out/bin/mbx" "$out/libexec/mbx/cargo" \
  --set MBX_CARGO_SHIM_MODE 1 \
  --set MBX_CARGO_SHIM_PATH "$out/libexec/mbx/cargo"
runHook postInstall
