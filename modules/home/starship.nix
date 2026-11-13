{ config, lib, ... }:
let
  extras = config.my.theme.dracula.extras;
in
{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  my.launchd.extraVariables = [ "STARSHIP_CACHE" ];

  programs.starship = {
    enable = true;

    # zsh runs only long enough to establish the environment before
    # exec'ing into nu, so its prompt is never drawn.
    enableZshIntegration = false;

    # Empty on purpose, which is starship's own default prompt. The
    # themes live in dracula-pro-extras and the Variant variable below
    # repoints STARSHIP_CONFIG at the variant; the value exported here
    # is the fallback for a starship invoked outside a themed nushell,
    # and is what keeps starship from hardcoding ~/.config.
  };

  my.launchd.shellOnlyVariables = [ "STARSHIP_CONFIG" ];

  my.theme.variantVariables.STARSHIP_CONFIG = lib.mkIf (extras != null) {
    pro = "${extras}/src/starship/pro.toml";
    alucard = "${extras}/src/starship/alucard.toml";
  };
}
