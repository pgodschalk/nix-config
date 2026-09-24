# shellcheck shell=bash
# Spliced into /etc/zshenv, inside an `if [[ -o rcs ]]` guard and after
# nix-darwin's own set-environment. /etc/zshenv is read before any user
# file, so no ~/.zshenv is needed to set ZDOTDIR.
if [ -n "$HOME" ]; then
  export ZDOTDIR="$HOME/Library/Application Support/zsh"
fi

# Stops Terminal.app writing ~/.zsh_sessions.
export SHELL_SESSIONS_DISABLE=1
