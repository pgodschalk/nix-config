# shellcheck shell=bash
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
cp -r @voltagent@/tools/subagent-catalog "$out"
chmod -R u+w "$out"

# The quoted `$HOME` and `~` are the literal text being searched for, so
# SC2016 and SC2088 are exactly backwards here: expanding either would
# look for a path upstream never wrote.
# shellcheck disable=SC2016
substituteInPlace "$out/config.sh" \
  --replace-fail '"$HOME/.claude/cache/subagent-catalog.md"' '"@cacheFile@"'

# A stray .md in a commands directory would itself become a
# `/subagent-catalog:README`.
rm "$out/README.md"

# Named individually, and `--replace-fail`, so a new or renamed command
# upstream fails the build rather than being installed with a path that
# does not resolve.
for f in fetch invalidate list search; do
  # shellcheck disable=SC2088
  substituteInPlace "$out/$f.md" \
    --replace-fail '~/.claude/commands/subagent-catalog/config.sh' '@configFile@'
done
