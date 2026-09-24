{
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  tipctl = pkgs.callPackage ../../pkgs/tipctl.nix { };
  op = lib.getExe' pkgs._1password-cli "op";
  item = "op://Private/r5z35lksmufbwflyzjqnudkhdq";
in
{
  home.packages = [ tipctl ];

  # TransIP authenticates with an RSA private key and tipctl reads it
  # only from its JSON config, so the wrapper materialises one per shell
  # session under $TMPDIR instead of $HOME.
  #
  # Two things in the wrapper are load-bearing. `--apiUseWhitelist` left
  # at its default asks for a whitelist-only token, which the API then
  # refuses with "Remote IP is not authorized for this request". And
  # TMPDIR is pinned to the session because the library caches the
  # access token in `$TMPDIR/symfony-cache`, where one bad run poisons
  # every later one until the cache is cleared.
  programs.nushell.extraConfig = lib.mkAfter (
    substituteFile ./tipctl/tipctl.nu {
      tipctl = lib.getExe tipctl;
      coreutils = "${pkgs.coreutils}";
      inherit op;
      keyRef = lib.escapeShellArg "${item}/cli.key";
      userRef = lib.escapeShellArg "${item}/username";
    }
  );
}
