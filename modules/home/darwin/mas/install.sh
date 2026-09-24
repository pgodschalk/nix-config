# shellcheck shell=bash

masInstalled=""
masListOk=1

# masInstalled is read by the fragment below, which is an opaque
# placeholder to the checker. Written without its `@`, since replaceVars
# substitutes inside comments too.
# shellcheck disable=SC2034
if ! masInstalled="$(@mas@ list 2>/dev/null)"; then
  echo "warning: 'mas list' failed; skipping Mac App Store installs" >&2
  masListOk=""
fi

masFailed=""

if [[ -n "$masListOk" ]]; then
  @installBlocks@
fi

if [[ -n "$masFailed" ]]; then
  echo "warning: these Mac App Store apps could not be installed:" >&2
  printf '%s' "$masFailed" >&2
  echo "  Check that you are signed in to the App Store and that each app" >&2
  echo "  is in your Purchased list, then run 'sudo -H darwin-rebuild" >&2
  echo "  switch' again." >&2
fi
