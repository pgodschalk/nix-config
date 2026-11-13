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

  # The GUI variables home-manager sets itself; every module that sets
  # one declares it beside its setter, in my.launchd.extraVariables.
  upstreamGuiNames = [
    "XDG_BIN_HOME"
    "XDG_CACHE_HOME"
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_STATE_HOME"
  ];

  guiVariables = lib.getAttrs (builtins.filter (n: sessionVariables ? ${n}) (
    lib.unique (upstreamGuiNames ++ home.my.launchd.extraVariables)
  )) sessionVariables;

  # mr-boxington's Cargo shim, first, as modules/home/rust.nix puts it
  # in shells, so a GUI-spawned `cargo` also goes through mbx.
  mbx = pkgs.callPackage ../../pkgs/mbx.nix { };

  envVariables = {
    PATH = "${dirOf mbx.cargoShim}:/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    # nixpkgs' claude-code wrapper hands this bundle to Node as
    # NODE_EXTRA_CA_CERTS; without it a GUI-spawned `claude` cannot
    # verify api.anthropic.com.
    inherit (config.environment.variables) NIX_SSL_CERT_FILE;
  }
  // guiVariables;

  notLiteral = builtins.attrNames (
    lib.filterAttrs (
      _: value:
      lib.any (c: lib.hasInfix c (toString value)) [
        "'"
        "$"
        "\n"
      ]
    ) envVariables
  );

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
  assertions = [
    {
      assertion = notLiteral == [ ];
      message =
        "GUI variables must be literal, with no ', $ or newline: " + lib.concatStringsSep ", " notLiteral;
    }
  ];

  launchd.user.envVariables = envVariables;

  # `launchd.user.envVariables` is applied once during activation and is
  # gone at the next login, so the same set is re-exported by an agent.
  launchd.user.agents.session-env.serviceConfig = {
    ProgramArguments = [ (lib.getExe setEnv) ];
    RunAtLoad = true;
    KeepAlive = false;
  };
}
