#!/usr/bin/env bash

# `xargs -r`: given no paths, tombi walks the whole tree.
set -euo pipefail

tombi=$(.github/scripts/nix-tool.sh tombi)
git ls-files '*.toml' | xargs -r "$tombi" "$@"
