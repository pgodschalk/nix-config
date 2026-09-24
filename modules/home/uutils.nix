{ pkgs, ... }:
{
  # The `-noprefix` build, so these are `ls` and `cat` rather than
  # `uutils-ls`. An explicit alias still wins, since Nushell resolves
  # one before it looks at PATH.
  #
  # They are GNU-compatible, so BSD spellings a personal script may use
  # -- `date -v-1d`, `mktemp -t NAME`, `stat -f %z` -- no longer work.
  home.packages = with pkgs; [
    uutils-coreutils-noprefix
    uutils-findutils
    uutils-diffutils
  ];
}
