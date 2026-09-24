# shellcheck shell=bash

# `${*: -1}` rather than `${@: -1}`: assigning `$@` to a scalar is an
# array-to-string assignment (SC2124), and with one element there is
# nothing for `$*` to join.
file="${*: -1}"
editor="${VISUAL:-${EDITOR:-vi}}"

# jj uses the same editor for `jj config edit` and friends.
case "$file" in
  *.jjdescription) ;;
  *) exec $editor "$@" ;;
esac

profile="$(@git@ config --get commitmsg.profile 2>/dev/null || true)"

if [ -z "$profile" ]; then
  # Substituted whole rather than as branches inside a `case`, for the
  # reason draft.sh records. No default branch: an unmatched directory
  # leaves $profile empty, which is the global profile.
  @directoryCase@
fi

message() { grep -v '^JJ:' "$file" | grep -v '^[[:space:]]*$'; }

if ! message >/dev/null && [ -t 2 ]; then
  target="$(sed -n 's/^JJ: Change ID: //p' "$file" | head -1)"
  current="$(@jj@ log --ignore-working-copy --no-graph --revision @ \
    --template 'change_id.short(8)' 2>/dev/null)"

  if [ -n "$target" ] && [ "$target" = "$current" ]; then
    if draft="$(@draftScript@ jj "$profile")"; then
      {
        printf '%s\n' "$draft"
        cat "$file"
      } >"$file.lumen"
      mv "$file.lumen" "$file"
    fi
  fi
fi

$editor "$file" || exit $?

# An empty description is jj's normal state for a change in progress.
if message >/dev/null; then
  @commitlintConfigFor@
  # On stdin rather than with --edit, which looks for a git root and
  # finds none in a secondary workspace or a non-colocated repository.
  #
  # config is assigned by the fragment above, which is an opaque
  # placeholder to the checker. Written without its `@`, since
  # replaceVars substitutes inside comments too.
  # shellcheck disable=SC2154
  grep -v '^JJ:' "$file" | @commitlint@ --config "$config"
fi
