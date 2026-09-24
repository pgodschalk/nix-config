{ pkgs, ... }:
{
  # `moor`, not `moar`: upstream renamed both in 2.0, and the nixpkgs
  # alias warns on every evaluation.
  home.packages = [ pkgs.moor ];

  home.sessionVariables = {
    PAGER = "moor";
  };

  # MOOR, which carries the syntax-highlighting style, is set per
  # appearance variant in modules/home/nushell.nix.
  #
  # moor supports neither LESS_TERMCAP_* nor LESSOPEN, so the `less`
  # theme reaches only a directly invoked less, and a LESSOPEN filter
  # such as batpipe would be inert.
}
