{
  programs.zoxide = {
    enable = true;

    # zsh runs only long enough to establish the environment before
    # exec'ing into nu, so nothing ever types `z` at a zsh prompt.
    enableZshIntegration = false;
  };
}
