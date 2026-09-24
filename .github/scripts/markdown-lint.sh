#!/usr/bin/env bash

set -euo pipefail

markdownlint=$(.github/scripts/nix-tool.sh markdownlint-cli2)
git ls-files '*.md' | xargs -r "$markdownlint"
