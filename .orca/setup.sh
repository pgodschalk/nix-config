#!/bin/sh
# Prepares a new Orca worktree: trusts its mise.toml and
# mise.local.toml, installs what they pin, then runs the repository's
# worktree:setup task if it defines one. Orca runs it from orca.yaml as
# `sh "$ORCA_ROOT_PATH/.orca/setup.sh"`.
set -eu

# Without the login shell's XDG variables mise looks for its trust
# store in ~/.local/state.
: "${XDG_CACHE_HOME:=$HOME/Library/Caches}"
: "${XDG_CONFIG_HOME:=$HOME/Library/Application Support}"
: "${XDG_DATA_HOME:=$HOME/Library/Application Support}"
: "${XDG_STATE_HOME:=$HOME/Library/Application Support}"
export XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME
PATH="/etc/profiles/per-user/${USER:-patrick}/bin:$PATH"

cd "${ORCA_WORKTREE_PATH:-.}"

# A worktree is a new path, so mise trusts none of its files yet.
for config in mise.toml mise.local.toml; do
  if [ -f "$config" ]; then
    mise trust --quiet "$config"
  fi
done
mise install
if mise tasks info worktree:setup >/dev/null 2>&1; then
  mise run worktree:setup
fi
