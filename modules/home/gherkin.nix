{ pkgs, ... }:
{
  # Zed's Cucumber extension resolves `worktree.which` before its npm
  # fallback, and zed.nix also points `lsp.cucumber.binary` here.
  home.packages = [ (pkgs.callPackage ../../pkgs/cucumber-language-server.nix { }) ];
}
