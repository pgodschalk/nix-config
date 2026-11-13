#!/usr/bin/env bash

set -euo pipefail

prettier_md=$(.github/scripts/nix-tool.sh --formatter prettier-md)
git ls-files '*.md' | xargs -r "$prettier_md" --check
