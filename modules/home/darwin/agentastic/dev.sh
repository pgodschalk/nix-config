# shellcheck shell=bash

if [ ! -f @cli@ ]; then
  echo "dev: Agentastic.dev is not installed at @app@" >&2
  echo "dev: it is a manual install -- see agentastic.dev/download" >&2
  exit 127
fi

exec @bash@/bin/bash @cli@ "$@"
