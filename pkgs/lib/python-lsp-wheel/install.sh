# shellcheck shell=bash

# The wheel's whole payload is one executable under
# `<name>-<version>.data/scripts/`.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall
install -Dm755 wheel/*.data/scripts/@binary@ "$out/bin/@binary@"
runHook postInstall
