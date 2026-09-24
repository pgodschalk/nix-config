{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  updateAllScript = pkgs.writeTextFile {
    name = "update-all.nu";
    text = substituteFile ./update/update-all.nu {
      # Empty when there is no checkout, which update-all skips.
      themeExtras = toString config.my.theme.dracula.extras;
    };
  };

  # `nu <file>` rather than a Nushell module, which would take its name
  # from the file stem and so carry the store hash, and would be a
  # command only interactive Nushell knows.
  #
  # No `runtimeInputs`: every tool it drives is already on PATH, and
  # pinning them here would shadow the packages the run is updating.
  updateAll = pkgs.writeShellScriptBin "update-all" (
    substituteFile ./update/update-all.sh {
      nu = lib.getExe pkgs.nushell;
      script = "${updateAllScript}";
    }
  );
in
{
  home.packages = [ updateAll ];
}
