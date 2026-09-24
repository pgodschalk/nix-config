{ pkgs, ... }:
{
  home.packages = [ pkgs.ripgrep ];

  # RIPGREP_CONFIG_PATH is set per appearance variant in
  # modules/home/nushell.nix.
}
