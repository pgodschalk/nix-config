# shellcheck shell=bash

# Exactly one trailing newline, whatever the tool emits.
set -euo pipefail
out=$(@cmd@ "$@")
printf '%s\n' "$out"
