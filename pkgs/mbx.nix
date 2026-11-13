# mr-boxington: a build cache wrapping whichever Cargo and rustc are
# active, so it adds no toolchain of its own.
#
# `libexec/mbx/cargo` is the Cargo shim, the wrapper upstream's own
# flake builds. It sits in a directory of its own because mbx finds the
# real cargo by searching PATH past the shim: the directory goes ahead
# of the cargo it wraps, and replacing that cargo would leave none.
#
# Linux takes the static musl builds, which need no patching.
# x86_64-darwin is absent because upstream publishes no such asset.
{
  lib,
  callPackage,
  makeWrapper,
}:

let
  # @VERSION https://github.com/jdx/mr-boxington/releases
  version = "1.30.0";

  # A name of its own, so cargoShim can point into the package's
  # output; the derivation never reads cargoShim, so nothing recurses.
  mbx = callPackage ./lib/release-binary.nix { } {
    pname = "mbx";
    inherit version;

    # Hashes from the release's SHA256SUMS.
    assets = {
      aarch64-darwin = {
        url = "https://github.com/jdx/mr-boxington/releases/download/v${version}/mbx-aarch64-apple-darwin.tar.gz";
        hash = "sha256-1blXIWyLYcLfkcnnqvX+vUXsdCdKYNNxTr4xbtwURUM=";
      };
      aarch64-linux = {
        url = "https://github.com/jdx/mr-boxington/releases/download/v${version}/mbx-aarch64-unknown-linux-musl.tar.gz";
        hash = "sha256-kAhEuYD549r3eNOKGQRigcw14HEIqcghvv72EwhG3x8=";
      };
      x86_64-linux = {
        url = "https://github.com/jdx/mr-boxington/releases/download/v${version}/mbx-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-tSOpMk1Q/UNONV/Hpa9fcVXWKFTdalp0Fz1SZV8WjUU=";
      };
    };

    nativeBuildInputs = [ makeWrapper ];

    postInstall = ./mbx/post-install.sh;

    passthru.cargoShim = "${mbx}/libexec/mbx/cargo";

    meta = {
      description = "Build cache for Cargo";
      homepage = "https://mr-boxington.jdx.dev";
      license = lib.licenses.mit;
    };
  };
in
mbx
