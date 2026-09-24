{ ... }:
{
  targets.darwin.defaults."pro.betterdisplay.BetterDisplay" = {
    # "Show app icon in the menu bar": off. The key is phrased as a
    # hide, so 1 hides it.
    hideMenuIcon = 1;

    # A brew-nix cask, so the bundle is read-only and a Sparkle update
    # can only fail; versions arrive with `nix flake update brew-api`.
    SUEnableAutomaticChecks = false;
  };
}
