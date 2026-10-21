# The language server behind Zed's Nomad extension, not in nixpkgs.
#
# Pinning it matters because the alternative is a server fetched at run
# time: the extension calls `latest_github_release` and downloads
# whatever is newest, so the version in use would change with no flake
# change. It resolves `which` first, which is what lets this take
# precedence.
#
# The asset name is the one the extension constructs.
{ lib, callPackage }:

let
  # @VERSION https://github.com/loczek/nomad-ls/releases
  version = "0.0.8";
in
callPackage ./lib/release-binary.nix { } {
  pname = "nomad-ls";
  inherit version;

  assets.aarch64-darwin = {
    url = "https://github.com/loczek/nomad-ls/releases/download/v${version}/nomad-ls_darwin_arm64.tar.gz";
    hash = "sha256-FKC4odJXgOagLwjSce7MMHZnzIxtoRkeQyMM2DMvUow=";
  };

  meta = {
    description = "Language server for HashiCorp Nomad job specifications";
    homepage = "https://github.com/loczek/nomad-ls";
    # Upstream publishes no license, so all rights are reserved.
    license = lib.licenses.unfree;
    mainProgram = "nomad-ls";
  };
}
