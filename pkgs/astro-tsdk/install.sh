# shellcheck shell=bash
#
# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
f=$(find -L @astroLanguageServer@/lib/node_modules \
  -type f -path '*/node_modules/typescript/lib/typescript.js' \
  | sort | head -1)

if [ -z "$f" ]; then
  echo "astro-language-server: no bundled TypeScript lib found" >&2
  exit 1
fi

ln -s "$(dirname "$f")" "$out"
