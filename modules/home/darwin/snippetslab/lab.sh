# shellcheck shell=bash

# The wrapper is on PATH whether or not the app is installed, so the
# missing case is reported rather than left to a confusing "no such
# file". 127 is the shell's own "command not found".
if [ ! -x @lab@ ]; then
  echo "lab: SnippetsLab is not installed at /Applications/SnippetsLab.app" >&2
  exit 127
fi

exec @lab@ "$@"
