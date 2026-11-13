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

  # `builtins.getFlake` will not take /etc/nix-darwin, which is a
  # symlink, so the real checkout is named.
  flake = ''(builtins.getFlake "${config.home.homeDirectory}/Developer/github.com/pgodschalk/nix-config")'';
  # The inside of a TOML basic string: JSON escapes it the same way,
  # and the template supplies the quotes.
  tomlString = s: lib.removePrefix "\"" (lib.removeSuffix "\"" (builtins.toJSON s));
  host = "${flake}.darwinConfigurations.Patricks-MacBook-Pro";
  linuxHome = ''${flake}.homeConfigurations."${config.home.username}@linux"'';
  systemKind = if isDarwin then "nix-darwin" else "nixos";
  nixd = config.my.nixd.settings;

  astroTsdk = pkgs.callPackage ../../pkgs/astro-tsdk.nix { };

  mkConfig = theme: substituteFile ./helix/config.toml { inherit theme; };
in
{
  options.my.nixd.settings = lib.mkOption {
    inherit (pkgs.formats.json { }) type;
    readOnly = true;
    default = {
      nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
      options = {
        # Linux has a standalone home configuration and no system
        # one, so its system entry is empty.
        ${systemKind}.expr = if isDarwin then "${host}.options" else "{ }";
        home-manager.expr =
          if isDarwin then
            "${host}.options.home-manager.users.type.getSubOptions [ ]"
          else
            "${linuxHome}.options";
      };
    };
    description = "nixd's settings for this machine: the expressions it evaluates for nixpkgs and for the system and home-manager options, as plain strings. Helix, Zed and the LSP plugin send them.";
  };

  config = {
    home.packages = [ pkgs.helix ];

    # This overrides a value already set: nix-darwin's
    # `environment.variables.EDITOR` is nano, exported from
    # set-environment and picked up by /etc/zshenv, and home-manager's
    # session variables are read afterwards.
    #
    # The absolute store path rather than a bare `hx`, because $EDITOR
    # is consumed by processes that may not have the user profile on
    # PATH. VISUAL is left unset so tools fall through to this.
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
        nixpkgsExpr = tomlString nixd.nixpkgs.expr;
        systemOptions = tomlString nixd.options.${systemKind}.expr;
        homeManagerOptions = tomlString nixd.options.home-manager.expr;
        inherit systemKind jdtlsSettings astroTsdk;
        oxfmtConfig = ./oxc/oxfmtrc.json;
        # The Xcode wrappers exist only on macOS.
        clangFormat = if isDarwin then "clang-format-xcode" else "clang-format";
        swiftFormat = if isDarwin then "swift-format-xcode" else "swift-format";
        terraform = pkgs.terraform;
        mbxCargo = (pkgs.callPackage ../../pkgs/mbx.nix { }).cargoShim;
      };

      # config.toml itself is a symlink
      # modules/home/darwin/appearance.nix owns, so it is not
      # declared here -- home-manager and the watcher must not both
      # claim one path.
      "helix/config-dark.toml".text = mkConfig "dracula-pro";
      "helix/config-light.toml".text = mkConfig "alucard";
    }
    # Elsewhere there is no appearance to follow, so config.toml is a
    # plain file rather than a symlink.
    // lib.optionalAttrs (!isDarwin) {
      "helix/config.toml".text = mkConfig "dracula-pro";
    };
  };
}
