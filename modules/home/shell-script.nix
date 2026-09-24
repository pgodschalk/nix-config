{ pkgs, ... }:
{
  home.packages = [
    pkgs.bash-language-server
    pkgs.fish-lsp

    # Not optional: bash-language-server has no diagnostics of its own
    # and shells out to shellcheck for them.
    pkgs.shellcheck

    # Both editors call shfmt directly with explicit flags, because the
    # server exposes no indent setting and shfmt defaults to tabs.
    pkgs.shfmt
  ];
}
