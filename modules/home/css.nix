{ pkgs, ... }:
{
  # These add what vscode-css-language-server cannot: it sees only the
  # buffer in front of it, so `var(--` completes nothing from a token
  # file, tsgo cannot resolve `styles.cardTitle` into a `*.module.css`
  # without generated `.d.ts` files, and an SCSS variable from a file
  # reached through `@use` stays unknown.
  home.packages = [
    (pkgs.callPackage ../../pkgs/css-variable-lsp.nix { })
    (pkgs.callPackage ../../pkgs/cssmodules-language-server.nix { })
    (pkgs.callPackage ../../pkgs/some-sass-language-server.nix { })
  ];
}
