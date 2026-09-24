# shellcheck shell=bash

# A running Agentastic holds its settings in memory and writes them back
# over this file later, discarding whatever the merge added. Nothing
# here can stop that.
if /usr/bin/pgrep -xq Agentastic.dev; then
  echo "agentastic: Agentastic.dev is running; it may overwrite these" >&2
  echo "agentastic: settings. quit it and switch again if they do not" >&2
  echo "agentastic: stick." >&2
fi

settings=@settings@
run mkdir -p "$(dirname "$settings")"
[ -s "$settings" ] || echo '{}' >"$settings"
run @jq@ --slurp '.[0] * .[1]' "$settings" @declared@ >"$settings.tmp"
run mv -f "$settings.tmp" "$settings"
