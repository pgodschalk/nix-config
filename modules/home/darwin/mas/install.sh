# shellcheck shell=bash

masInstalled=""

# masInstalled is read by the fragment below, which is an opaque
# placeholder to the checker. Written without its `@`, since replaceVars
# substitutes inside comments too.
# shellcheck disable=SC2034
if ! masInstalled="$(@mas@ list 2>/dev/null)"; then
  echo "warning: 'mas list' failed; skipping Mac App Store installs" >&2
  masInstalled=""
fi

masFailed=""

@installBlocks@

if [[ -n "$masFailed" ]]; then
  echo "warning: these Mac App Store apps could not be installed:" >&2
  printf '%s' "$masFailed" >&2
  echo "  Check that you are signed in to the App Store and that each app" >&2
  echo "  is in your Purchased list, then run 'darwin-rebuild switch'" >&2
  echo "  again." >&2
fi
