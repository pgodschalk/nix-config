{ pkgs, ... }:
{
  # `jq` is aliased to jaq in modules/home/nushell.nix, which binds in
  # interactive Nushell only; anything here needing jq's exact behaviour
  # calls pkgs.jq by store path.
  home.packages = [
    pkgs.jaq

    # For `.jq` filter files rather than the `jq` command.
    pkgs.jq-lsp

    # Shadows macOS's /usr/bin/jq, a 1.7.1 that rejects the 24-bit
    # JQ_COLORS fields the Dracula theme exports, so every script
    # running jq would print "Failed to set $JQ_COLORS".
    pkgs.jq
  ];
}
