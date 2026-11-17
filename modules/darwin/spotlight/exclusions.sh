# shellcheck shell=bash

# A subshell, so a refusal ends this block alone and not the activation
# it is part of.
(
  plist=/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist
  buddy=/usr/libexec/PlistBuddy

  # PlistBuddy exits 0 on a file it cannot open, so readability comes
  # from plutil and each write is confirmed by reading the list back.
  printf >&2 'configuring Spotlight exclusions...\n'
  if ! /usr/bin/plutil -lint "$plist" >/dev/null 2>&1; then
    printf >&2 'warning: cannot read %s; Spotlight exclusions unchanged\n' "$plist"
    exit 0
  fi

  listed() {
    # PlistBuddy prints each element indented by four spaces. The
    # Search Privacy pane may record the Data volume's own path.
    grep --quiet --line-regexp --fixed-strings \
      --regexp="    $1" --regexp="    /System/Volumes/Data$1" <<<"$2"
  }

  if ! current=$("$buddy" -c 'Print :Exclusions' "$plist" 2>/dev/null); then
    "$buddy" -c 'Add :Exclusions array' "$plist"
    current=
  fi

  exclusions=(@exclusions@)
  added=()
  for path in "${exclusions[@]}"; do
    if [ -e "$path" ] && ! listed "$path" "$current"; then
      "$buddy" -c "Add :Exclusions: string $path" "$plist"
      added+=("$path")
    fi
  done
  [ "${#added[@]}" -gt 0 ] || exit 0

  current=$("$buddy" -c 'Print :Exclusions' "$plist" 2>/dev/null) || exit 1
  for path in "${added[@]}"; do
    listed "$path" "$current" || exit 1
  done
  printf >&2 'Spotlight applies the new exclusions after a restart\n'
) || printf >&2 'warning: Spotlight exclusions not updated\n'
