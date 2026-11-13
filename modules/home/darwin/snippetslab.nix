{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  labPath = "/Applications/SnippetsLab.app/Contents/Helpers/lab";

  # `lab` on PATH without the documented `sudo ln -s` into
  # /usr/local/bin. It execs the bundle path rather than copying the
  # helper, which talks to the running app and updates with it through
  # the App Store; the trade is that `lab` exists even if the app is
  # removed, hence the explicit error.
  lab = pkgs.writeShellScriptBin "lab" (
    substituteFile ./snippetslab/lab.sh { lab = lib.escapeShellArg labPath; }
  );
in
{
  home.packages = [ lab ];

  my.agentSkills.generatedSkills = [ "snippetslab" ];

  home.activation.snippetslabSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    substituteFile ./snippetslab/skill.sh {
      lab = lib.escapeShellArg labPath;
      destinations = lib.escapeShellArgs config.my.agentSkills.destinations;
    }
  );
}
