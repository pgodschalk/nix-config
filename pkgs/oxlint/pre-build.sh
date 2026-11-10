# shellcheck shell=bash

# `napiCliPatch` is the patch's store path, set by the derivation.
# shellcheck disable=SC2154
for cli in node_modules/.pnpm/@napi-rs+cli@*/node_modules/@napi-rs/cli/dist/cli.js; do
  patch --batch --forward "$cli" "$napiCliPatch"
done
