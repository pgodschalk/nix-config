# shellcheck shell=bash

password="$(/usr/bin/security find-generic-password -s @serviceArg@ -w \
  2>/dev/null)" || password=""
username="$(/usr/bin/security find-generic-password -s @serviceArg@ \
  2>/dev/null \
  | /usr/bin/sed -n 's/^[[:space:]]*"acct"<blob>="\(.*\)"$/\1/p')" \
  || username=""

if [ -z "$password" ] || [ -z "$username" ]; then
  echo "cronometer-mcp-server: no credential in the login keychain under" \
    "service @service@." >&2
  echo "Add one with (-w takes no value, so it prompts and stays out of" \
    "history):" >&2
  echo "  security add-generic-password -U -a <cronometer email>" \
    "-s @service@ -w" >&2
  exit 1
fi

export CRONOMETER_USERNAME="$username" CRONOMETER_PASSWORD="$password"
exec @server@ "$@"
