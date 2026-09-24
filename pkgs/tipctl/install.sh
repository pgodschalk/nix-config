# shellcheck shell=bash

# `$out` is the build's output path, `$src` the fetched phar, both set
# by Nix.
# shellcheck disable=SC2154
runHook preInstall

mkdir -p "$out/libexec"
cp "$src" "$out/libexec/tipctl.phar"

makeWrapper @php@ "$out/bin/tipctl" \
  --add-flags "-d error_reporting=8191" \
  --add-flags "$out/libexec/tipctl.phar"

runHook postInstall
