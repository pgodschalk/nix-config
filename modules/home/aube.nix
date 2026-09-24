{ pkgs, ... }:
let
  # aube emits bash, zsh or fish but not nushell, so the fish output
  # goes where the fallback completer in modules/home/completions.nix
  # reads it. `usage` is load-bearing: `aube completion` shells out to
  # it and the derivation fails without it.
  fishCompletions = pkgs.runCommand "aube-completions.fish" { nativeBuildInputs = [ pkgs.usage ]; } ''
    ${pkgs.aube}/bin/aube completion fish > $out
  '';
in
{
  home.packages = [ pkgs.aube ];

  xdg.dataFile."fish/completions/aube.fish".source = fishCompletions;

  home.sessionVariables = {
    # Left on `auto`, aube builds a second collection of Node installs
    # that mise knows nothing about.
    AUBE_RUNTIME_INSTALLER = "mise";
  };
}
