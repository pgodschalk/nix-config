# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

mkdir -p "$out/lib/resend-cli"
cp -R dist skills package.json "$out/lib/resend-cli/"

makeWrapper @bun@ "$out/bin/resend" \
  --add-flags "$out/lib/resend-cli/dist/cli.cjs"

# Only fish, which is the fallback modules/home/completions.nix reads.
# Generated at build time so it tracks the version.
mkdir -p "$out/share/fish/vendor_completions.d"
"$out/bin/resend" completion fish \
  >"$out/share/fish/vendor_completions.d/resend.fish"

runHook postInstall
