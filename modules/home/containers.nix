{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  registries = config.my.containers.registries;

  # A table rather than a generated `case`, so the helper's whole
  # dispatch is ordinary shell in one file and this side is only data.
  registriesJson = pkgs.writeText "docker-credential-op-registries.json" (
    builtins.toJSON (
      lib.listToAttrs (
        lib.concatLists (
          lib.mapAttrsToList (
            _: r:
            map (
              host:
              lib.nameValuePair host {
                inherit (r)
                  account
                  vault
                  item
                  field
                  scopeDirs
                  ;
              }
            ) r.hosts
          ) registries
        )
      )
    )
  );

  # `docker login` base64-encodes the credential into config.json; a
  # helper keeps the file to a registry-to-helper mapping and fetches
  # the secret per invocation. `store` and `erase` succeed silently
  # because there is nothing local to write, which makes `docker login`
  # a harmless no-op rather than an error.
  credentialHelper = pkgs.writeShellScriptBin "docker-credential-op" (
    substituteFile ./containers/docker-credential-op.sh {
      op = lib.escapeShellArg "${pkgs._1password-cli}/bin/op";
      jq = lib.getExe pkgs.jq;
      registries = "${registriesJson}";
      lookupFilter = "${./containers/lookup.jq}";
      outputFilter = "${./containers/credential.jq}";
    }
  );

  dockerConfig = builtins.toJSON (
    {
      credHelpers = lib.genAttrs (lib.concatLists (lib.mapAttrsToList (_: r: r.hosts) registries)) (
        _: "op"
      );
    }
    # OrbStack's context, restated because this file replaces
    # ~/.docker's own.
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { currentContext = "orbstack"; }
  );
in
{
  # Each registry is backed by one 1Password item, read with `op read
  # --account <account> op://<vault>/<item>/<field>` and `/username`.
  options.my.containers.registries = lib.mkOption {
    default = { };
    description = "Container registries served by docker-credential-op.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          hosts = lib.mkOption {
            type = lib.types.nonEmptyListOf lib.types.str;
            description = "Every spelling a client may ask for.";
          };
          account = lib.mkOption { type = lib.types.str; };
          vault = lib.mkOption { type = lib.types.str; };
          item = lib.mkOption { type = lib.types.str; };
          field = lib.mkOption { type = lib.types.str; };
          scopeDirs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "If set, only answer beneath these directories.";
          };
        };
      }
    );
  };

  config = {
    my.containers.registries = {
      # Docker Hub answers to several names depending on the client: the
      # docker CLI asks for the v1 URL and skopeo for `docker.io`. A
      # missing spelling fails as "not logged in" with no hint that a
      # helper exists.
      dockerhub = {
        hosts = [
          "https://index.docker.io/v1/"
          "index.docker.io"
          "registry-1.docker.io"
          "docker.io"
          "dhi.io"
        ];
        account = "my.1password.eu";
        vault = "Private";
        item = "yvwdn427g6wp6e65uf65tnzray";
        field = "docker cli";
      };
      # The same token gh uses. GHCR takes a PAT as the password and the
      # GitHub username as the user.
      ghcr = {
        hosts = [ "ghcr.io" ];
        account = "my.1password.eu";
        vault = "Private";
        item = "bhmimlus3gz3xfqr4xnbobbdje";
        field = "token";
      };
    };

    home.packages = [
      credentialHelper
      pkgs.skopeo
      pkgs.kubernetes-helm
    ]
    # On macOS the docker client comes from OrbStack, which also serves
    # the daemon.
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.docker-client ];

    home.sessionVariables = {
      # One credential configuration for all three clients: helm and
      # skopeo read docker-format JSON and honour credHelpers.
      HELM_REGISTRY_CONFIG = "${config.home.homeDirectory}/.docker/config.json";
      REGISTRY_AUTH_FILE = "${config.home.homeDirectory}/.docker/config.json";
    };

    # The config stays in the dotdir docker hardcodes: it looks for its
    # contexts and cli-plugins beside the config, and OrbStack registers
    # both in ~/.docker, so DOCKER_CONFIG elsewhere breaks every command
    # with `context "orbstack": context not found`.
    home.file.".docker/config.json".text = dockerConfig;
  };
}
