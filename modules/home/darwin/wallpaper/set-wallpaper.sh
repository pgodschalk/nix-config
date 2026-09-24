# shellcheck shell=bash

wpSrc=@systemCatalog@
wpDest=@catalog@

if [ ! -r "$wpSrc" ]; then
  printf >&2 'warning: %s is missing; skipping the Golden Gate solar\n' "$wpSrc"
  printf >&2 'wallpaper catalog\n'
else
  wpTmp=$(mktemp "${TMPDIR:-/tmp}/entries.XXXXXX")

  if @jq@/bin/jq --arg gg @goldenGateId@ \
    --from-file @solarFilter@ "$wpSrc" >"$wpTmp" \
    && /usr/bin/plutil -convert json -o /dev/null "$wpTmp"; then
    # Only replace and restart the agent when something actually
    # changed, so an unrelated switch does not make the wallpaper
    # flicker.
    if ! cmp -s "$wpTmp" "$wpDest" 2>/dev/null; then
      run mkdir -p @customDir@
      run cp "$wpTmp" "$wpDest"
      run /usr/bin/killall WallpaperAgent WallpaperAerialsExtension 2>/dev/null || true
    fi
  else
    # Apple changed the catalog's shape; leave whatever is there alone
    # rather than writing something the wallpaper engine cannot parse.
    printf >&2 'warning: could not build the Golden Gate solar wallpaper\n'
    printf >&2 'catalog; leaving it unchanged\n'
  fi

  rm -f "$wpTmp"
fi
