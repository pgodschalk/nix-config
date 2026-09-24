#!/usr/bin/env bash

# nu-lint exits 0 whatever it finds, so the gate is its output.
set -euo pipefail

nu_lint=$(.github/scripts/nix-tool.sh nu-lint)/bin/nu-lint
out=$(git ls-files '*.nu' | xargs "$nu_lint" --format compact)
printf '%s\n' "$out"
case "$out" in
  *"No violations found"*) ;;
  *) exit 1 ;;
esac
