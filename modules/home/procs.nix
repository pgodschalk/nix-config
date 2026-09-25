{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.procs ];

  xdg.configFile."procs/config.toml".source = ./procs/config.toml;

  programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./procs/procs.nu);
}
