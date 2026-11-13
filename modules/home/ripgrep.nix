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
  home.packages = [ pkgs.ripgrep ];

  my.theme.variantVariables.RIPGREP_CONFIG_PATH = lib.mkIf (extras != null) {
    pro = "${extras}/src/ripgrep/pro.conf";
    alucard = "${extras}/src/ripgrep/alucard.conf";
  };
}
