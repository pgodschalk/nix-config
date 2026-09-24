{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # macOS ships the Golden Gate landscape wallpaper as four videos with
  # no solar metadata, so System Settings shows four entries and no
  # "Automatic" option. The wallpaper engine reads a local override
  # catalog instead, honouring `combineVariants` and a per-asset
  # `variant.solar` altitude/azimuth pair.
  #
  # Method from
  # https://gist.github.com/pdfux/5659724021e584313c00b843312e909d,
  # as one jq pass rather than the gist's sequential plutil calls.
  goldenGateId = "67512508-D33E-4CBC-8A9E-BE55CEE35C4C";

  systemCatalog = "/System/Library/ExtensionKit/Extensions/WallpaperAerialsExtension.appex/Contents/Resources/entries.json";

  # Where macOS keeps it, not an XDG directory: the preference below
  # names it, and that is the only link between the two.
  customDir = "${config.home.homeDirectory}/Library/Application Support/com.apple.wallpaper/aerials/custom";
  catalog = "${customDir}/entries.json";

  # Golden Gate has no separate Morning video, so Sunset stands in for
  # the morning position.
  solarFilter = pkgs.writeText "golden-gate-solar.jq" (
    builtins.readFile ./wallpaper/golden-gate-solar.jq
  );
in
{
  # Points the wallpaper engine at the generated catalog. ForceLocal
  # stops the engine preferring Apple's remote manifest over it.
  targets.darwin.defaults."com.apple.wallpaper.aerial" = {
    AerialManifestLocalPathOverride = catalog;
    AerialManifestForceLocal = true;
  };

  # Regenerated at activation because the catalog is derived from a file
  # inside the OS: a Nix build has no access to /System, and the source
  # changes with every macOS update.
  #
  # After setDarwinDefaults, so the preferences are in place before the
  # agent is restarted here.
  home.activation = {
    goldenGateSolarWallpaper = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] (
      substituteFile ./wallpaper/set-wallpaper.sh {
        catalog = lib.escapeShellArg catalog;
        customDir = lib.escapeShellArg customDir;
        goldenGateId = lib.escapeShellArg goldenGateId;
        systemCatalog = lib.escapeShellArg systemCatalog;
        jq = "${pkgs.jq}";
        solarFilter = "${solarFilter}";
      }
    );
  };
}
