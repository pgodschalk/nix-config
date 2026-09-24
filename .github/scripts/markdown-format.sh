#!/usr/bin/env bash

# The flags the editor's `prettier-md` wrapper passes, so a file saved
# in Zed and a file checked here are held to the same rules.
set -euo pipefail

git ls-files '*.md' \
  | xargs npx --yes prettier --check \
    --parser=markdown --prose-wrap=always --print-width=80
