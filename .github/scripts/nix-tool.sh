#!/usr/bin/env bash

# Prints the store path of a package, taken from the flake rather than
# from a nixpkgs reference rebuilt out of flake.lock. The two are not
# the same: `github:NixOS/nixpkgs/<the locked rev>` resolves nufmt to a
# 2026-03-26 build against the 2026-09-20 one this flake evaluates to,
# and CI would then disagree with the editor about formatting.
#
# The Linux home configuration is the portable half of what the machine
# runs, so its `pkgs` is this repository's own nixpkgs for the platform
# the runner is on.
set -euo pipefail

nix build --no-link --print-out-paths --override-input work path:./stubs/work \
  ".#homeConfigurations.\"patrick@linux\".pkgs.$1"
