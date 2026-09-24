{ pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ../../pkgs/deps-lsp.nix { }) ];

  # deps-lsp does not see this machine's GitHub Actions manifests:
  # modules/home/darwin/zed.nix gives them the dedicated GitHub Actions
  # language, and the extension claims YAML. A server cannot attach to
  # a language its extension never claimed.
}
