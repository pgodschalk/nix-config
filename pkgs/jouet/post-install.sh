# shellcheck shell=bash

# `$out` and `$TMPDIR` are set by Nix.
# shellcheck disable=SC2154

# The skill `jouet setup` installs, without the hash footer setup adds
# to recognise its own copy. jouet records each run under its state
# dir, which defaults to the unwritable build HOME.
mkdir -p "$out/share/jouet/skills/jouet-init"
HOME="$TMPDIR" XDG_STATE_HOME="$TMPDIR/state" \
  "$out/bin/jouet" skill --init --format claude \
  >"$out/share/jouet/skills/jouet-init/SKILL.md"
