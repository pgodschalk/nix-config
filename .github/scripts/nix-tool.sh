#!/usr/bin/env bash

# Usage: nix-tool.sh ATTR [BINARY]
#        nix-tool.sh --formatter NAME
#
# Prints the path of BINARY (ATTR by default) from the flake's own
# nixpkgs, the one the editor's copy comes from. A nixpkgs reference
# rebuilt out of flake.lock can resolve a different version, and CI
# would then disagree with the editor.
#
# --formatter prints the path of the wrapper NAME from `my.formatters`,
# the derivation the editor itself runs.
#
# The macOS configuration on a Mac and the Linux home configuration
# elsewhere, so the binary runs on the machine asking for it.
set -euo pipefail

usage() {
  printf '%s\n' 'usage: nix-tool.sh ATTR [BINARY]' \
    '       nix-tool.sh --formatter NAME' >&2
  exit 2
}

if [ -z "${1-}" ] || { [ "$1" = --formatter ] && [ -z "${2-}" ]; }; then
  usage
fi

case "$(uname -s)" in
  Darwin)
    config='darwinConfigurations.Patricks-MacBook-Pro'
    user="$config.config.home-manager.users.patrick"
    ;;
  *)
    config='homeConfigurations."patrick@linux"'
    user="$config.config"
    ;;
esac

if [ "$1" = --formatter ]; then
  attr=my.formatters.$2
  installable=".#$user.$attr"
  binary=$2
else
  attr=$1
  installable=".#$config.pkgs.$attr"
  binary=${2:-$1}
fi

while read -r out; do
  if [ -x "$out/bin/$binary" ]; then
    printf '%s\n' "$out/bin/$binary"
    exit 0
  fi
done < <(nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work "$installable")

echo "nix-tool.sh: $attr has no bin/$binary" >&2
exit 1
