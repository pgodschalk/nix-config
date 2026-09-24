#!/usr/bin/env bash

# Format-checks the files matching the globs given as arguments. The
# configuration is the one the editor formats with, so a file saved in
# Zed and a file checked here are held to the same rules.
set -euo pipefail

git ls-files "$@" \
  | xargs npx --yes oxfmt --check -c modules/home/darwin/zed/oxfmtrc.json
