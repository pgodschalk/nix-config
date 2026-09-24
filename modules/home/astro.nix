{ pkgs, ... }:
{
  home.packages = [
    # Ships as the `astro-ls` binary. It advertises
    # documentFormattingProvider and cannot honour it -- no prettier is
    # bundled -- so Helix formats .astro with prettier-astro from
    # pkgs/prettier-with-plugins.nix and Zed with its own bundled copy.
    pkgs.astro-language-server

    # Astro is the only remaining consumer: an .astro file gets its
    # TypeScript answers from here, while TypeScript, TSX and JavaScript
    # are on tsgo.
    pkgs.typescript-language-server
  ];
}
