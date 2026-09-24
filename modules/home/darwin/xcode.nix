{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  extras = config.my.theme.dracula.extras;
  themeDir = "${config.home.homeDirectory}/Library/Developer/Xcode/UserData/FontAndColorThemes";
  themes = [
    "Dracula Pro"
    "Alucard"
  ];
  # Xcode has two theme systems side by side, and both files are shipped
  # for each theme: `.xccolortheme` is the classic plist of 28 RGB
  # syntax colours, under "Classic Presets", and
  # `.xcworkspacecolortheme` is the modern JSON recipe, under
  # "Presets".
  #
  # A modern per-token override holds either a hue in radians or a full
  # Oklch colour, so these carry Dracula's real hex values rather than
  # approximations. `primary` and `secondary` stay hue plus intensity,
  # which is the shape Xcode writes, so the window background and chrome
  # are still Xcode-derived; the classic file covers what the recipe
  # does not reach.
  extensions = [
    "xccolortheme"
    "xcworkspacecolortheme"
  ];

  # Fonts are not part of a modern theme: Xcode keeps one global recipe
  # in preferences and silently drops `fontName`/`fontSize` written into
  # a theme. The recipe holds a `code` and a `console` category, each
  # with separate light and dark faces -- SFMonoTerminal ships one face,
  # so both slots name it, and leaving a slot alone leaves it on Apple's
  # default.
  fontRecipe = (pkgs.formats.json { }).generate "xcode-font-recipe.json" (
    let
      face = family: identifier: weight: {
        inherit size;
        family = if family == null then { monospace = { }; } else { custom._0 = family; };
        variant = {
          inherit identifier weight;
          slant.value = 0;
          width.value = 0;
        };
      };
      size = 13;
      # `weight` is Xcode's own scale: 4 for Regular, 5 for Medium.
      category = name: light: dark: [
        { ${name} = { }; }
        {
          category.${name} = { };
          displayModes = [
            { standard = { }; }
            {
              category.${name} = { };
              content.custom = {
                automaticSize = true;
                inherit light dark;
              };
            }
          ];
        }
      ];
      liga = "Liga SFMono Nerd Font";
    in
    {
      fonts =
        category "code" (face liga "LigaSFMonoNerdFont-Regular" 4) (face liga "LigaSFMonoNerdFont-Medium" 5)
        ++ category "console" (face null "SFMonoTerminalNF" 4) (face null "SFMonoTerminalNF" 4);
      lineSpacing.normal = { };
    }
  );

in
{
  # Compared before writing, so an unchanged switch is quiet -- and a
  # font chosen in Xcode's UI is reverted by the next switch, which is
  # the point of declaring it. Its own entry, so a font change does not
  # depend on the themes being present.
  home.activation.xcodeFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    substituteFile ./xcode/set-font.sh {
      recipe = "${fontRecipe}";
      coreutils = "${pkgs.coreutils}";
    }
  );

  # Copied rather than symlinked: Xcode's theme picker does not list a
  # symlink into the store, so a theme edited in dracula-pro-extras
  # needs a switch to take effect, and the writable copies are
  # overwritten again by the next one.
  home.activation.xcodeThemes = lib.mkIf (extras != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./xcode/install-themes.sh {
        themeDir = lib.escapeShellArg themeDir;
        installBlocks = lib.concatMapStrings (
          f:
          substituteFile ./xcode/install-theme.sh {
            src = lib.escapeShellArg "${extras}/src/xcode/${f}";
            dst = lib.escapeShellArg "${themeDir}/${f}";
            name = f;
          }
        ) (lib.concatMap (name: map (ext: "${name}.${ext}") extensions) themes);
      }
    )
  );
}
