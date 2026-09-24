{ config, lib, ... }:
{
  # XDG_BIN_HOME first, where uv and other XDG-aware installers put
  # executables, then ~/.local/bin for the tools that hardcode it. On
  # Linux the two are the same directory.
  #
  # sessionPath prepends, so a binary here outranks the profile's. It
  # reaches shells only; GUI apps read launchd.user.envVariables.
  home.sessionPath = lib.unique [
    config.xdg.binHome
    "${config.home.homeDirectory}/.local/bin"
  ];
}
