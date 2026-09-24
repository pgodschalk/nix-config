{ lib, pkgs, ... }:
let
  fnoxFragment = "\n" + builtins.readFile ./huggingface/fnox.toml;
in
{
  # The `hf` binary comes out of the Python library; there is no package
  # of its own.
  home.packages = [ pkgs.python3Packages.huggingface-hub ];

  xdg.configFile."fnox/config.toml".text = lib.mkAfter fnoxFragment;

  programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./huggingface/huggingface.nu);
}
