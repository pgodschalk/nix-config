#!/usr/bin/env bash

set -euo pipefail

nufmt=$(.github/scripts/nix-tool.sh nufmt)/bin/nufmt
git ls-files '*.nu' | xargs "$nufmt" --dry-run
