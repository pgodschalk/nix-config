{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  cfg = config.my.mergedSettings;
  json = pkgs.formats.json { };
  mergeJson = pkgs.callPackage ../../pkgs/merge-json.nix { inherit substituteFile; };

  manifest = json.generate "merged-settings.json" (
    lib.mapAttrsToList (name: entry: {
      inherit name;
      inherit (entry) file;
      declared = json.generate "${name}.json" entry.value;
      state = "${config.xdg.stateHome}/nix-config/${name}.json";
      strategies = json.generate "${name}-strategies.json" entry.strategies;
    }) cfg
  );

  entryAssertions =
    name: entry:
    [
      {
        assertion = !lib.hasSuffix ".strategies" name;
        message = "my.mergedSettings.${name}: a name cannot end in .strategies, which names another entry's strategies state";
      }
      {
        assertion = lib.hasPrefix "/" entry.file;
        message = "my.mergedSettings.${name}.file is not an absolute path: ${entry.file}";
      }
      {
        assertion = builtins.isAttrs entry.value;
        message = "my.mergedSettings.${name}.value is not an attribute set";
      }
    ]
    ++ lib.mapAttrsToList (key: strategy: {
      assertion =
        strategy != "union"
        || !(builtins.isAttrs entry.value && entry.value ? ${key})
        || builtins.isList entry.value.${key};
      message = "my.mergedSettings.${name}.value.${key} is merged by union, so it must be a list";
    }) entry.strategies;
in
{
  options.my.mergedSettings = lib.mkOption {
    default = { };
    example = lib.literalExpression ''
      {
        some-app = {
          file = "''${config.xdg.configHome}/some-app/settings.json";
          value.plugins = [ "spell-check" ];
          strategies.plugins = "union";
        };
      }
    '';
    description = ''
      Settings merged into a JSON file an app owns and rewrites itself,
      by entry name. A top-level key is deep-merged unless `strategies`
      names it, and what an entry stops declaring is taken back out of
      the file at the next activation. Removing an entry stops merging
      it and leaves its keys in the file, so declare its `value` as
      `{ }` for one switch first. A file that cannot be merged is left
      as it is, with a warning naming the entry.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          file = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path of the app's own settings file.";
          };
          value = lib.mkOption {
            inherit (json) type;
            description = "The declared settings, a JSON object.";
          };
          strategies = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.enum [
                "replace"
                "union"
              ]
            );
            default = { };
            description = ''
              How a top-level key is merged when not deep-merged.
              `replace` makes the file's value the declared one whole,
              discarding what the app added under it. `union` keeps the
              app's own elements of a list and appends the declared ones,
              comparing by value. A key dropped together with its
              strategy is still taken back by that strategy.
            '';
          };
        };
      }
    );
  };

  config = {
    assertions = lib.concatLists (lib.mapAttrsToList entryAssertions cfg);

    home.activation.mergedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./merged-settings/merge.sh {
        entries = "${./merged-settings/entries.jq}";
        jq = lib.getExe pkgs.jq;
        manifest = "${manifest}";
        mergeJson = lib.getExe mergeJson;
      }
    );
  };
}
