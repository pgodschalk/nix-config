# Hooks and commands for coding agents: check timings, rules drafted
# from repeated failures, and edit, search and CI-wait commands. Two
# binaries from one release: `jouet`, and `joue`, which runs a routine.
#
# Linux takes the static musl builds, which need no patching.
# x86_64-darwin is absent because upstream publishes no such asset.
{ lib, callPackage }:

let
  # @VERSION https://github.com/jdx/jouet/releases
  version = "0.0.4";
in
callPackage ./lib/release-binary.nix { } {
  pname = "jouet";
  inherit version;

  # Hashes from the release's SHA256SUMS.
  assets = {
    aarch64-darwin = {
      url = "https://github.com/jdx/jouet/releases/download/v${version}/jouet-aarch64-apple-darwin.tar.gz";
      hash = "sha256-nWra+64YDv7Q3yfgG4BNnZ4oC3CYmWEvYjMfyS+uN4s=";
    };
    aarch64-linux = {
      url = "https://github.com/jdx/jouet/releases/download/v${version}/jouet-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-//YTziHzTUELkPT9nFrKfZ2wZ5eRQwx2/hZSwm0O7Ik=";
    };
    x86_64-linux = {
      url = "https://github.com/jdx/jouet/releases/download/v${version}/jouet-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-il72b3Gg+kcsSPjdEhNB8FN3/F2MMS3DChyGSSmbrF8=";
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
