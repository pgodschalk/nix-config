# shellcheck shell=bash

# Xcode's swift-format, defaulted to a 4-space indent. The injected
# configuration is a fallback, supplied only when no `.swift-format`
# exists at or above the file; `swift-format format -` finds one from
# the working directory even when reading stdin.
set -eu

dir=${1:-$PWD}
[ -d "$dir" ] || dir=$(dirname "$dir")
# Absolute, or the walk stops at `.`, which is its own dirname.
case $dir in
  /*) ;;
  *) dir=$PWD/$dir ;;
esac

found=

while [ "$dir" != "/" ] && [ -n "$dir" ]; do
  if [ -e "$dir/.swift-format" ]; then
    found=1
    break
  fi
  dir=$(dirname "$dir")
done

if [ -n "$found" ]; then
  exec /usr/bin/xcrun swift-format format -
else
  exec /usr/bin/xcrun swift-format format \
    --configuration '{"version":1,"indentation":{"spaces":4}}' -
fi
