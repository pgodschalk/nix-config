#!/usr/bin/env bash

# Ghostty's shell integration does not survive the trip through zsh: it
# prepends its own directory to XDG_DATA_DIRS, where Nushell looks for
# the autoload script (`nushell/vendor/autoload/ghostty.nu`), and
# /etc/zshenv runs nix-darwin's set-environment, which overwrites that
# variable rather than appending. The GHOSTTY_* variables are untouched.
#
# Autoloading only defines the module. Ghostty activates it by appending
# `--execute 'use ghostty *'` to its command, which `zsh -c` drops as
# positional parameters.
if [ -n "${GHOSTTY_SHELL_INTEGRATION_XDG_DIR:-}" ]; then
  export XDG_DATA_DIRS="$GHOSTTY_SHELL_INTEGRATION_XDG_DIR:${XDG_DATA_DIRS:-}"
  exec nu --execute 'use ghostty *'
fi

exec nu
