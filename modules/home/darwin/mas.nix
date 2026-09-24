{
  apps,
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  mas = "${pkgs.mas}/bin/mas";

  # One check-and-install block per app, kept terse because it is
  # repeated once per app in the generated activation.
  #
  # The label is a separately escaped word rather than interpolated into
  # the quotes, so an app title carrying a quote, a `$` or a backtick
  # cannot reach the shell as syntax.
  installBlocks = lib.concatStrings (
    lib.mapAttrsToList (
      name: id:
      substituteFile ./mas/install-one.sh {
        id = lib.escapeShellArg (toString id);
        label = lib.escapeShellArg "${name} (${toString id})";
        inherit mas;
      }
    ) config.my.masApps
  );
in
{
  config = {
    my.masApps = apps.mas;

    # A home-manager activation entry rather than a nix-darwin script,
    # because `mas` acts on the App Store session of the user running
    # it.
    #
    # It can only install what is already in the Purchased list, so a
    # failure is collected and reported rather than aborting the switch.
    # `mas list` derives its answer from Spotlight, so an unindexed app
    # is reported missing and re-installed as a no-op.
    home.activation = lib.mkIf (config.my.masApps != { }) {
      masApps = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        substituteFile ./mas/install.sh { inherit installBlocks mas; }
      );
    };
  };
}
