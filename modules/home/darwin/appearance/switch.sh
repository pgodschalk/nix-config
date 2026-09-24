# shellcheck shell=bash

# mode is read by the fragments below, which are opaque placeholders to
# the checker. Written without its `@`, since replaceVars substitutes
# inside comments too.
# shellcheck disable=SC2034
mode=light

if /usr/bin/defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  mode=dark
fi

changed=0
@applyLinks@
@applyClaudeTheme@

if [ "$changed" = 1 ]; then
  # Helix reloads its configuration on SIGUSR1. glab needs nothing: it
  # reads the style per invocation.
  /usr/bin/pkill -USR1 -x hx || true
fi
