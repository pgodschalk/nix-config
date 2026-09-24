# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
wrapProgram "$out/bin/rubocop" \
  --set-default XDG_CONFIG_HOME "@configHome@"
