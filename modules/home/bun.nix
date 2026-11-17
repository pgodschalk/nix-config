{
  config,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.bun ];

  home.sessionVariables = {
    # The install root, which bun otherwise puts in ~/.bun.
    BUN_INSTALL = "${config.xdg.dataHome}/bun";
    # The package cache, which bun otherwise keeps under the install
    # root; here it sits with the other caches instead.
    BUN_INSTALL_CACHE_DIR = "${config.xdg.cacheHome}/bun/install/cache";
  };

  my.launchd.extraVariables = [
    "BUN_INSTALL"
    "BUN_INSTALL_CACHE_DIR"
  ];
}
