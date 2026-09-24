#!/bin/sh
msg_file="$1"
source="${2-}"

# git's commit source: "message" (-m/-F), "template", "merge", "squash"
# or "commit" (-c/-C/--amend). Any of them means a message already
# exists; empty means a bare `git commit`.
if [ -n "$source" ]; then
  @chainLocal@
fi

# For clients that leave "$2" empty while still supplying a message, Zed
# among them.
#
# Everything from git's scissors line onwards is cut first: with
# commit.verbose git appends the staged diff below it, and those lines
# are not comments, so the test would see `diff --git a/...` and
# silently stop generating for every commit.
if sed '/^# -\{1,\} >8 -\{1,\}$/,$d' "$msg_file" 2>/dev/null \
  | grep -qvE '^(#|[[:space:]]*$)'; then
  @chainLocal@
fi

# Generating costs a network round trip and may raise a Touch ID prompt,
# so only ever from a terminal.
if [ ! -t 2 ]; then
  @chainLocal@
fi

@selectProfile@
# `git`, not lumen's auto-detection, which in a colocated repository can
# pick jj and draft from its working-copy commit rather than from what
# is staged.
#
# profile is assigned by the fragment above, which is an opaque
# placeholder to the checker. Written without its `@`, since replaceVars
# substitutes inside comments too.
# shellcheck disable=SC2154
if ! draft="$(@draftScript@ git "$profile")"; then
  @chainLocal@
fi

# Prepended, so the editor still shows git's status summary below.
printf '%s\n' "$draft" >"$msg_file.lumen"
cat "$msg_file" >>"$msg_file.lumen"
mv "$msg_file.lumen" "$msg_file"

@chainLocal@
