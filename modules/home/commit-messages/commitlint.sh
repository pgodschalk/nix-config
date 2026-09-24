# shellcheck shell=bash

export NODE_PATH=@nodePath@
exec @bun@ --no-install @cli@ "$@"
