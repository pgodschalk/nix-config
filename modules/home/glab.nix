{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  cfg = config.my.glab;

  # One `match` arm per extra host, as Nushell string literals.
  hostArms = lib.concatStrings (
    lib.mapAttrsToList (
      host: profile: "${builtins.toJSON host} => ${builtins.toJSON profile}\n            "
    ) cfg.hostProfiles
  );

  # glamour_style points at a stable path that the appearance watcher
  # repoints, because glab takes the style from that key and ignores
  # GLAMOUR_STYLE.
  #
  # The `hosts:` stanza holds no secret and is load-bearing: `glab auth
  # status` enumerates configured hosts, so without it glab reports
  # nothing authenticated while every real command works off
  # $GITLAB_TOKEN. Declaring the host with no `token:` key lists it and
  # keeps the token off disk.
  #
  # Only gitlab.com. glab probes every configured host on each `auth
  # status`, so one reachable only over a VPN costs the full timeout
  # off-VPN. Other hosts need no entry: GITLAB_HOST plus GITLAB_TOKEN
  # is enough.
  glabConfig = pkgs.replaceVars ./glab/config.yml {
    configHome = config.xdg.configHome;
  };

  fnoxFragment = "\n" + builtins.readFile ./glab/fnox.toml;
  nushellWrapper = substituteFile ./glab/glab.nu { inherit hostArms; };
in
{
  options.my.glab.hostProfiles = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "GitLab host to the fnox profile holding its GITLAB_TOKEN.";
  };

  config = {
    home.packages = [ pkgs.glab ];

    home.activation.glabConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      substituteFile ./glab/install-config.sh {
        coreutils = "${pkgs.coreutils}";
        dir = lib.escapeShellArg "${config.xdg.configHome}/glab-cli";
        src = "${glabConfig}";
        dst = lib.escapeShellArg "${config.xdg.configHome}/glab-cli/config.yml";
      }
    );

    xdg.configFile."fnox/config.toml".text = lib.mkAfter fnoxFragment;

    programs.nushell.extraConfig = lib.mkAfter nushellWrapper;
  };
}
