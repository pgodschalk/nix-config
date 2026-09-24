{ pkgs, ... }:
{
  # Provides `graphql-lsp`, which is the name Helix resolves on PATH. It
  # offers completion and navigation only: linting comes from biome and
  # formatting from oxfmt.
  home.packages = [ pkgs.graphql-language-service-cli ];
}
