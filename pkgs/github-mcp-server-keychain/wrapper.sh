# shellcheck shell=bash

# github-mcp-server with its token read from the macOS login keychain.
#
# The server exits immediately without a credential, and the client
# reports that as a bare `-32000`, so the message below is the only
# thing that says what is actually wrong.
token="$(/usr/bin/security find-generic-password -s @serviceArg@ -w \
  2>/dev/null)" || token=""
if [ -z "$token" ]; then
  echo "github-mcp-server: no token in the login keychain under" \
    "service @service@." >&2
  echo "Add it with (-w takes no value, so it prompts and stays out" \
    "of history):" >&2
  echo "  security add-generic-password -U -a \"\$(id -un)\"" \
    "-s @service@ -w" >&2
  exit 1
fi
export GITHUB_PERSONAL_ACCESS_TOKEN="$token"
exec @server@ "$@"
