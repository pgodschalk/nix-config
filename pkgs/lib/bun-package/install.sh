# shellcheck shell=bash

# `$out`, `$pname`, `$copy`, `$bun`, `$binary` and `$entry` are set by
# Nix; `$copy` splits on spaces.
# shellcheck disable=SC2154,SC2086
runHook preInstall

mkdir -p "$out/lib/$pname"
cp -R $copy "$out/lib/$pname/"
makeWrapper "$bun" "$out/bin/$binary" \
  --add-flags --no-install \
  --add-flags "$out/lib/$pname/$entry"

runHook postInstall
