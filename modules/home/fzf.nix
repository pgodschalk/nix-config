{
  lib,
  pkgs,
  ...
}:
let
  # Kept out of FZF_DEFAULT_OPTS: the Dracula Pro theme owns that
  # variable and rewrites it on every appearance change. fzf reads this
  # file first and merges the variable over it.
  defaultOpts = pkgs.writeText "fzf-defaults" ''
    --height=60%
    --layout=reverse
    --border=rounded
    --info=inline
    --preview-window=right,60%,border-left,~3
    --bind=ctrl-/:toggle-preview
    --bind=ctrl-u:preview-half-page-up
    --bind=ctrl-d:preview-half-page-down
  '';

  # The key bindings live in this generated script, and nothing reads
  # FZF_CTRL_T_COMMAND and friends until it is loaded. Nushell cannot
  # `source` it from a pipe, so it is written to the autoload
  # directory.
  integration = pkgs.runCommand "fzf-nushell-integration.nu" { } ''
    ${lib.getExe pkgs.fzf} --nushell > $out
  '';
in
{
  home.packages = [ pkgs.fzf ];

  xdg.configFile."nushell/autoload/_fzf_integration.nu".source = integration;

  home.sessionVariables = {
    FZF_DEFAULT_COMMAND = "fd --type file --hidden --follow --exclude .git";
    FZF_DEFAULT_OPTS_FILE = "${defaultOpts}";
    FZF_ALT_C_COMMAND = "fd --type directory --hidden --follow --exclude .git";
    FZF_ALT_C_OPTS = "--preview 'fd --max-depth 1 --color=always . {}'";

    FZF_CTRL_R_OPTS = "--no-sort --preview 'echo {}' --preview-window=down,4,wrap";
    FZF_CTRL_T_COMMAND = "fd --type file --type directory --hidden --follow --exclude .git";

    # --color=always because fzf pipes the preview rather than giving it
    # a terminal, so bat's own detection turns colour off.
    FZF_CTRL_T_OPTS = "--preview 'bat --color=always --style=numbers --line-range=:200 {}'";
  };
}
