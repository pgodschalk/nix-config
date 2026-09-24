{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  inherit (config.my.theme.dracula) extras pro;

  # The exceptions: tools that can follow neither the appearance nor an
  # environment variable, so a symlink has to move underneath them.
  # Anything that can use a variable is handled far more cheaply by the
  # nushell theme hook.
  links = [
    {
      path = "${config.xdg.configHome}/helix/config.toml";
      dark = "${config.xdg.configHome}/helix/config-dark.toml";
      light = "${config.xdg.configHome}/helix/config-light.toml";
    }
  ]
  ++ lib.optionals (extras != null) [
    {
      # glab takes the glamour style from its own config key and ignores
      # GLAMOUR_STYLE, so that key names a stable path and the path
      # moves.
      path = "${config.xdg.configHome}/glamour/style.json";
      dark = "${extras}/src/glamour/dracula-pro.json";
      light = "${extras}/src/glamour/alucard.json";
    }
    {
      # tlrc has no environment variable for either the palette or the
      # config path; `--config <FILE>` is the only override.
      path = "${config.xdg.configHome}/tlrc/config.toml";
      dark = "${extras}/src/tlrc/dracula-pro.toml";
      light = "${extras}/src/tlrc/alucard.toml";
    }
  ]
  ++ lib.optionals (pro != null) [
    {
      # aichat takes its theme from a file named for the mode, and
      # chooses which by a config key with no environment override, so
      # the config stays on "dark" and the file moves underneath it.
      path = "${config.xdg.configHome}/aichat/dark.tmTheme";
      dark = "${pro}/themes/sublime/dracula-pro.tmTheme";
      light = "${pro}/themes/sublime/dracula-pro-alucard.tmTheme";
    }
  ];

  applyOne =
    l:
    substituteFile ./appearance/apply-link.sh {
      light = lib.escapeShellArg l.light;
      dark = lib.escapeShellArg l.dark;
      path = lib.escapeShellArg l.path;
      dir = lib.escapeShellArg (dirOf l.path);
    };

  # Claude Code is a JSON key rather than a file, so it cannot join
  # `links` above. Its `-ansi` presets hand every colour to the
  # terminal's palette, which is wrong anywhere but Ghostty, and `auto`
  # picks among the built-in literal palettes rather than the custom
  # themes modules/home/claude-code.nix links.
  applyClaudeTheme = substituteFile ./appearance/apply-claude-theme.sh {
    settings = lib.escapeShellArg "${config.xdg.configHome}/claude-code/settings.json";
    jq = lib.getExe pkgs.jq;
    getTheme = "${./appearance/get-theme.jq}";
    setTheme = "${./appearance/set-theme.jq}";
  };

  switchScript = pkgs.writeShellScript "appearance-apply" (
    substituteFile ./appearance/switch.sh {
      inherit applyClaudeTheme;
      applyLinks = lib.concatMapStrings applyOne links;
    }
  );

  # Polling, because the appearance change is a distributed notification
  # that no shell tool can wait on and it writes nothing to disk:
  # cfprefsd keeps the value in memory, which also rules out launchd's
  # WatchPaths.
  watchScript = pkgs.writeShellScript "appearance-watch" (
    substituteFile ./appearance/watch.sh { switchScript = "${switchScript}"; }
  );
in
{
  launchd.agents.appearance = {
    enable = true;
    config = {
      ProgramArguments = [ "${watchScript}" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "${config.xdg.cacheHome}/appearance-watch.log";
    };
  };

  # The agent only starts at login, so without this the symlinks would
  # be missing between a switch and the next login -- and a missing
  # config is a silently unthemed tool rather than an error.
  home.activation.appearanceApply = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    substituteFile ./appearance/apply.sh { switchScript = "${switchScript}"; }
  );
}
