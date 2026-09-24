{ config, ... }:
{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;

    # zsh runs only long enough to establish the environment before
    # exec'ing into nu, so its prompt is never drawn.
    enableZshIntegration = false;

    # Empty on purpose, which is starship's own default prompt. The
    # themes live in dracula-pro-extras and modules/home/nushell.nix
    # repoints STARSHIP_CONFIG at the variant; the value exported here
    # is the fallback for a starship invoked outside a themed nushell,
    # and is what keeps starship from hardcoding ~/.config.
  };
}
