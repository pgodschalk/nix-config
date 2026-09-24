{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  draculaPro = config.my.theme.dracula.pro;
  sublime = "${draculaPro}/themes/sublime";

  # bat identifies a theme by its filename stem, not by the `name` key
  # inside the tmTheme: `--theme="Dracula Pro"` warns "Unknown theme"
  # on stderr and falls back to the default.
  darkTheme = "dracula-pro";
  lightTheme = "dracula-pro-alucard";

  batConfigDir = "${config.xdg.configHome}/bat";
in
{
  programs.bat = {

    config = {
      wrap = "auto";
      # Nushell already prints a header, so bat's box drawing on top is
      # noise; the line numbers and git gutter stay.
      style = "numbers,changes";
    };
    enable = true;

    extraPackages = with pkgs.bat-extras; [
      batgrep
      batdiff
      batwatch
      batpipe
    ];
  };

  # batwatch shells out to `entr`, and polls once a second without it.
  home.packages = [ pkgs.entr ];

  # Out-of-store symlinks: the checkout is outside this flake, and a
  # pure evaluation refuses an absolute path that is not flake source.
  xdg.configFile = {
    "bat/themes/dracula-pro.tmTheme" = lib.mkIf (draculaPro != null) {
      source = config.lib.file.mkOutOfStoreSymlink "${sublime}/dracula-pro.tmTheme";
    };
    "bat/themes/dracula-pro-alucard.tmTheme" = lib.mkIf (draculaPro != null) {
      source = config.lib.file.mkOutOfStoreSymlink "${sublime}/dracula-pro-alucard.tmTheme";
    };
  };

  home.activation.batCache = lib.mkForce (
    lib.hm.dag.entryAfter [ "linkGeneration" ] (
      substituteFile ./bat/cache.sh {
        cacheHome = lib.escapeShellArg config.xdg.cacheHome;
        configDir = lib.escapeShellArg batConfigDir;
        emptyDir = "${pkgs.emptyDirectory}";
        bat = lib.getExe config.programs.bat.package;
      }
    )
  );

  home.sessionVariables = {
    # bat's default --theme=auto asks the terminal for its background on
    # every run, so there is nothing to keep in sync and no hook.
    BAT_THEME_DARK = darkTheme;
    BAT_THEME_LIGHT = lightTheme;

    # `col -bx` strips the backspace overstrike groff uses for bold and
    # underline, which bat's `man` syntax re-applies as colour.
    MANPAGER = "sh -c 'col -bx | bat --language=man --style=plain'";
    # Without this groff emits its own colours alongside bat's.
    MANROFFOPT = "-c";
  };
}
