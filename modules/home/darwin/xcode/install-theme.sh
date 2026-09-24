# shellcheck shell=bash

# Spliced into install-themes.sh once per file.
if [ -f @src@ ]; then
  run rm -f @dst@
  run install -m 644 @src@ @dst@
else
  echo "xcode: @name@ missing from dracula-pro-extras" >&2
fi
