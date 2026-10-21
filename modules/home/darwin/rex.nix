{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # Manual install, so the path is fixed rather than a store path.
  app = "/Applications/Rex Beta.app";
  cli = "${app}/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";

  # The CLI on PATH, which Rex's agent skill and hook both call by bare
  # name. It execs the binary inside the bundle, which Sparkle updates.
  rex = pkgs.writeShellScriptBin "rex" (
    substituteFile ./rex/rex.sh {
      inherit app;
      cli = lib.escapeShellArg cli;
    }
  );

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
  home.packages = [ rex ];

  # What `rex skill setup` installs: a stub that has the agent run
  # `rex __internal skill`, so the guide follows the installed Rex.
  my.agentSkills.storeSkills.rex = ./rex/skill;

  # The other half of `rex skill setup`, merged after the main settings
  # merge because both rewrite the same file.
  home.activation.rexClaudeHook = lib.hm.dag.entryAfter [ "claudePluginSettings" ] (
    substituteFile ./rex/claude-hook.sh {
      settings = lib.escapeShellArg "${config.xdg.configHome}/claude-code/settings.json";
      jq = lib.getExe pkgs.jq;
      filter = "${./rex/claude-hook.jq}";
    }
  );

  # Rex publishes no reference for these, so the keys are alphabetical;
  # toPlist sorts them either way. `//` merges the theme selection in
  # only when the checkout exists.
  targets.darwin.defaults."com.superlogical.rex" = {
    # Manual install that updates itself through Sparkle.
    SUEnableAutomaticChecks = true;
    "Workspace.showsMenuBarIcon" = false;
    "Workspace.terminalFontName" = "SFMonoTerminal Nerd Font";
    # A float, so it is written as the `real` Rex stores.
    "Workspace.terminalFontPointSize" = 13.0;
    # Nushell through a login zsh; see modules/home/nushell.nix.
    "Workspace.terminalStartupCommand" = "${config.home.profileDirectory}/bin/nu-login";
    "Workspace.terminalUsesDisplayP3" = true;
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
