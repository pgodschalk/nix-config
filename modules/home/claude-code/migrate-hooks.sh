# shellcheck shell=bash

# A subshell keeps these variables out of the rest of the activation
# script.
(
  settings=@settings@
  state=@state@
  if [ ! -e "$state" ] && [ -s "$settings" ]; then
    if @jq@ --from-file @filter@ "$settings" >"$settings.tmp"; then
      run mv -f "$settings.tmp" "$settings"
    else
      echo "claude-code: $settings not migrated" >&2
    fi
    rm -f "$settings.tmp"
  fi
)
