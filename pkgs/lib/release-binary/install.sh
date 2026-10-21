# shellcheck shell=bash

# `$out` and `$binaries` are set by Nix; `$binaries` splits on spaces.
# shellcheck disable=SC2154,SC2086
runHook preInstall
for binary in $binaries; do
  install -Dm755 "$binary" "$out/bin/$binary"
done
runHook postInstall
