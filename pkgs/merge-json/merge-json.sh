# shellcheck shell=bash
#
# Usage: merge-json NAME FILE DECLARED STATE [STRATEGIES]
#
# Merges the DECLARED JSON into an app's own settings FILE, keeping the
# keys the app writes itself. STATE records the declaration, so what is
# dropped from it is taken back out of FILE on the next run.
# STRATEGIES names "replace" or "union" for a key at any depth, in
# the shape of DECLARED; every other key is deep-merged. They are
# recorded beside STATE, its .json suffix replaced by .strategies.json,
# so a key no longer declared is taken back by the strategy it had.
#
# A FILE that cannot be merged is left as it is, both states with it,
# and NAME is named in a warning: one app's broken file must not stop
# the rest of the activation.
name=$1
file=$2
declared=$3
state=$4
strategies=${5:-@empty@}
strategies_state=${state%.json}.strategies.json

input=$file
[ -s "$input" ] || input=@empty@
old=$state
[ -s "$old" ] || old=@empty@
old_strategies=$strategies_state
[ -s "$old_strategies" ] || old_strategies=@empty@

if ! jq empty "$input" 2>/dev/null; then
  echo "$name: $file is not valid JSON; not merged" >&2
  exit 0
fi

mkdir -p "$(dirname "$file")" "$(dirname "$state")"

if ! error=$(jq --slurp --slurpfile old "$old" --slurpfile new "$declared" \
  --slurpfile strategies "$strategies" \
  --slurpfile oldStrategies "$old_strategies" --from-file @filter@ "$input" \
  2>&1 >"$file.tmp"); then
  rm -f "$file.tmp"
  echo "$name: $file not merged: $error" >&2
  exit 0
fi

mv -f "$file.tmp" "$file"
cp -f "$declared" "$state"
cp -f "$strategies" "$strategies_state"
chmod 644 "$state" "$strategies_state"
