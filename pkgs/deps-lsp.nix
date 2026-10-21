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
{ lib, callPackage }:

let
  # @VERSION https://github.com/bug-ops/deps-lsp/releases
  version = "3.0.0";
in
callPackage ./lib/release-binary.nix {
  pname = "deps-lsp";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "https://github.com/bug-ops/deps-lsp/releases/download/v${version}/deps-lsp-aarch64-apple-darwin.tar.gz";
      hash = "sha256-Ye84o33h3njAAGfjtUvkdCEA3uMBPP0iBrbNZt0US0A=";
    };
    aarch64-linux = {
      url = "https://github.com/bug-ops/deps-lsp/releases/download/v${version}/deps-lsp-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-X6RoLtjafgLJTnHq3I2eHBS0y98eM7aeNT8SGHBRCW8=";
    };
    x86_64-linux = {
      url = "https://github.com/bug-ops/deps-lsp/releases/download/v${version}/deps-lsp-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-DcEmxcOfB1tYwR/nBS+4+Oyczi6Qi96grpTsaRG6pxI=";
    };
  };

  meta = {
    description = "Language server for dependency manifests across 14 package ecosystems";
    homepage = "https://github.com/bug-ops/deps-lsp";
    license = lib.licenses.mit;
    mainProgram = "deps-lsp";
  };
}
