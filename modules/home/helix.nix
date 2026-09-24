{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  jdtlsSettings = pkgs.callPackage ../../pkgs/jdtls-settings.nix { };

  extras = config.my.theme.dracula.extras;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Which configuration nixd reads this machine's options from.
  systemKind = if isDarwin then "nix-darwin" else "nixos";
  systemAttr =
    if isDarwin then
      "darwinConfigurations.Patricks-MacBook-Pro"
    else
      "nixosConfigurations.\${config.home.username}";

  # astro-language-server refuses to start without a TypeScript SDK: an
  # initialize with no initializationOptions comes back `-32603: The
  # `typescript.tsdk` init option is required`. Zed's Astro extension
  # locates one itself; Helix's bundled entry is only a command.
  #
  # Resolved at build time because the only real location is under
  # pnpm's content-addressed layout and would rot on the next bump, back
  # to the same silent -32603. The bundled copy rather than
  # pkgs.typescript, which is a major version ahead of it.
  astroTsdk = pkgs.runCommand "astro-tsdk" { } (
    substituteFile ./helix/astro-tsdk.sh {
      astroLanguageServer = "${pkgs.astro-language-server}";
    }
  );

  mkConfig = theme: substituteFile ./helix/config.toml { inherit theme; };
in
{
  home.packages = [ pkgs.helix ];

  # This overrides a value already set: nix-darwin's
  # `environment.variables.EDITOR` is nano, exported from
  # set-environment and picked up by /etc/zshenv, and home-manager's
  # session variables are read afterwards.
  #
  # The absolute store path rather than a bare `hx`, because $EDITOR is
  # consumed by processes that may not have the user profile on PATH.
  # VISUAL is left unset so tools fall through to this.
  home.sessionVariables.EDITOR = lib.getExe pkgs.helix;

  xdg.configFile = {
    # Out-of-store symlinks, so editing a theme in the working copy
    # takes effect in the next `hx` without a rebuild.
    "helix/themes/dracula-pro.toml" = lib.mkIf (extras != null) {
      source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/helix/dracula-pro.toml";
    };
    "helix/themes/alucard.toml" = lib.mkIf (extras != null) {
      source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/helix/alucard.toml";
    };

    "helix/languages.toml".source = pkgs.replaceVars ./helix/languages.toml {
      homeDirectory = config.home.homeDirectory;
      inherit
        systemAttr
        systemKind
        jdtlsSettings
        astroTsdk
        ;
      terraform = pkgs.terraform;
    };

    # config.toml itself is a symlink modules/home/appearance.nix owns,
    # so it is not declared here -- home-manager and the watcher must
    # not both claim one path.
    "helix/config-dark.toml".text = mkConfig "dracula-pro";
    "helix/config-light.toml".text = mkConfig "alucard";
  }
  # Elsewhere there is no appearance to follow, so config.toml is a
  # plain file rather than a symlink.
  // lib.optionalAttrs (!isDarwin) {
    "helix/config.toml".text = mkConfig "dracula-pro";
  };
}
