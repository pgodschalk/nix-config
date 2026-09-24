{ config, ... }:
{
  home.sessionVariables.LESSHISTFILE = "${config.xdg.stateHome}/less/history";

  # less does not create the directory, and without it saves no history
  # and says nothing.
  xdg.stateFile."less/.keep".text = "";
}
