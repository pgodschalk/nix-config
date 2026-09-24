{ pkgs, ... }:
{
  # No config is written here: modules/home/appearance.nix owns that
  # path, as a symlink that moves between the two variants.
  home.packages = [ pkgs.tlrc ];
}
