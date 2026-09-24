# shellcheck shell=bash

xcodeApp=/Applications/Xcode.app
if [ -d "$xcodeApp" ]; then
  if [ "$(/usr/bin/xcode-select -p 2>/dev/null)" \
    != "$xcodeApp/Contents/Developer" ]; then
    printf >&2 'selecting Xcode as the developer directory...\n'
    /usr/bin/xcode-select --switch "$xcodeApp/Contents/Developer" \
      || true
  fi

  # On a fresh machine this pulls a multi-gigabyte asset from Apple
  # during the switch.
  if ! /usr/bin/xcodebuild -showComponent MetalToolchain -json \
    2>/dev/null | /usr/bin/grep -q '"status" *: *"installed"'; then
    printf >&2 'downloading the Metal toolchain (this is large)...\n'
    /usr/bin/xcodebuild -downloadComponent MetalToolchain \
      >/dev/null 2>&1 \
      || printf >&2 'warning: could not download the Metal toolchain\n'
  fi

  # -checkFirstLaunchStatus exits non-zero for an outstanding licence
  # and for pending first-launch tasks alike, so it guards both.
  if ! /usr/bin/xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    printf >&2 \
      'accepting the Xcode licence and running first-launch tasks...\n'
    /usr/bin/xcodebuild -license accept >/dev/null 2>&1 \
      || printf >&2 'warning: could not accept the Xcode licence\n'
    /usr/bin/xcodebuild -runFirstLaunch >/dev/null 2>&1 \
      || printf >&2 'warning: xcodebuild -runFirstLaunch failed\n'
  fi
fi
