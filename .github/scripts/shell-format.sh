#!/usr/bin/env bash

set -euo pipefail

shfmt=$(.github/scripts/nix-tool.sh shfmt)
git ls-files '*.sh' \
  | xargs -r "$shfmt" --indent 2 --binary-next-line --case-indent --diff
