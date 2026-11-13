{ config, pkgs, ... }:
{
  # nixpkgs builds hk with Pkl embedded, so `hk.pkl` needs no `pkl` on
  # PATH.
  home.packages = [ pkgs.hk ];

  # hk ignores XDG_STATE_HOME and keeps its log in ~/.local/state/hk
  # without this. Its cache already follows the platform's cache dir.
  home.sessionVariables.HK_STATE_DIR = "${config.xdg.stateHome}/hk";

  my.launchd.extraVariables = [ "HK_STATE_DIR" ];
}
