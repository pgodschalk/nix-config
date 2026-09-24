# Language-agnostic filesystem path completion over LSP. Not in nixpkgs
# and not on crates.io, so it comes from the upstream release binary.
{
  lib,
  stdenvNoCC,
  fetchurl,
  darwin,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "path-server";
  # @VERSION https://github.com/kunlinglio/path-server/releases
  version = "1.4.2";

  # Upstream publishes one plain binary per target rather than an
  # archive.
  src = fetchurl {
    url = "https://github.com/kunlinglio/path-server/releases/download/v${finalAttrs.version}/path-server_v${finalAttrs.version}_aarch64-apple-darwin";
    hash = "sha256-SGKQpDmPp8pLCJK9mKLE/835D2JIxcD1H2UC9GwWYSw=";
  };

  nativeBuildInputs = lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook;

  dontUnpack = true;
  dontBuild = true;

  installPhase = builtins.readFile ./path-server/install.sh;

  meta = {
    description = "Language server providing filesystem path completion";
    homepage = "https://github.com/kunlinglio/path-server";
    license = lib.licenses.asl20;
    mainProgram = "path-server";
    platforms = [ "aarch64-darwin" ];
  };
})
