# Hooks and commands for coding agents: check timings, rules drafted
# from repeated failures, and edit, search and CI-wait commands. Two
# binaries from one release: `jouet`, and `joue`, which runs a routine.
#
# Linux takes the static musl builds, which need no patching.
# x86_64-darwin is absent because upstream publishes no such asset.
{ lib, callPackage }:

let
  # @VERSION https://github.com/jdx/jouet/releases
  version = "0.0.5";
in
callPackage ./lib/release-binary.nix { } {
  pname = "jouet";
  inherit version;

  # Hashes from the release's SHA256SUMS.
  assets = {
    aarch64-darwin = {
      url = "https://github.com/jdx/jouet/releases/download/v${version}/jouet-aarch64-apple-darwin.tar.gz";
      hash = "sha256-g+4f2WCK1RXb3UmXH+uX6ZvICqBpiACUlR0AycSbhJs=";
    };
    aarch64-linux = {
      url = "https://github.com/jdx/jouet/releases/download/v${version}/jouet-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-dVUBovwBcoVwq/Af/IDOHH4kPLDgO3TAndnl005QJrc=";
    };
    x86_64-linux = {
      url = "https://github.com/jdx/jouet/releases/download/v${version}/jouet-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-2u5BH9O94nH4VATLnXrgSF28X27ZbpndIB5oLTLAszE=";
    };
  };

  binaries = [
    "jouet"
    "joue"
  ];

  postInstall = ./jouet/post-install.sh;

  meta = {
    description = "Wind-up tools for coding agents";
    homepage = "https://jouet.jdx.dev";
    license = lib.licenses.mit;
  };
}
