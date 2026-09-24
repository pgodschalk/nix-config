# shellcheck shell=bash

# The temp file keeps a `.yaml` suffix because helmfmt decides what to
# do from the extension, and `--files` is required or it looks for a
# chart directory.
set -eu
tmp=$(@coreutils@/bin/mktemp "${TMPDIR:-/tmp}/helmfmt.XXXXXX.yaml")
trap '@coreutils@/bin/rm -f "$tmp"' EXIT
@coreutils@/bin/cat >"$tmp"
@helmfmt@ --files --stdout "$tmp"
