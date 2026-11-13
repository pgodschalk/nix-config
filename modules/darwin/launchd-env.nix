{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  user = config.system.primaryUser;

  home = config.home-manager.users.${user};
  inherit (home.home) sessionVariables;

  # Every variable here redirects state out of $HOME. A GUI-spawned CLI
  # that does not see them recreates the dotfiles they exist to prevent.
  # Sorted, ASCII order; a module setting a redirect of its own adds it
  # through my.launchd.extraVariables instead.
  redirectNames = [
    "ANDROID_AVD_HOME"
    "ANDROID_EMULATOR_HOME"
    "ANDROID_USER_HOME"
    "ANSIBLE_HOME"
    "BUNDLE_USER_HOME"
    "BUN_INSTALL"
    "CARGO_HOME"
    "CHECKPOINT_DISABLE"
    "CLAUDE_CONFIG_DIR"
    "GOMODCACHE"
    "GOPATH"
    "GRADLE_USER_HOME"
    "HK_STATE_DIR"
    "IMPECCABLE_BIN"
    "IMPECCABLE_HOME"
    "LESSHISTFILE"
    "PITCHFORK_CONFIG_DIR"
    "PITCHFORK_STATE_DIR"
    "RUSTUP_HOME"
    "STARSHIP_CACHE"
    "XDG_BIN_HOME"
    "XDG_CACHE_HOME"
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_STATE_HOME"
    "npm_config_cache"
    "npm_config_userconfig"
  ];

  redirects = lib.getAttrs (builtins.filter (n: sessionVariables ? ${n}) (
    lib.unique (redirectNames ++ home.my.launchd.extraVariables)
  )) sessionVariables;

  # mr-boxington's Cargo shim, first, as modules/home/rust.nix puts it
  # in shells, so a GUI-spawned `cargo` also goes through mbx.
  mbx = pkgs.callPackage ../../pkgs/mbx.nix { };

  envVariables = {
    PATH = "${mbx}/libexec/mbx:/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    # nixpkgs' claude-code wrapper hands this bundle to Node as
    # NODE_EXTRA_CA_CERTS; without it a GUI-spawned `claude` cannot
    # verify api.anthropic.com.
    inherit (config.environment.variables) NIX_SSL_CERT_FILE;
  }
  // redirects;

  setEnv = pkgs.writeShellApplication {
    name = "launchd-session-env";
    text = substituteFile ./launchd-env/set-env.sh {
      envFile = "${pkgs.writeText "launchd-session-env" (
        lib.concatLines (lib.mapAttrsToList (name: value: "${name}=${value}") envVariables)
      )}";
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
