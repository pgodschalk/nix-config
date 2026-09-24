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
  draculaPro = "${config.home.homeDirectory}/Developer/github.com/dracula-pro/dracula-pro/themes/ghostty";

  themeDirs = [
    "${config.xdg.configHome}/ghostty/themes"
    "${config.home.homeDirectory}/Library/Application Support/com.mitchellh.ghostty/themes"
  ];
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

      window-padding-x = 16;
      window-padding-y = 4;
      window-height = 28;
      window-width = 87;

      # Nushell through a login zsh; see modules/home/nushell.nix.
      command = "${config.home.profileDirectory}/bin/nu-login";

      # Must be stated rather than left at `detect`, which reads the
      # command's filename -- `nu-login` -- matches no known shell and
      # injects nothing. This is what makes Ghostty export
      # GHOSTTY_SHELL_INTEGRATION_XDG_DIR, which the wrapper needs.
      shell-integration = "nushell";
      shell-integration-features = true;

      macos-non-native-fullscreen = "visible-menu";
      macos-option-as-alt = "left";

      # A list renders as repeated `keybind = …` lines.
      keybind = [
        "global:§=toggle_quick_terminal"
      ];
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

  # The theme lookup always uses `$XDG_CONFIG_HOME/ghostty/themes`,
  # falling back to ~/.config, even when the config came from the
  # native path -- so the second link is insurance rather than a route
  # that is used.
  home.activation.ghosttyThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatMapStrings (
      dir:
      substituteFile ./ghostty/link-themes.sh {
        themes = lib.escapeShellArg draculaPro;
        dir = lib.escapeShellArg dir;
      }
    ) themeDirs
  );
}
