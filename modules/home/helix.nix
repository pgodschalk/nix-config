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

  # Which configuration nixd reads this machine's options from, as the
  # inside of a TOML string. Linux has a standalone home configuration
  # and no system one, so its system entry is empty.
  flake = ''(builtins.getFlake "${config.home.homeDirectory}/Developer/github.com/pgodschalk/nix-config")'';
  tomlString = s: lib.removePrefix "\"" (lib.removeSuffix "\"" (builtins.toJSON s));
  systemKind = if isDarwin then "nix-darwin" else "nixos";
  systemOptions = tomlString (
    if isDarwin then "${flake}.darwinConfigurations.Patricks-MacBook-Pro.options" else "{ }"
  );
  homeManagerOptions = tomlString (
    if isDarwin then
      "${flake}.darwinConfigurations.Patricks-MacBook-Pro.options.home-manager.users.type.getSubOptions [ ]"
    else
      "${flake}.homeConfigurations.\"${config.home.username}@linux\".options"
  );

  astroTsdk = pkgs.callPackage ../../pkgs/astro-tsdk.nix { };

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
        systemKind
        systemOptions
        homeManagerOptions
        jdtlsSettings
        astroTsdk
        ;
      oxfmtConfig = ./oxc/oxfmtrc.json;
      # The Xcode wrappers exist only on macOS.
      clangFormat = if isDarwin then "clang-format-xcode" else "clang-format";
      swiftFormat = if isDarwin then "swift-format-xcode" else "swift-format";
      terraform = pkgs.terraform;
    };

    # config.toml itself is a symlink modules/home/darwin/appearance.nix owns,
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
