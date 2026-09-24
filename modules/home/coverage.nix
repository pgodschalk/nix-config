{ pkgs, ... }:
{
  # covhl tints lines through textDocument/documentColor, which Zed
  # renders according to the editor-wide `lsp_document_colors` in
  # modules/home/zed.nix; hover works without it.
  home.packages = [ (pkgs.callPackage ../../pkgs/covhl.nix { }) ];
}
