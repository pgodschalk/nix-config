{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  extras = "${config.home.homeDirectory}/Developer/github.com/pgodschalk/dracula-pro-extras";
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

  # Hex to write the recipe, base64 to compare it.
  #
  # Both are import-from-derivation, which is tolerable only because
  # this module is macOS-only and never reached by the Linux eval check.
  # Do not copy the pattern into a portable module. There is no way
  # around it here: Nix has no base64 builtin.
  encode =
    name: script:
    builtins.readFile (pkgs.runCommand name { } (substituteFile script { recipe = "${fontRecipe}"; }));
  fontRecipeHex = encode "xcode-font-recipe-hex" ./xcode/font-recipe-hex.sh;
  fontRecipeB64 = encode "xcode-font-recipe-b64" ./xcode/font-recipe-b64.sh;
in
{
  # Compared before writing, so an unchanged switch is quiet -- and a
  # font chosen in Xcode's UI is reverted by the next switch, which is
  # the point of declaring it. Its own entry, so a font change does not
  # depend on the themes being present.
  home.activation.xcodeFonts = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./xcode/set-font.sh {
        wantB64 = lib.escapeShellArg fontRecipeB64;
        recipeHex = lib.escapeShellArg fontRecipeHex;
      }
    )
  );

  # Copied rather than symlinked: Xcode's theme picker does not list a
  # symlink into the store, so a theme edited in dracula-pro-extras
  # needs a switch to take effect, and the writable copies are
  # overwritten again by the next one.
  home.activation.xcodeThemes = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
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
