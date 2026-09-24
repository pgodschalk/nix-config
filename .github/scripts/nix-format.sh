#!/usr/bin/env bash

set -euo pipefail

nixfmt=$(.github/scripts/nix-tool.sh nixfmt)
git ls-files '*.nix' | xargs -r "$nixfmt" --check
