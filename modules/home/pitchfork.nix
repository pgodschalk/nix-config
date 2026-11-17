{ config, pkgs, ... }:
{
  home.packages = [ pkgs.pitchfork ];

  # pitchfork ignores the XDG variables and falls back to
  # ~/.config/pitchfork and ~/.local/state/pitchfork without these.
  home.sessionVariables = {
    PITCHFORK_CONFIG_DIR = "${config.xdg.configHome}/pitchfork";
    # Unset, the supervisor keeps every log line forever.
    PITCHFORK_LOG_TIME_RETENTION = "6h";
    PITCHFORK_STATE_DIR = "${config.xdg.stateHome}/pitchfork";
  };

  my.launchd.extraVariables = [
    "PITCHFORK_CONFIG_DIR"
    "PITCHFORK_LOG_TIME_RETENTION"
    "PITCHFORK_STATE_DIR"
  ];
}
