# Language-agnostic filesystem path completion over LSP. Not in nixpkgs
# and not on crates.io, so it comes from the upstream release binary.
{ lib, callPackage }:

let
  # @VERSION https://github.com/kunlinglio/path-server/releases
  version = "1.4.4";
in
callPackage ./lib/release-binary.nix {
  pname = "path-server";
  inherit version;

  # Upstream publishes one plain binary per target rather than an
  # archive.
  assets.aarch64-darwin = {
    url = "https://github.com/kunlinglio/path-server/releases/download/v${version}/path-server_v${version}_aarch64-apple-darwin";
    hash = "sha256-5fkQJ0Izv34yFWOklBpXS56Z5KqZKaCtxItR3ovaqQ4=";
  };

  meta = {
    description = "Language server providing filesystem path completion";
    homepage = "https://github.com/kunlinglio/path-server";
    license = lib.licenses.asl20;
    mainProgram = "path-server";
  };
}
