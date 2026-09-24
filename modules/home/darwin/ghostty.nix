{
  config,
  lib,
  substituteFile,
  ...
}:
let
  # Referenced by name, not by path: Ghostty's `theme` accepts an
  # absolute path but not inside the `light:…,dark:…` form, where it
  # silently reduces the value to the basename and then cannot find it.
  draculaPro = config.my.theme.dracula.pro;
in
{
  programs.ghostty = {
    enable = true;
    # Ghostty itself comes from apps.nix.
    package = null;

    settings = {
      font-family = "SFMonoTerminal Nerd Font";
      font-size = 13;

      theme = "light:alucard,dark:pro";

      mouse-hide-while-typing = true;
      background-opacity = 0.95;
      background-blur = true;

      # Nushell through a login zsh; see modules/home/nushell.nix.
      command = "${config.home.profileDirectory}/bin/nu-login";

      # A list renders as repeated `keybind = …` lines.
      keybind = [
        "global:§=toggle_quick_terminal"
      ];

      window-padding-x = 16;
      window-padding-y = 4;
      window-height = 28;
      window-width = 87;

      # Must be stated rather than left at `detect`, which reads the
      # command's filename -- `nu-login` -- matches no known shell and
      # injects nothing. This is what makes Ghostty export
      # GHOSTTY_SHELL_INTEGRATION_XDG_DIR, which the wrapper needs.
      shell-integration = "nushell";
      shell-integration-features = true;

      macos-non-native-fullscreen = "visible-menu";
      macos-option-as-alt = "left";
    };
  };

  # home-manager writes the config under XDG_CONFIG_HOME, where Ghostty
  # looks only when that variable is set -- which it is not for an app
  # launched from the Dock after a logout. Ghostty's own macOS location
  # points at the same file, and it merges every config it finds.
  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    config.xdg.configFile."ghostty/config".source;

  # It comes from nixpkgs, so the bundle is read-only and a Sparkle
  # update can only fail; versions arrive with `nix flake update`.
  targets.darwin.defaults."com.mitchellh.ghostty".SUEnableAutomaticChecks = false;

  # Ghostty looks themes up only in `$XDG_CONFIG_HOME/ghostty/themes`,
  # falling back to ~/.config, even when the config came from the
  # native path. The session-env agent in modules/darwin/launchd-env.nix
  # exports XDG_CONFIG_HOME at login; a launch before it runs finds the
  # config but not the theme.
  home.activation.ghosttyThemes = lib.mkIf (draculaPro != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./ghostty/link-themes.sh {
        themes = lib.escapeShellArg "${draculaPro}/themes/ghostty";
        dir = lib.escapeShellArg "${config.xdg.configHome}/ghostty/themes";
      }
    )
  );
}
