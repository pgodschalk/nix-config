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
  stdenvNoCC,
  fetchurl,
  darwin,
  makeWrapper,
}:

let
  # @VERSION https://github.com/jdx/mr-boxington/releases
  version = "1.30.0";

  # Hashes from the release's SHA256SUMS.
  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-1blXIWyLYcLfkcnnqvX+vUXsdCdKYNNxTr4xbtwURUM=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-musl";
      hash = "sha256-kAhEuYD549r3eNOKGQRigcw14HEIqcghvv72EwhG3x8=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-musl";
      hash = "sha256-tSOpMk1Q/UNONV/Hpa9fcVXWKFTdalp0Fz1SZV8WjUU=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "mbx: no upstream release asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "mbx";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jdx/mr-boxington/releases/download/v${version}/mbx-${target.triple}.tar.gz";
    inherit (target) hash;
  };

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook;

  sourceRoot = ".";

  dontBuild = true;

  installPhase = builtins.readFile ./mbx/install.sh;

  meta = {
    description = "Build cache for Cargo";
    homepage = "https://mr-boxington.jdx.dev";
    license = lib.licenses.mit;
    mainProgram = "mbx";
    platforms = lib.attrNames targets;
  };
}
