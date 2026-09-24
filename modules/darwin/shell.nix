{
  programs.zsh = {
    enable = true;

    shellInit = builtins.readFile ./shell/zshenv.sh;

    # Spliced verbatim into `HISTFILE=<value>` in /etc/zshrc, so the
    # value has to carry its own quotes around the space.
    histFile = ''"$HOME/Library/Application Support/zsh/history"'';

    # Defaults on, and emits a bare `compinit` with no `-d`, which would
    # write ~/.zcompdump.
    enableGlobalCompInit = false;
  };

  # The per-user profile links only these paths, and the fish completion
  # fallback in modules/home/completions.nix reads package completions
  # from it. Not the whole of share/fish: fish sources every
  # vendor_conf.d on each start, completions included.
  environment.pathsToLink = [ "/share/fish/vendor_completions.d" ];
}
