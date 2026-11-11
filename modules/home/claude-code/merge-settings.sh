# shellcheck shell=bash

settings=@settings@
marketplace=@marketplace@
run mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' >"$settings"
run @jq@ \
  --arg path "$marketplace" \
  --arg statusline @statusline@ \
  --arg mdlint @mdlint@ \
  --arg vcsguard @vcsguard@ \
  --argjson plugins @plugins@ \
  --from-file @filter@ \
  "$settings" >"$settings.tmp"
run mv -f "$settings.tmp" "$settings"
