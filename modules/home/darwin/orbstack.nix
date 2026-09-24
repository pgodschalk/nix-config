{ lib, pkgs, ... }:
let
  # The same schema as Docker's own daemon.json, generated so the types
  # are checked at evaluation time.
  dockerConfig = (pkgs.formats.json { }).generate "orbstack-docker.json" {
    ipv6 = true;
  };
in
{
  # A hardcoded path in $HOME, and a read-only store symlink, so
  # OrbStack's own "Docker engine config" editor can no longer save to
  # it.
  home.file.".orbstack/config/docker.json" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = dockerConfig;
  };

  # The bundle id is `dev.kdrag0n.MacVirt`, not `dev.orbstack.OrbStack`.
  #
  # `app.start_at_login` is deliberately absent: it is not a config
  # value at all, but an SMAppService login item macOS owns, with no
  # file to declare.
  targets.darwin.defaults."dev.kdrag0n.MacVirt" = {
    # "Keep running when menu bar app is quit". A boolean despite
    # `defaults read` showing 1; the trailing 2 is OrbStack's own key
    # versioning.
    global_stayInBackground2 = true;

    # "Show in menu bar": off. The key is phrased positively while the
    # setting reads as a hide, so 0 is "not shown".
    global_showMenubarExtra = 0;

    # "External terminal app", as a bundle id.
    terminal_defaultApp = "com.mitchellh.ghostty";
  };
}
