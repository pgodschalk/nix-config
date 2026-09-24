#!/usr/bin/env bash

# Format-checks the files matching the globs given as arguments. The
# configuration is the one the editor formats with, so a file saved in
# Zed and a file checked here are held to the same rules.
#
# `xargs -r`: given no paths, oxfmt checks the whole tree, Markdown
# included.
set -euo pipefail

oxfmt=$(.github/scripts/nix-tool.sh oxfmt)
git ls-files "$@" \
  | xargs -r "$oxfmt" --check -c modules/home/oxc/oxfmtrc.json
