# shellcheck shell=bash

settings=@settings@
run @jq@ --from-file @filter@ "$settings" >"$settings.tmp"
run mv -f "$settings.tmp" "$settings"
