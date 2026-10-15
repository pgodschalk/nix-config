# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
wrapProgram "$out/bin/ruby-lsp" \
  --set GEM_HOME "@gemHome@" \
  --set GEM_PATH "@gemPath@"
