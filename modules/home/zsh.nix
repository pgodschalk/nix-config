{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {

    # The default is a bare `compinit`, which dumps to ~/.zcompdump.
    # `:h` is zsh's dirname modifier.
    completionInit = ''
      autoload -U compinit
      _zcompdump=${lib.escapeShellArg "${config.xdg.cacheHome}/zsh/zcompdump"}
      [[ -d ''${_zcompdump:h} ]] || mkdir -p ''${_zcompdump:h}
      compinit -d "$_zcompdump"
      unset _zcompdump
    '';

    # /etc/zshenv exports the same path as ZDOTDIR, which is how zsh
    # finds these files at all. Stated rather than relying on the
    # home-manager default, which only points here from stateVersion
    # 26.05.
    dotDir = "${config.xdg.configHome}/zsh";
    enable = true;

    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
      extended = true;
    };
  };

  # home-manager writes a ~/.zshenv stub sourcing $ZDOTDIR/.zshenv. On
  # macOS /etc/zshenv exports ZDOTDIR before zsh looks for any user
  # file, so zsh reads $ZDOTDIR/.zshenv directly and the stub is dead.
  home.file.".zshenv".enable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin false;
}
