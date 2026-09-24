{ config, ... }:
{
  home.sessionVariables.LESSHISTFILE = "${config.xdg.stateHome}/less/history";
}
