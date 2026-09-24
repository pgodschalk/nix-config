{ pkgs, ... }:
{
  # Both add what vscode-css-language-server cannot: it sees only the
  # buffer in front of it, so `var(--` completes nothing from a token
  # file, and tsgo cannot resolve `styles.cardTitle` into a
  # `*.module.css` without generated `.d.ts` files.
  home.packages = [
    (pkgs.callPackage ../../pkgs/css-variable-lsp.nix { })
    (pkgs.callPackage ../../pkgs/cssmodules-language-server.nix { })
  ];
}
