# shellcheck shell=bash

# `$srcs` and `$binaries` are set by Nix; a wheel is one asset, a zip
# holding each binary under `<name>-<version>.data/scripts/`.
# shellcheck disable=SC2154,SC2086
runHook preUnpack
unzip -q "$srcs" -d wheel
for binary in $binaries; do
  cp wheel/*.data/scripts/"$binary" .
done
runHook postUnpack
