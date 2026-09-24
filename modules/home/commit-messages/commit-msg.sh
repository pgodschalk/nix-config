#!/bin/sh
#
# Unlike prepare-commit-msg this runs for `git commit -m` too, and Zed's
# commits reach it, which is the only place the rules are enforced for a
# GUI commit.
@selectProfile@
@commitlintConfigFor@

# config and profile are assigned by the fragments above, which are
# opaque placeholders to the checker. Written without their `@`, since
# replaceVars substitutes inside comments too.
# shellcheck disable=SC2154
@commitlint@ --config "$config" --edit "$1" || exit 1

@chainLocal@
