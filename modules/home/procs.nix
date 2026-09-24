{
  config,
  lib,
  pkgs,
  ...
}:
let
  extras = config.my.theme.dracula.extras;
in
{
  home.packages = [ pkgs.procs ];

  xdg.configFile."procs/config.toml" = lib.mkIf (extras != null) {
    source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/procs/config.toml";
  };

  programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./procs/procs.nu);
}
