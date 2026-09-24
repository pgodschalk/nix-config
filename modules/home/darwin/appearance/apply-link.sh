# shellcheck shell=bash

# Spliced into switch.sh once per entry in `links`, which assigns `mode`
# and reads `changed`.
# shellcheck disable=SC2034,SC2154
want=@light@
[ "$mode" = dark ] && want=@dark@
current=$(/usr/bin/readlink @path@ 2>/dev/null || true)

if [ "$current" != "$want" ]; then
  /bin/mkdir -p @dir@
  /bin/ln -sfn "$want" @path@
  changed=1
fi
