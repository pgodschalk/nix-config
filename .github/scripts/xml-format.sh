#!/usr/bin/env bash

# xmllint has no check mode, so its output is compared against the file.
set -euo pipefail

xmllint=$(.github/scripts/nix-tool.sh libxml2.bin xmllint)
status=0

while read -r f; do
  "$xmllint" --format "$f" | diff -u "$f" - || status=1
done < <(git ls-files '*.xml' '*.svg')

exit "$status"
