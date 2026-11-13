# shellcheck shell=bash

settings=@settings@
run mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' >"$settings"
run @jq@ --from-file @filter@ "$settings" >"$settings.tmp"
run mv -f "$settings.tmp" "$settings"
