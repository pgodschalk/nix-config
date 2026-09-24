# shellcheck shell=bash
#
# Usage: chain-local HOOK [ARG...]
#
# Hands a repository's own hook control once the global one has run, so
# the global core.hooksPath does not silently disable it.
hook="$1"
shift

# `--git-common-dir`: hooks live in the common directory, which in a
# linked worktree is not `--git-dir`. Not `--git-path hooks` either,
# which resolves through core.hooksPath to the global directory, so the
# hook would exec itself forever.
common_dir="$(@git@ rev-parse --git-common-dir)"

local_hook="$common_dir/hooks/$hook"
if [ -x "$local_hook" ]; then
  exec "$local_hook" "$@"
fi

# `git lfs install` cannot write its hooks into the read-only global
# directory, so a repository using LFS gets them here. Without pre-push
# the pointers are pushed and the objects are not.
case "$hook" in
  post-checkout | post-commit | post-merge | pre-push)
    if [ -d "$common_dir/lfs" ]; then
      exec @gitLfs@ "$hook" "$@"
    fi
    ;;
esac

exit 0
