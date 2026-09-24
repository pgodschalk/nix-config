{
  config,
  pkgs,
  ...
}:
{
  # A floor rather than a pin: aube execs node for `aube dlx` and fails
  # outright with none on PATH, and a repo pinning a version through
  # mise still wins.
  home.packages = [ pkgs.nodejs ];

  home.sessionVariables = {
    npm_config_cache = "${config.xdg.cacheHome}/npm";
    npm_config_userconfig = "${config.xdg.configHome}/npm/npmrc";
  };
}
