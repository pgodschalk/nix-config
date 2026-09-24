{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;

  sessionVariables = config.home-manager.users.${user}.home.sessionVariables;

  # Every variable here redirects state out of $HOME. A GUI-spawned CLI
  # that does not see them recreates the dotfiles they exist to prevent.
  redirects = lib.getAttrs (builtins.filter (n: sessionVariables ? ${n}) [
    "ANSIBLE_HOME"
    "BUNDLE_USER_HOME"
    "CHECKPOINT_DISABLE"
    "CLAUDE_CONFIG_DIR"
    "CLOUDSDK_CONFIG"
    "GOMODCACHE"
    "GOPATH"
    "LESSHISTFILE"
    "STARSHIP_CACHE"
    "npm_config_cache"
    "npm_config_userconfig"
  ]) sessionVariables;

  envVariables = {
    PATH = "/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";

    XDG_CONFIG_HOME = "${home}/Library/Application Support";
    XDG_DATA_HOME = "${home}/Library/Application Support";
    XDG_STATE_HOME = "${home}/Library/Application Support";
    XDG_CACHE_HOME = "${home}/Library/Caches";
  }
  // redirects;

  setEnv = pkgs.writeShellApplication {
    name = "launchd-session-env";
    text = substituteFile ./launchd-env/set-env.sh {
      setenvCalls = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value: "/bin/launchctl setenv ${lib.escapeShellArg name} ${lib.escapeShellArg value}"
        ) envVariables
      );
    };
  };
in
{
  launchd.user.envVariables = envVariables;

  # `launchd.user.envVariables` is applied once during activation and is
  # gone at the next login, so the same set is re-exported by an agent.
  launchd.user.agents.session-env.serviceConfig = {
    ProgramArguments = [ (lib.getExe setEnv) ];
    RunAtLoad = true;
    KeepAlive = false;
  };
}
