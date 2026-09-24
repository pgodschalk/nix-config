# shellcheck shell=bash

# One bare word with no quoting on the caller's side, because
# Terminal.app tokenises its "Run command" field itself and mangles
# `/bin/zsh -l -i -c 'exec nu'` into `zsh:1: unmatched '`.
exec /bin/zsh -l -i -c 'exec @inner@'
