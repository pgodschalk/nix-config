{ pkgs, ... }:
{
  home.packages = [
    pkgs.ty
    pkgs.ruff
    pkgs.python3Packages.debugpy
  ];
}
