# shellcheck shell=bash

# `$out` is the build's output path, set by Nix.
# shellcheck disable=SC2154
wrapProgram "$out/bin/jdtls" \
  --set-default JAVA_HOME @jdk@ \
  --run "mkdir -p @configArea@" \
  --add-flags "--jvm-arg=-Dosgi.configuration.area=@configArea@"
