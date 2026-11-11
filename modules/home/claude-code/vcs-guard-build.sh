# shellcheck shell=bash
# Builds claude-vcs-guard, running its tests first: they need only a
# writable directory, since the trees they check are `.jj` and `.git`
# markers rather than real repositories.
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
set -euo pipefail

mkdir -p "$out/lib" "$out/bin"
cp @module@ "$out/lib/vcs_guard.py"

work=$(mktemp -d)
cp @module@ "$work/vcs_guard.py"
cp @tests@ "$work/test_vcs_guard.py"
(cd "$work" && @python@ -m unittest test_vcs_guard)

# -I keeps PYTHONPATH and user site-packages from the agent's
# environment out of a hook that runs on every Bash call. The tests
# above run without it, since it also drops the working directory
# their `import vcs_guard` relies on.
cat >"$out/bin/claude-vcs-guard" <<EOF
#!/bin/sh
exec @python@ -I $out/lib/vcs_guard.py "\$@"
EOF
chmod +x "$out/bin/claude-vcs-guard"
