# shellcheck shell=bash

# $PPID is the ssh process; its argv must carry -T (an auth probe, not a
# git transport), and its parent must be claude.
args=$(/bin/ps -o args= -p "$PPID" 2>/dev/null) || exit 1

case " $args " in
  *" -T "*) ;;
  *) exit 1 ;;
esac

parent=$(/bin/ps -o ppid= -p "$PPID" 2>/dev/null | tr -d ' ') || exit 1
[ -n "$parent" ] || exit 1
comm=$(/bin/ps -o comm= -p "$parent" 2>/dev/null) || exit 1

case "${comm##*/}" in
  claude) exit 0 ;;
  *) exit 1 ;;
esac
