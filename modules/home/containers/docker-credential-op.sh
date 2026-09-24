# shellcheck shell=bash

set -euo pipefail
op=@op@

fail() {
  printf 'credentials not found in native keychain\n' >&2
  exit 1
}

case "${1:-}" in
  store | erase)
    cat >/dev/null
    exit 0
    ;;
  list)
    printf '{}\n'
    exit 0
    ;;
  get) : ;;
  *) fail ;;
esac

# `|| true` is load-bearing: clients send the registry with no trailing
# newline, so `read` returns non-zero having read it perfectly well, and
# `set -e` would kill the helper. The client then reports
# `exit status 1, out:` with an empty value, which looks like a
# credential failure rather than a shell bug.
read -r registry || true

# lookup.jq takes the registry and $PWD and emits the account, vault,
# item and field, one per line, or nothing when the registry is unknown
# or out of scope. Refusing is the right failure there -- the client
# reports an auth error rather than using a credential from the wrong
# context.
#
# One field per line rather than a tab-separated row, because tab is an
# IFS whitespace character: an empty field would collapse and shift
# every later one, and the helper would still exit 0 with the wrong
# item.
#
# The `. as $d` in that filter is load-bearing and jqfmt strips the
# comment that says so: the `|` in the second test rebinds `.` to $pwd,
# so `. + "/"` there would compare $PWD with itself and never match a
# subdirectory of a scoped registry.
fields=$(@jq@ --raw-output --arg r "$registry" --arg pwd "$PWD" \
  --from-file @lookupFilter@ @registries@) || fail

[ -n "$fields" ] || fail

{
  IFS= read -r account
  IFS= read -r vault
  IFS= read -r item
  IFS= read -r secret_field
} <<<"$fields"

username=$("$op" read --account "$account" \
  "op://$vault/$item/username" 2>/dev/null) || fail
secret=$("$op" read --account "$account" \
  "op://$vault/$item/$secret_field" 2>/dev/null) || fail

[ -n "$secret" ] || fail

# jq rather than printf, so a credential containing a quote or
# backslash cannot break the JSON the client is about to parse.
@jq@ --null-input \
  --arg s "$registry" \
  --arg u "$username" \
  --arg p "$secret" \
  --from-file @outputFilter@
