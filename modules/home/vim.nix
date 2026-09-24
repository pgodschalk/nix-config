{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  draculaPro = config.my.theme.dracula.pro;
  extras = config.my.theme.dracula.extras;

  # Vim 8+ loads anything under pack/*/start automatically, so the
  # upstream directory drops in whole: the variants are thin and defer
  # to a shared dracula-pro-base.vim.
  packDir = "vim/pack/themes/start/dracula-pro";

  # fzf's Vim integration is two plugins. The library -- fzf#run,
  # fzf#exec and :FZF -- ships inside the fzf distribution itself, which
  # is why there is no separate package for it, and the nixpkgs build
  # rewrites fzf#exec to an absolute store path. fzf.vim is the commands
  # built on top.
  fzfPlugin = "${pkgs.fzf}/share/vim-plugins/fzf";
  fzfVimPlugin = pkgs.vimPlugins.fzf-vim;

  # The appearance glue lives in dracula-pro-extras, so it can only be
  # sourced where that checkout exists.
  appearance =
    if extras == null then
      ''" No dracula-pro-extras checkout, so no appearance switching.''
    else
      ''
        " Dracula Pro in Dark Mode, Alucard in Light, re-checked on
        " focus.
        source ${extras}/src/vim/appearance.vim'';
in
{
  # macOS ships vim 9.1 with +termguicolors and +packages, so a second
  # copy would only shadow it. Elsewhere there may be no vim at all.
  home.packages = lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.vim ];

  # Vim reads $HOME/.vimrc, then $HOME/.vim/vimrc, then
  # $XDG_CONFIG_HOME/vim/vimrc, and only the first found -- so ~/.vimrc
  # must not exist for this to take effect. When the XDG vimrc is used,
  # vim adds $XDG_CONFIG_HOME/vim to 'runtimepath' and 'packpath'
  # itself, which is how pack/*/start below is found.
  xdg.configFile = {
    ${packDir} = lib.mkIf (draculaPro != null) {
      source = config.lib.file.mkOutOfStoreSymlink "${draculaPro}/themes/vim";
    };

    # Store paths rather than out-of-store symlinks: unlike the themes
    # these are not a working copy being edited.
    "vim/pack/fzf/start/fzf".source = fzfPlugin;
    "vim/pack/fzf/start/fzf.vim".source = fzfVimPlugin;

    # The viminfo path is substituted already-escaped: `:set` splits its
    # argument on whitespace, so the space in "Application Support" has
    # to be backslashed.
    "vim/vimrc".source = pkgs.writeText "vimrc" (
      substituteFile ./vim/vimrc.vim {
        viminfoFile = builtins.replaceStrings [ " " ] [ "\\ " ] "${config.xdg.stateHome}/vim/viminfo";
        inherit appearance;
      }
    );
  };
}
