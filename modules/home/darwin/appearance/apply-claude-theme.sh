# shellcheck shell=bash

# Spliced into switch.sh, which assigns `mode`. Guarded on the current
# value because that script runs every two seconds and Claude Code
# reloads settings.json whenever it changes, so an unconditional rewrite
# would poke a reload on every poll.
# shellcheck disable=SC2154
claudeSettings=@settings@
wantTheme=custom:alucard
[ "$mode" = dark ] && wantTheme=custom:dracula-pro

if [ -f "$claudeSettings" ]; then
  curTheme=$(@jq@ --raw-output '.theme // ""' "$claudeSettings" \
    2>/dev/null || true)

  if [ "$curTheme" != "$wantTheme" ]; then
    # $t is jq's own variable, bound by --arg: expanding it in the
    # shell would write `.theme = null`.
    # shellcheck disable=SC2016
    if @jq@ --arg t "$wantTheme" '.theme = $t' \
      "$claudeSettings" >"$claudeSettings.appearance.tmp" 2>/dev/null; then
      /bin/mv -f "$claudeSettings.appearance.tmp" "$claudeSettings"
    else
      /bin/rm -f "$claudeSettings.appearance.tmp"
    fi
  fi
fi
