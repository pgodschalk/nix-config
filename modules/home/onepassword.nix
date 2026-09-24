{ pkgs, ... }:
{
  home.packages = [ pkgs._1password-cli ];

  # Without this `op` falls back to whichever account was signed in to
  # last, which makes the default depend on history. Other accounts are
  # selected per directory by a mise.local.toml.
  home.sessionVariables.OP_ACCOUNT = "my.1password.eu";
}
