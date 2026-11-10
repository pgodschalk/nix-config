{ pkgs, ... }:
{
  home.packages = [
    (pkgs.callPackage ../../pkgs/oxlint.nix { })
    pkgs.oxfmt
  ];
}
