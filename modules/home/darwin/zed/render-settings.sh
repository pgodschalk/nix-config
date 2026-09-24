# shellcheck shell=bash

set -euo pipefail
base=$1
out=$2
umask 077
mkdir -p "$(dirname "$out")"

token=$(OP_ACCOUNT=my.1password.eu @onePassword@/bin/op read \
  "op://Private/bhmimlus3gz3xfqr4xnbobbdje/gh-actions-language-server" \
  2>/dev/null </dev/null || true)

# A switch while 1Password is locked keeps the token already rendered
# rather than dropping it until the next switch.
if [ -z "$token" ] && [ -f "$out" ]; then
  token=$(@jq@/bin/jq --raw-output \
    '.lsp["gh-actions-language-server"].initialization_options.sessionToken // empty' \
    "$out" 2>/dev/null || true)
fi

if [ -n "$token" ]; then
  ZED_GH_TOKEN=$token @jq@/bin/jq --from-file @spliceToken@ "$base" >"$out.tmp"
else
  echo "zed: no GitHub Actions token available; writing settings without it" >&2
  @jq@/bin/jq . "$base" >"$out.tmp"
fi

mv -f "$out.tmp" "$out"
chmod 600 "$out"
