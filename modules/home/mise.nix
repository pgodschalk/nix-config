{
  lib,
  pkgs,
  ...
}:
let
  # A directory holding mise.nu rather than a bare file: Nushell takes a
  # module's name from the file stem, and a store path's stem carries
  # the hash, so `use` would define the wrapper as `<hash>-mise`. The
  # external binary still answers most calls, so only `mise shell`,
  # `mise use` and `mise deactivate` break, and silently.
  activate = pkgs.runCommand "mise-activate" { } ''
    mkdir -p $out
    ${lib.getExe pkgs.mise} activate nu > $out/mise.nu
  '';
in
{
  home.packages = [ pkgs.mise ];

  # `activate` rather than `--shims`, which would prepend a directory to
  # PATH permanently and shadow the Nix copies everywhere. The trade-off
  # is that a process started outside the shell, such as an editor's
  # language server, never sees mise's PATH.
  programs.nushell.extraConfig = lib.mkAfter ''
    use ${activate}/mise.nu *
  '';

  home.sessionVariables = {
    # base16 rather than the bundled dracula, which is plain Dracula and
    # fixed: base16 draws from the terminal's ANSI palette and so
    # follows the appearance.
    MISE_COLOR_THEME = "base16";
  };
}
