# shellcheck shell=bash

if [ ! -x @cli@ ]; then
  echo "rex: Rex Beta is not installed at @app@" >&2
  echo "rex: it is a manual install -- see superlogical.com/rex" >&2
  exit 127
fi

exec @cli@ "$@"
