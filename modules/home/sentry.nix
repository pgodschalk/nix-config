{
  lib,
  pkgs,
  ...
}:
let
  fnoxFragment = "\n" + builtins.readFile ./sentry/fnox.toml;
in
{
  # No completions derivation: sentry-cli already ships the fish file
  # its own `completions fish` would generate.
  home.packages = [ pkgs.sentry-cli ];

  xdg.configFile."fnox/config.toml".text = lib.mkAfter fnoxFragment;

  programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./sentry/sentry.nu);
}
