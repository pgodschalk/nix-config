{
  config,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.bun ];

  home.sessionVariables = {
    # Moves both the install root and the package cache, which bun
    # otherwise puts in ~/.bun.
    BUN_INSTALL = "${config.xdg.dataHome}/bun";
  };
}
