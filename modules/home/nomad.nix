{ lib, pkgs, ... }:
{
  # pkgs/nomad-ls.nix fetches the darwin release asset only; a Linux
  # host needs the matching URLs added there.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    (pkgs.callPackage ../../pkgs/nomad-ls.nix { })
  ];

  # Format-on-save is a no-op for Nomad files: nomad-ls advertises
  # documentFormattingProvider and returns no edits.
}
