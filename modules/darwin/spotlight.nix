{
  config,
  lib,
  substituteFile,
  ...
}:
let
  home = config.home-manager.users.${config.system.primaryUser}.home.homeDirectory;
  appSupport = "${home}/Library/Application Support";

  # Tool stores and app caches that churn and that nobody searches;
  # XDG data, config and state all point into Application Support on
  # this Mac (home/patrick/darwin.nix). Alphabetical: no reference
  # orders them.
  excluded = map (name: "${appSupport}/${name}") [
    "amie-desktop"
    "aube"
    "bun"
    "cargo"
    "Claude"
    "claude-code"
    "claude-marketplace"
    "discord"
    "go"
    "jj"
    "jouet"
    "Linear"
    "mise"
    "orca"
    "pi"
    "pitchfork"
    "rustup"
    "uv"
    "Zed"
  ];
in
{
  # The Search Privacy pane's own list, which has no command-line
  # interface. Entries are only ever added: one dropped from the list
  # above stays excluded until removed in the pane. mds reads the list
  # at boot, and SIP keeps it from being restarted, so a new entry
  # applies after the next restart.
  #
  # mkAfter so this follows home-manager's block, which creates some of
  # these directories on a fresh machine.
  system.activationScripts.postActivation.text = lib.mkAfter (
    substituteFile ./spotlight/exclusions.sh { exclusions = lib.escapeShellArgs excluded; }
  );
}
