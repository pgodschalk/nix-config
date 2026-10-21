# A language server for Swift Package Manager's `Package.swift`
# manifests, not in nixpkgs, so it comes from the upstream release zip.
#
# It complements sourcekit-lsp rather than overlapping it: that reads
# the manifest as ordinary Swift and so completes the API, where this
# completes versions, branches and products from the network. It
# advertises only completion and hover, so attaching it to the whole
# Swift language is safe -- it contends with no formatter and adds no
# diagnostics.
#
# It reaches github.com, raw.githubusercontent.com and
# swiftpackageindex.com, with no token setting, so GitHub is queried
# unauthenticated at 60 requests an hour and the symptom of hitting
# that is completions going quiet rather than an error.
#
# x86_64-darwin is skipped, since Rosetta is ruled out.
{
  lib,
  stdenv,
  callPackage,
  curl,
  sqlite,
}:

let
  # @VERSION https://github.com/kattouf/package-swift-lsp/releases
  version = "1.6.1";
in
callPackage ./lib/release-binary.nix {
  pname = "package-swift-lsp";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "https://github.com/kattouf/package-swift-lsp/releases/download/${version}/package-swift-lsp-${version}-arm64-apple-macosx.zip";
      hash = "sha256-ZlbIPf+n8wN7AT9EfskFEJGLjMkDX0eDaMYgZBILZ1I=";
    };
    aarch64-linux = {
      url = "https://github.com/kattouf/package-swift-lsp/releases/download/${version}/package-swift-lsp-${version}-aarch64-unknown-linux-gnu.zip";
      hash = "sha256-OZD/W52Ut6DyFl+Pv3hOJxCmtXVvScQCKoYzR/nPgIw=";
    };
    x86_64-linux = {
      url = "https://github.com/kattouf/package-swift-lsp/releases/download/${version}/package-swift-lsp-${version}-x86_64-unknown-linux-gnu.zip";
      hash = "sha256-qH3f0JffJ/s4olJJPky68lTWBcTvXiuf9NxLW4kfoPs=";
    };
  };

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    curl
    sqlite
  ];

  meta = {
    description = "Language server for Swift Package Manager Package.swift manifests";
    homepage = "https://github.com/kattouf/package-swift-lsp";
    license = lib.licenses.mit;
    mainProgram = "package-swift-lsp";
  };
}
