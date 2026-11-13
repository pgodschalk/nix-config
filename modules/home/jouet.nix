{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  jouet = pkgs.callPackage ../../pkgs/jouet.nix { };
in
{
  home.packages = [ jouet ];

  # What `jouet setup claude` installs, declared: its onboarding skill
  # and its hooks. The hook commands are setup's own, character for
  # character, so a manual `jouet setup claude` recognises them and
  # changes nothing.
  my.agentSkills.storeSkills.jouet-init = "${jouet}/share/jouet/skills/jouet-init";

  # After mergedSettings, which rewrites the same file.
  home.activation.jouetClaudeHooks =
    lib.hm.dag.entryAfter
      [
        "writeBoundary"
        "mergedSettings"
      ]
      (
        substituteFile ./jouet/merge-claude-hooks.sh {
          settings = lib.escapeShellArg "${config.xdg.configHome}/claude-code/settings.json";
          jq = "${pkgs.jq}/bin/jq";
          hooks = "${./jouet/claude-hooks.json}";
          filter = "${./jouet/claude-hooks.jq}";
        }
      );
}
