#!/bin/sh
# Stops the daemons of the worktree's own pitchfork.local.toml before
# Orca archives or removes the worktree, so none keeps serving a deleted
# directory or holding its port. A repository that must keep one (a
# daemon shared by every worktree) defines a worktree:archive task,
# which then runs instead. Orca runs it from orca.yaml as
# `sh "$ORCA_ROOT_PATH/.orca/archive.sh"`.
set -eu

# pitchfork keeps its state under XDG_STATE_HOME, mise its trust store.
: "${XDG_CACHE_HOME:=$HOME/Library/Caches}"
: "${XDG_CONFIG_HOME:=$HOME/Library/Application Support}"
: "${XDG_DATA_HOME:=$HOME/Library/Application Support}"
: "${XDG_STATE_HOME:=$HOME/Library/Application Support}"
export XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME
PATH="/etc/profiles/per-user/${USER:-patrick}/bin:$PATH"

cd "${ORCA_WORKTREE_PATH:-.}"

if mise tasks info worktree:archive >/dev/null 2>&1; then
  exec mise run worktree:archive
fi

# pitchfork resolves a daemon name against the nearest
# pitchfork.local.toml, so without the worktree's own copy this would
# stop the primary checkout's daemons.
if [ -f pitchfork.local.toml ]; then
  sed -n 's/^\[daemons\.\([A-Za-z0-9_-]*\)\]$/\1/p' pitchfork.local.toml | while read -r daemon; do
    pitchfork stop "$daemon" || true
    pitchfork clean --daemon "$daemon" || true
  done
fi
