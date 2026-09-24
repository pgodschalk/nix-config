{ pkgs, ... }:
{
  # helm itself comes from modules/home/containers.nix, which helm-ls
  # shells out to for `helm template` and dependency resolution.
  home.packages = [ pkgs.helm-ls ];
}
