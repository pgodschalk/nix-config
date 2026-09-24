# The language server behind Zed's Nomad extension, not in nixpkgs.
#
# Pinning it matters because the alternative is a server fetched at run
# time: the extension calls `latest_github_release` and downloads
# whatever is newest, so the version in use would change with no flake
# change. It resolves `which` first, which is what lets this take
# precedence.
#
# The asset name is the one the extension constructs.
{
  lib,
  stdenvNoCC,
  fetchurl,
  darwin,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nomad-ls";
  # @VERSION https://github.com/loczek/nomad-ls/releases
  version = "0.0.8";

  src = fetchurl {
    url = "https://github.com/loczek/nomad-ls/releases/download/v${finalAttrs.version}/nomad-ls_darwin_arm64.tar.gz";
    hash = "sha256-FKC4odJXgOagLwjSce7MMHZnzIxtoRkeQyMM2DMvUow=";
  };

  nativeBuildInputs = lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook;

  # The tarball is a single bare binary, no leading directory.
  sourceRoot = ".";

  dontBuild = true;

  installPhase = builtins.readFile ./nomad-ls/install.sh;

  meta = {
    description = "Language server for HashiCorp Nomad job specifications";
    homepage = "https://github.com/loczek/nomad-ls";
    license = lib.licenses.mit;
    mainProgram = "nomad-ls";
    platforms = [ "aarch64-darwin" ];
  };
})
