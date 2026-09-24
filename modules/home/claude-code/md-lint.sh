#!/usr/bin/env bash
# A PostToolUse hook, handed a JSON event on stdin. Exit 2 feeds stderr
# back to the model, which is what gets the diagnostics fixed in the
# same turn; any other non-zero code reaches the user and not the model,
# so every real failure here exits 2.
#
# It checks rather than fixes: a file that changes under Claude between
# one edit and the next is how stale-context bugs start.
set -euo pipefail

if [ -z "${MARKDOWNLINT_CONFIG-}" ]; then
  echo "md-lint: MARKDOWNLINT_CONFIG is unset" >&2
  exit 2
fi

event=$(cat)
file=$(jq -r --from-file @filter@ <<<"$event") || exit 2

[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# docs/agents/ holds the per-repository files the engineering skills
# read, which agnix checks as agent files. The glossary beside them is
# formatted and linted the same way, but agnix has no rule for it. The
# leading slash lets a relative path match the same patterns.
case "/$file" in
  */CLAUDE.md | */CLAUDE.local.md | */AGENTS.md | */docs/agents/*.md)
    agnix=true
    ;;
  */CONTEXT.md | */CONTEXT-MAP.md)
    agnix=false
    ;;
  *) exit 0 ;;
esac

status=0
report=""

note() {
  report+="$1"$'\n'
  status=2
}

# Both linters load JavaScript configs they find beside the file and in
# its ancestors, and a hook runs outside the sandbox, so they see only a
# copy in a directory of its own. agnix reads nothing but .agnix.toml
# and stays on the original.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/md-lint.XXXXXX") || exit 2
trap 'rm -rf "$scratch"' EXIT
name=$(basename "$file")
cp -- "$file" "$scratch/$name" || exit 2
origin=$PWD
cd "$scratch" || exit 2

# --check prints only the path, so the report is the command to run.
if ! prettier-md --no-config --no-editorconfig --check "$name" \
  >/dev/null 2>&1; then
  note "prettier-md: $file is not formatted. Run:
  prettier-md --no-config --no-editorconfig --write $(printf '%q' "$file")"
fi

# One line per violation with the rule id, which is already the right
# report.
if ! out=$(markdownlint-cli2 --config "$MARKDOWNLINT_CONFIG" "$name" 2>&1); then
  note "markdownlint-cli2:
$out"
fi

# The agent agnix validates for comes from `tools` in .agnix.toml rather
# than `--target`, which it deprecates and warns about on every run.
if [ "$agnix" = true ] && ! out=$(cd "$origin" && agnix validate "$file" 2>&1); then
  note "agnix:
$out"
fi

if [ "$status" -ne 0 ]; then
  printf '%s\n' "$file fails its linters; fix these before continuing." >&2
  printf '%s' "$report" >&2
fi

exit "$status"
