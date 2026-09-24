# A language server that reads dependency manifests across 14 package
# ecosystems and reports pins that are outdated, yanked, unsatisfiable
# or carrying a known advisory. Not in nixpkgs, so it comes from the
# upstream release tarball, whose published `.sha256` sidecar matches
# the hash below.
#
# It reaches the network widely -- crates.io, api.github.com,
# api.nuget.org, central.sonatype.com, maven.google.com, jsr.io,
# gitlab.com and api.osv.dev. Package names and versions leave the
# machine; file contents do not. api.github.com is queried without a
# token, so the 60-requests-an-hour ceiling applies and the symptom of
# hitting it is hints going quiet rather than an error.
{
  lib,
  stdenvNoCC,
  fetchurl,
  darwin,
}:

let
  # @VERSION https://github.com/bug-ops/deps-lsp/releases
  version = "1.2.0";

  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-5YMNn8i9EASOSIXe8VhoeFr4AgD+lBIX9kyC0hWztI8=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      hash = "sha256-pDPnlld5ge5HQdBdL2xgvZ58WWTlHjkYIcxXS4YCQ90=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      hash = "sha256-zW21PdxjICZkwWuRgmBCxwRrpLmHzEjfkbrZNZTUMIo=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "deps-lsp: no upstream release asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "deps-lsp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/bug-ops/deps-lsp/releases/download/v${version}/deps-lsp-${target.triple}.tar.gz";
    inherit (target) hash;
  };

  nativeBuildInputs = lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook;

  # The tarball is a single bare binary, no leading directory.
  sourceRoot = ".";

  dontBuild = true;

  installPhase = builtins.readFile ./deps-lsp/install.sh;

  meta = {
    description = "Language server for dependency manifests across 14 package ecosystems";
    homepage = "https://github.com/bug-ops/deps-lsp";
    license = lib.licenses.mit;
    mainProgram = "deps-lsp";
    platforms = lib.attrNames targets;
  };
}
