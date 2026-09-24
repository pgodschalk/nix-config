# shellcheck shell=bash

token="$(/usr/bin/security find-generic-password \
  -s @serviceArg@ -w 2>/dev/null)" || token=""

# A second lookup of the same item: without -w, find-generic-password
# prints its attributes, and the account is the `"acct"<blob>=` line.
username="$(/usr/bin/security find-generic-password -s @serviceArg@ \
  2>/dev/null \
  | /usr/bin/sed -n \
    's/^[[:space:]]*"acct"<blob>="\(.*\)"$/\1/p')" || username=""

user_args=()
if [ -n "$token" ] && [ -n "$username" ]; then
  export HUB_PAT_TOKEN="$token"
  user_args=(--username="$username")
else
  echo "dockerhub-mcp-server: no credential in the login keychain under" >&2
  echo "service @service@. Serving public Docker Hub content read-only." >&2
  echo "Add one with (-w takes no value, so it prompts and stays out of" >&2
  echo "history):" >&2
  echo "  security add-generic-password -U -a <docker hub username> \\" >&2
  echo "    -s @service@ -w" >&2
fi

exec @server@ --transport=stdio "${user_args[@]}" "$@"
