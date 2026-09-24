{ pkgs, ... }:
{
  home.packages = [
    pkgs.oxlint
    pkgs.oxfmt
  ];
}
