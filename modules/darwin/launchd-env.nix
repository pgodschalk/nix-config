{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  user = config.system.primaryUser;

  sessionVariables = config.home-manager.users.${user}.home.sessionVariables;

  # Every variable here redirects state out of $HOME. A GUI-spawned CLI
  # that does not see them recreates the dotfiles they exist to prevent.
  # Sorted, ASCII order.
  redirects = lib.getAttrs (builtins.filter (n: sessionVariables ? ${n}) [
    "ANSIBLE_HOME"
    "BUNDLE_USER_HOME"
    "BUN_INSTALL"
    "CHECKPOINT_DISABLE"
    "CLAUDE_CONFIG_DIR"
    "CLOUDSDK_CONFIG"
    "GOMODCACHE"
    "GOPATH"
    "IMPECCABLE_BIN"
    "IMPECCABLE_HOME"
    "LESSHISTFILE"
    "STARSHIP_CACHE"
    "XDG_CACHE_HOME"
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_STATE_HOME"
    "npm_config_cache"
    "npm_config_userconfig"
  ]) sessionVariables;

  envVariables = {
    PATH = "/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
