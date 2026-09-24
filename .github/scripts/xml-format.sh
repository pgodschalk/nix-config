#!/usr/bin/env bash

# xmllint has no check mode, so its output is compared against the file.
# libxml2-utils is not in the runner image.
set -euo pipefail

sudo apt-get update
sudo apt-get install --yes libxml2-utils

status=0

for f in $(git ls-files '*.xml' '*.svg'); do
  xmllint --format "$f" | diff -u "$f" - || status=1
done

exit "$status"
