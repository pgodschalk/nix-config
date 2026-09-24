# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out"

for v in pro alucard; do
  substitute @gitconfigTemplate@ "$out/$v.gitconfig" \
    --replace-fail '@variant@' "$v"

  substitute @envTemplate@ "$out/$v.env" \
    --replace-fail '@variant@' "$v" \
    --replace-fail '@out@' "$out"
done
