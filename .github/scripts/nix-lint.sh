#!/usr/bin/env bash

# nixf-tidy is the linter behind nixd's diagnostics, so this reports
# exactly what the editor reports. It reads one file on stdin and exits
# 0 whatever it finds, so the gate is its output.
set -euo pipefail

tidy=$(.github/scripts/nix-tool.sh nixf)/bin/nixf-tidy
status=0

while read -r file; do
  diagnostics=$("$tidy" <"$file")
  [ "$diagnostics" = "[]" ] && continue

  # nixf counts lines and columns from zero.
  printf '%s\n' "$diagnostics" \
    | jq --raw-output --arg file "$file" \
      '.[] | "\($file):\(.range.lCur.line + 1):\(.range.lCur.column + 1): \(.message) [\(.sname)]"'
  status=1
done < <(git ls-files '*.nix')

exit "$status"
