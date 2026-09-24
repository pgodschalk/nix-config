# shellcheck shell=bash

# Claude Code drops this stub into ~/Applications on every startup.
# Deleting it is futile, since it is recreated; the Finder `hidden`
# flag leaves the bundle in place, so Claude Code sees it already
# exists, the flag survives, and the claude-cli: binding keeps working.
ccUrlHandler="$HOME/Applications/Claude Code URL Handler.app"

if [ -d "$ccUrlHandler" ] \
  && ! /usr/bin/stat -f '%Sf' "$ccUrlHandler" 2>/dev/null | grep -q hidden; then
  run /usr/bin/chflags hidden "$ccUrlHandler"
fi
