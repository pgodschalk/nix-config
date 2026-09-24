#!/usr/bin/env bash

set -euo pipefail

ruff=$(.github/scripts/nix-tool.sh ruff)
"$ruff" check
"$ruff" format --check
