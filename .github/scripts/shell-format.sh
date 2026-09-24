#!/usr/bin/env bash

set -euo pipefail

tmp=${RUNNER_TEMP:-$(mktemp -d)}
tag=$(curl --fail --silent --show-error --location \
  https://api.github.com/repos/mvdan/sh/releases/latest \
  | jq -r .tag_name)
curl --fail --silent --show-error --location --output "$tmp/shfmt" \
  "https://github.com/mvdan/sh/releases/download/$tag/shfmt_${tag}_linux_amd64"
chmod +x "$tmp/shfmt"

git ls-files '*.sh' \
  | xargs "$tmp/shfmt" --indent 2 --binary-next-line --case-indent --diff
