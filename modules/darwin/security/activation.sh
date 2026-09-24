# shellcheck shell=bash

printf >&2 'configuring the system-wide settings authorization right...\n'
# Activation puts GNU coreutils ahead of /usr/bin, and GNU mktemp -t
# wants a template rather than BSD's bare prefix.
spRight=$(mktemp "${TMPDIR:-/tmp}/system-preferences.XXXXXX")

if /usr/bin/security authorizationdb read system.preferences >"$spRight" \
  2>/dev/null; then
  spShared=$(/usr/libexec/PlistBuddy -c 'Print :shared' "$spRight" \
    2>/dev/null || echo unknown)

  if [ "$spShared" != "false" ]; then
    if ! /usr/libexec/PlistBuddy -c 'Set :shared false' "$spRight" \
      && ! /usr/libexec/PlistBuddy -c 'Add :shared bool false' "$spRight"; then
      rm -f "$spRight"
      printf >&2 'error: could not edit the system.preferences right\n'
      exit 1
    fi
    if ! /usr/bin/security authorizationdb write system.preferences \
      <"$spRight"; then
      rm -f "$spRight"
      printf >&2 \
        'error: failed to write the system.preferences authorization right\n'
      exit 1
    fi
  fi
else
  printf >&2 'warning: could not read the system.preferences authorization'
  printf >&2 ' right; leaving it alone\n'
fi

rm -f "$spRight"
