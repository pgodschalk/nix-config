# shellcheck shell=bash

if [ ! -x @cli@ ]; then
  echo "orca: Orca is not installed at @app@" >&2
  echo "orca: it is a manual install -- see onorca.dev/download" >&2
  exit 127
fi

exec @cli@ "$@"
