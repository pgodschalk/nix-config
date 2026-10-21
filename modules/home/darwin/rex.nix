{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  draculaPro = config.my.theme.dracula.pro;

  # Rex's importer mints `custom-<UUID>`; any fixed id works, as long as
  # the theme and the light/dark selection below agree on it.
  themes = {
    dark = {
      id = "custom-17D04EF2-8D02-47C6-AA09-B37EDD9EE560";
      file = "pro";
    };
    light = {
      id = "custom-81C737C5-D624-4194-BB6B-864F3C39A6E4";
      file = "alucard";
    };
  };

  # One `--theme ID APPEARANCE PATH` triple per entry of `themes`.
  themeArgs = lib.concatLists (
    lib.mapAttrsToList (appearance: theme: [
      "--theme"
      theme.id
      appearance
      "${draculaPro}/themes/ghostty/${theme.file}"
    ]) themes
  );
in
{
  # Rex publishes no reference for these, so the keys are alphabetical;
  # toPlist sorts them either way. `//` merges the theme selection in
  # only when the checkout exists.
  targets.darwin.defaults."com.superlogical.rex" = {
    # Manual install that updates itself through Sparkle.
    SUEnableAutomaticChecks = true;
    "Workspace.terminalFontName" = "SFMonoTerminal Nerd Font";
    # A float, so it is written as the `real` Rex stores.
    "Workspace.terminalFontPointSize" = 13.0;
    # Nushell through a login zsh; see modules/home/nushell.nix.
    "Workspace.terminalStartupCommand" = "${config.home.profileDirectory}/bin/nu-login";
  }
  // lib.optionalAttrs (draculaPro != null) {
    "Workspace.darkThemeID" = themes.dark.id;
    "Workspace.lightThemeID" = themes.light.id;
  };

  # Custom themes are a JSON array stored as plist data, which toPlist
  # cannot express, so they are built from the Ghostty theme files.
  home.activation.rexThemes = lib.mkIf (draculaPro != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./rex/import-themes.sh {
        python = lib.getExe pkgs.python3;
        script = "${./rex/import-themes.py}";
        themes = lib.escapeShellArgs themeArgs;
      }
    )
  );
}
