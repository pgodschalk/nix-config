# Builds a prebuilt upstream release binary: fetches the asset for the
# host platform, unpacks it, installs the named binaries into
# `$out/bin`, re-signs them on Darwin and patches them for the store
# on Linux. `assets` maps a Nix system to one `{ url; hash }` or to a
# list of them.
{
  lib,
  stdenvNoCC,
  stdenv,
  fetchurl,
  darwin,
  autoPatchelfHook,
  unzip,
  pname,
  version,
  assets,
  binaries ? [ pname ],
  buildInputs ? [ ],
  meta,
}:

let
  inherit (stdenvNoCC.hostPlatform) system isDarwin isLinux;

  asset = assets.${system} or (throw "${pname}: no upstream release asset for ${system}");

  toList = x: if builtins.isList x then x else [ x ];
  fetch = a: fetchurl { inherit (a) url hash; };

  first = lib.head (lib.attrValues assets);
  firstUrl = (lib.head (toList first)).url;
  archive =
    if
      lib.hasInfix ".tar." firstUrl
      || lib.any (s: lib.hasSuffix s firstUrl) [
        ".tgz"
        ".tar"
        ".tbz"
      ]
    then
      "tar"
    else if lib.hasSuffix ".zip" firstUrl then
      "zip"
    else if lib.hasSuffix ".gz" firstUrl then
      "gzip"
    else
      "file";
in
stdenvNoCC.mkDerivation (
  {
    inherit pname version binaries;

    nativeBuildInputs =
      lib.optional (archive == "zip") unzip
      ++ lib.optional isDarwin darwin.autoSignDarwinBinariesHook
      ++ lib.optional isLinux autoPatchelfHook;

    # Linux assets are glibc binaries with the FHS loader, so
    # autoPatchelf points them at the loader and libraries in the
    # store.
    buildInputs = lib.optional isLinux stdenv.cc.cc.lib ++ buildInputs;

    # Every archive holds its binaries at the root, with no leading
    # directory.
    sourceRoot = ".";

    dontBuild = true;

    installPhase = builtins.readFile ./release-binary/install.sh;

    meta = {
      platforms = lib.attrNames assets;
    }
    // meta;

    passthru = { inherit archive; };
  }
  // (if builtins.isList first then { srcs = map fetch asset; } else { src = fetch asset; })
  # A bare `.gz` or a bare file is unpacked to the first name in
  # `binaries`.
  // lib.optionalAttrs (archive == "gzip") {
    unpackPhase = builtins.readFile ./release-binary/unpack-gzip.sh;
  }
  // lib.optionalAttrs (archive == "file") {
    unpackPhase = builtins.readFile ./release-binary/unpack-file.sh;
  }
)
