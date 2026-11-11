#!/usr/bin/env bash

# Usage: format.sh FILE < CONTENT > FORMATTED
#
# Orca's format-on-save command: formats stdin as FILE's language with
# the flags CI's .github/scripts pass, and prints the result. A file of
# no listed language comes back unchanged.
set -euo pipefail

# Orca runs this outside a login shell.
bin=/etc/profiles/per-user/${USER:-patrick}/bin
file=$1
root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel)
# CI runs from the root, where prettier finds .prettierignore.
cd "$root"

case "$file" in
  *.nix) exec "$bin/nixfmt" --filename="$file" ;;
  *.sh)
    exec "$bin/shfmt" --indent 2 --binary-next-line --case-indent \
      --filename "$file"
    ;;
  *.md) exec "$bin/prettier-md" --stdin-filepath "$file" ;;
  *.json | *.jsonc | *.yaml | *.yml)
    exec "$bin/oxfmt" -c "$root/modules/home/oxc/oxfmtrc.json" \
      --stdin-filepath "$file"
    ;;
  *.toml) exec "$bin/tombi" format --stdin-filename "$file" - ;;
  *.nu) exec "$bin/nufmt" --stdin ;;
  *.py)
    exec "$bin/ruff" format --config "$root/ruff.toml" \
      --stdin-filename "$file" -
    ;;
  *.xml | *.svg) exec "$bin/xmllint" --format - ;;
  *) exec cat ;;
esac
