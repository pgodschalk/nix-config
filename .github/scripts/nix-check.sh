#!/usr/bin/env bash

# Builds the flake check named in $1 for the system this runs on. The
# `work` input is a private tree that exists on no runner, so the stub
# stands in for it.
set -euo pipefail

system=$(nix eval --raw --impure --expr builtins.currentSystem)
nix build --no-link --print-build-logs \
  --override-input work path:./stubs/work ".#checks.$system.$1"
