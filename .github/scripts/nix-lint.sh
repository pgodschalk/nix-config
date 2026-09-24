#!/usr/bin/env bash

# nixf-tidy is the linter behind nixd's diagnostics, so this reports
# exactly what the editor reports. It reads one file on stdin and exits
# 0 whatever it finds, so the gate is its output.
set -euo pipefail

tidy=$(.github/scripts/nix-tool.sh nixf)/bin/nixf-tidy
status=0

while read -r file; do
  # Without --variable-lookup nixf-tidy reports parse errors only, and
  # nixd's undefined and unused names go unchecked.
  diagnostics=$("$tidy" --variable-lookup <"$file")
  [ "$diagnostics" = "[]" ] && continue

  printf '%s\n' "$diagnostics" \
    | jq --raw-output --arg file "$file" --from-file .github/scripts/nix-lint.jq
  status=1
done < <(git ls-files '*.nix')

exit "$status"
