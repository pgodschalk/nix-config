#!/usr/bin/env bash

set -euo pipefail

nufmt=$(.github/scripts/nix-tool.sh nufmt)
git ls-files '*.nu' | xargs -r "$nufmt" --dry-run
