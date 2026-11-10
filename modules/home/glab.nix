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

  # pkgs.formats.yaml sorts the keys, so the order here is for the
  # reader only.
  glabConfig = (pkgs.formats.yaml { }).generate "glab-config.yml" {
    git_protocol = "ssh";

    # A stable path that the appearance watcher repoints, because glab
    # takes the style from this key and ignores GLAMOUR_STYLE.
    glamour_style = "${config.xdg.configHome}/glamour/style.json";

    # glab's own default is true, and the nixpkgs wrapper that sets
    # GLAB_SEND_TELEMETRY=0 is not a contract.
    telemetry = false;

    # Holds no secret and is load-bearing: `glab auth status` enumerates
    # configured hosts, and `--hostname` names only a configured one, so
    # a host missing here reads as signed out while every real command
    # works off $GITLAB_TOKEN. Orca recognises a GitLab repository only
    # through that check. A host with no `token:` key is listed and
    # keeps the token off disk.
    #
    # Every hostProfiles host is listed, a VPN-only one included: Orca's
    # --hostname check needs it. The wrappers narrow a bare `auth
    # status` to the host whose token they hold, so it neither waits
    # out an unreachable host nor shows it another host's token.
    hosts = lib.genAttrs ([ "gitlab.com" ] ++ lib.attrNames cfg.hostProfiles) (host: {
      api_protocol = "https";
      api_host = host;
    });
  };

  fnoxFragment = "\n" + builtins.readFile ./glab/fnox.toml;
  nushellWrapper = substituteFile ./glab/glab.nu { inherit hostArms; };
in
{
  options.my.glab.hostProfiles = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "GitLab host to the fnox profile holding its GITLAB_TOKEN; each is also listed in glab's config.";
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
