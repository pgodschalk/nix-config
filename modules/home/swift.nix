{ pkgs, ... }:
{
  home.packages = [
    # Completes versions, branches and products in Package.swift, which
    # sourcekit-lsp cannot: it reads the file as ordinary Swift and
    # never reaches the network.
    (pkgs.callPackage ../../pkgs/package-swift-lsp.nix { })
  ];
}
