# Builder for the Rust language servers for Python that are published to
# PyPI and are not in nixpkgs.
#
# Despite arriving through PyPI these are Rust binaries rather than
# Python libraries: each wheel's whole payload is one executable under
# `<name>-<version>.data/scripts/`, with no Python in it and nothing to
# byte-compile. Building from source would mean a Rust toolchain and a
# `cargoHash` to re-pin per bump, to arrive at what upstream published.
#
# A binary that analyses Python from the outside is never a project
# dependency, so there is nothing for a pyproject.toml to declare.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  darwin,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:

{
  pname,
  version,
  binary ? pname,
  url,
  hash,
  description,
  homepage,
  license,
}:

stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl { inherit url hash; };

  # A wheel is a zip, and `.whl` is not an extension stdenv unpacks by
  # itself. On darwin the binary also has to be re-signed: an ad-hoc
  # signature does not survive being rewritten into the store, and macOS
  # refuses to exec an arm64 binary without one.
  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook;

  unpackPhase = builtins.readFile ./python-lsp-wheel/unpack.sh;

  dontBuild = true;

  installPhase = substituteFile ./python-lsp-wheel/install.sh { inherit binary; };

  meta = {
    inherit description homepage license;
    mainProgram = binary;
    platforms = lib.platforms.unix;
  };
}
