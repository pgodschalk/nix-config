{
  lib,
  pkgs,
  ...
}:
let
  # getExe' rather than getExe: the derivation sets no meta.mainProgram
  # and getExe then guesses the binary name and warns for it.
  activate = pkgs.runCommand "fnox-activate.nu" { } ''
    ${lib.getExe' pkgs.fnox "fnox"} activate nu > $out
  '';
  completion = pkgs.runCommand "fnox-completion.nu" { } ''
    ${lib.getExe' pkgs.fnox "fnox"} completion nu > $out
  '';
in
{
  home.packages = [ pkgs.fnox ];

  # `source`, not `use`: fnox emits plain scripts with top-level
  # `def --env` rather than modules.
  #
  # mkAfter matters for the completion half, which wraps whatever
  # external completer it finds: running before
  # modules/home/completions.nix would drop carapace and the fish
  # fallback for every other command.
  programs.nushell.extraConfig = lib.mkAfter ''
    source ${activate}
    source ${completion}
  '';
}
