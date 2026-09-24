{ pkgs, ... }:
{
  # The `-noprefix` build, so these are `ls` and `cat` rather than
  # `uutils-ls`. An explicit alias still wins, since Nushell resolves
  # one before it looks at PATH.
  #
  # They are GNU-compatible, so BSD spellings a personal script may use
  # -- `date -v-1d`, `mktemp -t NAME`, `stat -f %z` -- no longer work.
  #
  # diffutils is not at parity with GNU's, and its `diff` comes before
  # /usr/bin/diff for every caller, not only Nushell: it rejects `-r`,
  # `-N` and `--color`, and `diff -y` exits 0 on files that differ.
  home.packages = with pkgs; [
    uutils-coreutils-noprefix
    uutils-findutils
    uutils-diffutils
  ];
}
