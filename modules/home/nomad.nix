{ lib, pkgs, ... }:
{
  home.packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) [
    (pkgs.callPackage ../../pkgs/nomad-ls.nix { })
  ];

  # Format-on-save is a no-op for Nomad files: nomad-ls advertises
  # documentFormattingProvider and returns no edits.
}
