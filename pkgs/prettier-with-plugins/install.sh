# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
runHook preInstall

# The node_modules tree beside a link to prettier is load-bearing: each
# plugin does `import "prettier"` at run time, and Node resolves that by
# walking up from the plugin's own file. Unpacked anywhere else they
# fail with "Cannot find package 'prettier'".
mkdir -p "$out/lib/node_modules"
ln -s @prettierModule@ "$out/lib/node_modules/prettier"

# One link per plugin tarball, named for its package, scoped ones one
# directory down.
while read -r link; do
  name=${link#./}
  mkdir -p "$out/lib/node_modules/$name"
  tar xzf "@plugins@/$name" -C "$out/lib/node_modules/$name" \
    --strip-components=1
done < <(cd @plugins@ && find . -type l)

# Each --plugin names the entry file, not the directory: Prettier loads
# plugins as ES modules, and an ESM directory import fails with
# "Directory import ... is not supported".
#
# AWK runs prettier twice, because the plugin converges rather than
# oscillating -- pass 1 reformats and pass 2 settles a comment -- so one
# save lands on the fixed point. Two files, because makeWrapper can add
# flags to one invocation and cannot pipe two together.
#
# `pipefail` is load-bearing: without it a failure in the first pass is
# masked by a successful second one, and the editor replaces the buffer
# with whatever the second pass made of a truncated input.
mkdir -p "$out/bin" "$out/libexec"
makeWrapper @prettier@ "$out/libexec/prettier-awk-once" \
  --add-flags "--plugin=$out/lib/node_modules/prettier-plugin-awk/out/index.js \
  --parser=awk-parse"

printf '#!%s\nset -euo pipefail\n%s "$@" | %s "$@"\n' \
  @shell@ \
  "$out/libexec/prettier-awk-once" \
  "$out/libexec/prettier-awk-once" \
  >"$out/bin/prettier-awk"
chmod +x "$out/bin/prettier-awk"

makeWrapper @prettier@ "$out/bin/prettier-ini" \
  --add-flags "--plugin=$out/lib/node_modules/prettier-plugin-ini/src/plugin.js \
  --parser=ini"

makeWrapper @prettier@ "$out/bin/prettier-jinja" \
  --add-flags \
  "--plugin=$out/lib/node_modules/prettier-plugin-jinja-template/lib/index.js \
  --parser=jinja-template"

# The Gherkin plugin is ESM with an `exports` map and no `main`, so the
# entry file comes from `exports["."]`. The Cucumber language server
# advertises formatting and then does nothing.
makeWrapper @prettier@ "$out/bin/prettier-gherkin" \
  --add-flags "--plugin=$out/lib/node_modules/prettier-plugin-gherkin/dist/index.js \
  --parser=gherkin"

# Astro, likewise ESM with an `exports` map and no `main`.
makeWrapper @prettier@ "$out/bin/prettier-astro" \
  --add-flags "--plugin=$out/lib/node_modules/prettier-plugin-astro/dist/index.js \
  --parser=astro"

makeWrapper @prettier@ "$out/bin/prettier-json5" --add-flags "--parser=json5"

# `--prose-wrap=always` is the load-bearing flag: Prettier's default
# preserves, and oxfmt has no prose-wrap or print-width option at all,
# so without it a long paragraph is not reflowed. The width matches the
# Markdown wrap guide in modules/home/darwin/zed.nix.
makeWrapper @prettier@ "$out/bin/prettier-md" \
  --add-flags "--parser=markdown --prose-wrap=always --print-width=80"

runHook postInstall
