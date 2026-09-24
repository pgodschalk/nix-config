#!/usr/bin/env bash

set -euo pipefail

nixfmt=$(.github/scripts/nix-tool.sh nixfmt)/bin/nixfmt
git ls-files '*.nix' | xargs "$nixfmt" --check
