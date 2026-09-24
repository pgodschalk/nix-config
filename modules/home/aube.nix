{ pkgs, substituteFile, ... }:
let
  # aube emits bash, zsh or fish but not nushell, so the fish output
  # goes where the fallback completer in modules/home/completions.nix
  # reads it. `usage` is load-bearing twice over: `aube completion`
  # shells out to it at build time, and the script it writes does so on
  # every completion.
  fishCompletions = pkgs.runCommand "aube-completions.fish" { nativeBuildInputs = [ pkgs.usage ]; } (
    substituteFile ./aube/completions.sh { aube = "${pkgs.aube}/bin/aube"; }
  );
in
{
  home.packages = [
    pkgs.aube
    pkgs.usage
  ];

  # vendor_completions.d, which fish searches under XDG_DATA_HOME on
  # every platform; fish/completions there is not on its path.
  xdg.dataFile."fish/vendor_completions.d/aube.fish".source = fishCompletions;

  home.sessionVariables = {
    # Left on `auto`, aube builds a second collection of Node installs
    # that mise knows nothing about.
    AUBE_RUNTIME_INSTALLER = "mise";
  };
}
