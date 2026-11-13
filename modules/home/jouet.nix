{ lib, pkgs, ... }:
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

  my.mergedSettings.claude-code.value.hooks = lib.importJSON ./jouet/claude-hooks.json;
}
