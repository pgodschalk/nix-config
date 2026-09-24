#!/usr/bin/env bash

# Usage: nix-tool.sh ATTR [BINARY]
#
# Prints the path of BINARY (ATTR by default) from the flake's own
# nixpkgs, the one the editor's copy comes from. A nixpkgs reference
# rebuilt out of flake.lock can resolve a different version, and CI
# would then disagree with the editor.
#
# The macOS configuration on a Mac and the Linux home configuration
# elsewhere, so the binary runs on the machine asking for it.
set -euo pipefail

attr=$1
binary=${2:-$1}

case "$(uname -s)" in
  Darwin) config='darwinConfigurations.Patricks-MacBook-Pro' ;;
  *) config='homeConfigurations."patrick@linux"' ;;
esac

while read -r out; do
  if [ -x "$out/bin/$binary" ]; then
    printf '%s\n' "$out/bin/$binary"
    exit 0
  fi
done < <(nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work ".#$config.pkgs.$attr")

echo "nix-tool.sh: $attr has no bin/$binary" >&2
exit 1
