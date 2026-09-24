# shellcheck shell=bash

# base64 is the form `plutil -extract raw` prints, so the activation
# script can compare before writing. GNU base64 wraps at 76 columns and
# needs `-w0`; BSD base64 rejects that flag, hence the fallback.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
base64 -w0 <@recipe@ >"$out" 2>/dev/null \
  || base64 <@recipe@ | tr -d '\n' >"$out"
