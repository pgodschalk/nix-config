# shellcheck shell=bash

# One NAME=VALUE per line; a value may hold `=` but no newline.
while IFS= read -r line; do
  /bin/launchctl setenv "${line%%=*}" "${line#*=}"
done <@envFile@
