# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
mkdir -p "$out"
cp @prepareCommitMsg@ "$out/prepare-commit-msg"
cp @commitMsg@ "$out/commit-msg"
chmod +x "$out/prepare-commit-msg" "$out/commit-msg"

# Every other hook git knows only chains to the repository's own.
while read -r hook; do
  ln -s @hookStub@ "$out/$hook"
done <@stubHooks@
