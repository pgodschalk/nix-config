# shellcheck shell=bash

# `$out`, `$pname` and `$binary` are set by Nix.
# shellcheck disable=SC2154

# Usage telemetry is on unless DISABLE_TELEMETRY is 1 or true, and that
# variable cannot be set for the session: Claude Code reads the same
# name (see modules/home/telemetry.nix). The wrapper sets it for this
# CLI alone.
wrapProgram "$out/bin/$binary" --set DISABLE_TELEMETRY 1

# The guides and the CLI's own output tell the agent to run an unpinned
# copy through npx, past the wrapper above. Each is pointed at this
# build on PATH, and a form the rewrite does not match fails the build.
skill="$out/lib/$pname/skills/modern-web-guidance"
find "$skill" -type f \( -name '*.md' -o -name '*.mjs' \) -exec \
  sed --in-place --regexp-extended \
  's/npx( -y)? modern-web-guidance(@latest)?/modern-web-guidance/g' {} +

status=0
grep --recursive --line-number --extended-regexp \
  --include='*.md' --include='*.mjs' \
  'npx.{0,40}modern-web-guidance' "$skill" || status=$?
if [ "$status" -ne 1 ]; then
  echo "modern-web-guidance: an npx call is left (grep: $status)" >&2
  exit 1
fi
