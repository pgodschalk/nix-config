# shellcheck shell=bash

set -u
base=$1
out=$2
umask 077
token=$(OP_ACCOUNT=my.1password.eu @onePassword@/bin/op read \
  "op://Private/bhmimlus3gz3xfqr4xnbobbdje/gh-actions-language-server" \
  2>/dev/null </dev/null || true)

if [ -n "$token" ]; then
  @jq@/bin/jq --arg t "$token" \
    '.lsp["gh-actions-language-server"].settings.sessionToken = $t' \
    "$base" >"$out.tmp"
else
  echo "zed: no GitHub Actions token available; writing settings without it" >&2
  @jq@/bin/jq . "$base" >"$out.tmp"
fi

mv -f "$out.tmp" "$out"
chmod 600 "$out"
