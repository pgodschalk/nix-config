{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # `pkl` itself, wrapped so its package cache leaves ~/.pkl.
  pkl = pkgs.writeShellApplication {
    name = "pkl";
    text = substituteFile ./pkl/pkl.sh {
      pkl = lib.getExe pkgs.pkl;
      cacheHome = config.xdg.cacheHome;
    };
  };
in
{
  # pkl-lsp fetches a missing package, such as hk's, through the `pkl`
  # CLI on PATH.
  home.packages = [
    pkl
    (pkgs.callPackage ../../pkgs/pkl-lsp.nix { })
  ];
}
