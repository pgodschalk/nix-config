#!/usr/bin/env bash

# nu-lint 1.2 exits 0 whatever it finds and 1.3 does not, so the gate is
# both the exit status and the output. Capturing stderr as well keeps
# the diagnostics visible: without it a non-zero exit under `set -e`
# reports only the count.
set -euo pipefail

nu_lint=$(.github/scripts/nix-tool.sh nu-lint)/bin/nu-lint
status=0

out=$(git ls-files '*.nu' | xargs "$nu_lint" --format compact 2>&1) || status=1
printf '%s\n' "$out"

case "$out" in
  *"No violations found"*) ;;
  *) status=1 ;;
esac

exit "$status"
