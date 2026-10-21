# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154

# Upstream installs the binary under both names; `mermaidfmt` is the
# short one its own docs use.
ln -s "$out/bin/mermaidfmt" "$out/bin/mermaid-formatter"
