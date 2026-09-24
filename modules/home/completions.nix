{ pkgs, ... }:
{
  home.packages = [
    pkgs.carapace

    # Not a shell here but a completion engine: `fish --command complete
    # --do-complete=…` reads the vendor_completions.d files Nix packages
    # ship, with fish never being anyone's login shell. On macOS they
    # reach the profile only through the pathsToLink entry in
    # modules/darwin/shell.nix.
    pkgs.fish
  ];

  # Must be config.nu rather than anywhere later: fzf's integration
  # loads from the autoload directory, which Nushell reads after
  # config.nu, and it wraps whatever external completer it finds. The
  # other order has fzf silently replaced.
  programs.nushell.extraConfig = builtins.readFile ./completions/completions.nu;
}
