{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.nh ];

  # The darwin-specific variable rather than the general NH_FLAKE, so a
  # later `nh home` or `nh os` on a Linux host is not pointed here.
  home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    NH_DARWIN_FLAKE = "/etc/nix-darwin";
  };

  # Do not use `nh clean`: garbage collection belongs to Determinate
  # Nixd, and two collectors with different retention policies fight.
}
