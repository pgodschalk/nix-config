{ config, ... }:
{
  # On Linux the XDG defaults are already right, so nothing is remapped
  # and `enable` only exports the variables.
  #
  # Linux here is always headless, so every GUI module stays in
  # modules/home/darwin and none is imported.
  xdg.enable = true;

  # `xdg.userDirs` would export the same variables and also create the
  # directories, which is wrong on a headless box. Only the two
  # Nushell's `dt` and `dl` aliases read are declared, so those resolve
  # rather than erroring on an unset variable.
  home.sessionVariables = {
    XDG_DESKTOP_DIR = "${config.home.homeDirectory}/Desktop";
    XDG_DOWNLOAD_DIR = "${config.home.homeDirectory}/Downloads";
  };
}
