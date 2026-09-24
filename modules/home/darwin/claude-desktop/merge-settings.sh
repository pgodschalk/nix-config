# shellcheck shell=bash

# A running Claude Desktop may write its in-memory settings back over
# this file, discarding the merge.
if /usr/bin/pgrep -xq Claude; then
  echo "claude-desktop: Claude is running; it may overwrite these" >&2
  echo "claude-desktop: settings. quit it and switch again if they do" >&2
  echo "claude-desktop: not stick." >&2
fi

file=@file@
run mkdir -p "$(dirname "$file")"
[ -s "$file" ] || echo '{}' >"$file"
run @jq@ --slurp '.[0] * .[1]' "$file" @declared@ >"$file.tmp"
run mv -f "$file.tmp" "$file"
