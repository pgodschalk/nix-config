# The language server behind Zed's "Test Coverage Highlight"
# extension, reading lcov, JaCoCo, Cobertura and Clover reports. Not in
# nixpkgs.
#
# Packaging it fixes a bug rather than pinning a version: the published
# darwin binary has a broken code signature, so macOS SIGKILLs it and
# it exits 137 with no output, which from Zed looks like a server that
# starts and instantly dies. `autoSignDarwinBinariesHook` re-signs it
# ad hoc.
{
  lib,
  stdenvNoCC,
  fetchurl,
  gzip,
  darwin,
  autoPatchelfHook,
  stdenv,
}:

let
  # @VERSION https://github.com/hyyan/zed-test-coverage-highlight/releases
  version = "0.1.3";

  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-kvXcj9Q/4tp73pmErS+lgtum1r8XnuefhWnHZlRxWQU=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      hash = "sha256-fLKwR5YCEtJh9WggIrH2BAUMzInOBYK60o5joJEyh0s=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      hash = "sha256-TqI3Y8HBU9/d3PS0GxAApbYlI//PtCynmQxMSKuOd9Y=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "covhl: no upstream release asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "covhl";
  inherit version;

  src = fetchurl {
    url = "https://github.com/hyyan/zed-test-coverage-highlight/releases/download/v${version}/covhl-${target.triple}.gz";
    inherit (target) hash;
  };

  nativeBuildInputs = [
    gzip
  ]
  ++ lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook
  ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;

  # Upstream's Linux builds are glibc binaries with the FHS loader, so
  # on Linux they are patched to find it and their libraries in the
  # store.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  unpackPhase = builtins.readFile ./covhl/unpack.sh;

  dontBuild = true;

  installPhase = builtins.readFile ./covhl/install.sh;

  meta = {
    description = "Language server that surfaces test coverage from lcov, JaCoCo, Cobertura and Clover reports";
    homepage = "https://github.com/hyyan/zed-test-coverage-highlight";
    license = lib.licenses.mit;
    mainProgram = "covhl";
    platforms = lib.attrNames targets;
  };
}
