#!/usr/bin/env bash

# Validates each file matching the globs given as arguments against the
# schema it declares itself -- a `# yaml-language-server: $schema=`
# line in YAML, a `$schema` key in JSON -- which is what the editor's
# language servers validate against. A file declaring none is skipped,
# there being nothing to check it against.
#
# .jsonc is deliberately not covered: check-jsonschema parses json,
# toml and yaml only, and a comment makes it fail to parse the file.
set -euo pipefail

check_jsonschema=$(.github/scripts/nix-tool.sh check-jsonschema)
status=0

while read -r file; do
  case "$file" in
    *.yaml | *.yml)
      pattern='s/^#[[:space:]]*yaml-language-server:[[:space:]]*[$]schema=\([^[:space:]]*\).*/\1/p'
      ;;
    *)
      pattern='s/.*"[$]schema"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
      ;;
  esac

  schema=$(sed -n "$pattern" "$file" | head -1)
  if [ -z "$schema" ]; then
    echo "skipped $file, which declares no schema"
    continue
  fi

  # A relative schema is relative to the file, as the editor reads it.
  case "$schema" in
    *://*) ;;
    *) schema="$(dirname "$file")/$schema" ;;
  esac

  "$check_jsonschema" --schemafile "$schema" "$file" </dev/null || status=1
done < <(git ls-files "$@")

exit "$status"
