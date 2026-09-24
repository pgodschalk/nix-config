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
  stdenvNoCC,
  fetchurl,
  unzip,
  darwin,
  autoPatchelfHook,
  stdenv,
  curl,
  sqlite,
}:

let
  # @VERSION https://github.com/kattouf/package-swift-lsp/releases
  version = "1.6.1";

  targets = {
    aarch64-darwin = {
      asset = "arm64-apple-macosx";
      hash = "sha256-ZlbIPf+n8wN7AT9EfskFEJGLjMkDX0eDaMYgZBILZ1I=";
    };
    aarch64-linux = {
      asset = "aarch64-unknown-linux-gnu";
      hash = "sha256-OZD/W52Ut6DyFl+Pv3hOJxCmtXVvScQCKoYzR/nPgIw=";
    };
    x86_64-linux = {
      asset = "x86_64-unknown-linux-gnu";
      hash = "sha256-qH3f0JffJ/s4olJJPky68lTWBcTvXiuf9NxLW4kfoPs=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "package-swift-lsp: no upstream release asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "package-swift-lsp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/kattouf/package-swift-lsp/releases/download/${version}/package-swift-lsp-${version}-${target.asset}.zip";
    inherit (target) hash;
  };

  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook
  ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;

  # Upstream's Linux builds are glibc binaries with the FHS loader, so
  # on Linux they are patched to find it and their libraries in the
  # store.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    curl
    sqlite
  ];

  # The zip holds the bare binary, no leading directory.
  sourceRoot = ".";

  dontBuild = true;

  installPhase = builtins.readFile ./package-swift-lsp/install.sh;

  meta = {
    description = "Language server for Swift Package Manager Package.swift manifests";
    homepage = "https://github.com/kattouf/package-swift-lsp";
    license = lib.licenses.mit;
    mainProgram = "package-swift-lsp";
    platforms = lib.attrNames targets;
  };
}
