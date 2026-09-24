# shellcheck shell=bash

set -eu
file=${1:-}
dir=${file:-$PWD}
[ -d "$dir" ] || dir=$(dirname "$dir")
# Absolute, or the walk stops at `.`, which is its own dirname.
case $dir in
  /*) ;;
  *) dir=$PWD/$dir ;;
esac
found=

while [ "$dir" != "/" ] && [ -n "$dir" ]; do
  if [ -e "$dir/.clang-format" ]; then
    found=1
    break
  fi

  dir=$(dirname "$dir")
done

set --
[ -n "$file" ] && set -- --assume-filename="$file"

if [ -n "$found" ]; then
  exec /usr/bin/xcrun clang-format --style=file "$@"
else
  exec /usr/bin/xcrun clang-format \
    --style='{BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 80}' "$@"
fi
