#!/usr/bin/env bash

set -euo pipefail

shellcheck=$(.github/scripts/nix-tool.sh shellcheck)
git ls-files '*.sh' | xargs -r "$shellcheck"
