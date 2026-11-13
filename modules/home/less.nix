{ config, ... }:
{
  home.sessionVariables.LESSHISTFILE = "${config.xdg.stateHome}/less/history";

  my.launchd.extraVariables = [ "LESSHISTFILE" ];

  # less does not create the directory, and without it saves no history
  # and says nothing.
  xdg.stateFile."less/.keep".text = "";
}
