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
}:

let
  # @VERSION
  # https://github.com/hyyan/zed-test-coverage-highlight/releases
  version = "0.1.2";

  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-kl7HSOD6VwcqeksiZnAMKFhBMnJ97VmCxseAkYaDxms=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      hash = "sha256-RnCj7asRTdfE8DQVUTWE2r9i9s/mSO2GJZTDKrDYZjc=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      hash = "sha256-ZsmsOPb+cfmLb+qk76G6yxMUgV7J5zz6+8U2yEh2gPY=";
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
  ++ lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook;

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
