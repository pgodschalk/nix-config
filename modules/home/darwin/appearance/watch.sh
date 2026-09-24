# shellcheck shell=bash

# A resident loop rather than a repeating one-shot: launchd throttles a
# job that exits to roughly one launch per ten seconds, so
# StartInterval=2 would quietly become 10.
while :; do
  @switchScript@ || true
  /bin/sleep 2
done
