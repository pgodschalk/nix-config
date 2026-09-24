# shellcheck shell=bash

# A running Claude Desktop may write its in-memory settings back over
# this file, discarding the merge.
if /usr/bin/pgrep -xq Claude; then
  echo "claude-desktop: Claude is running; it may overwrite these" >&2
  echo "claude-desktop: settings. quit it and switch again if they do" >&2
  echo "claude-desktop: not stick." >&2
fi

run @mergeJson@ claude-desktop @file@ @declared@ @state@
