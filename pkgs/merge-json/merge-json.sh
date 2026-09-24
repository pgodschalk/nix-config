# shellcheck shell=bash
#
# Usage: merge-json NAME FILE DECLARED STATE
#
# Merges the DECLARED JSON into an app's own settings FILE, keeping the
# keys the app writes itself. STATE records the declaration, so a key
# dropped from it is removed from FILE on the next run.
name=$1
file=$2
declared=$3
state=$4

mkdir -p "$(dirname "$file")" "$(dirname "$state")"
[ -s "$file" ] || echo '{}' >"$file"

# One app's broken file must not stop the rest of the activation.
if ! jq -e . "$file" >/dev/null 2>&1; then
  echo "$name: $file is not valid JSON; not merged" >&2
  exit 0
fi

old=$state
[ -s "$old" ] || old=@empty@

jq --slurpfile old "$old" --slurpfile new "$declared" \
  --from-file @filter@ "$file" >"$file.tmp"
mv -f "$file.tmp" "$file"
cp -f "$declared" "$state"
chmod 644 "$state"
