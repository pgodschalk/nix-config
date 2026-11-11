{ pkgs, ... }:
{
  # Zed's jsonl-lsp extension resolves `worktree.which("jsonl-lsp")`
  # before npm, and zed.nix also points `lsp.jsonl-lsp.binary` here.
  home.packages = [ (pkgs.callPackage ../../pkgs/jsonl-lsp.nix { }) ];

  # Helix loads queries by language name, and its `jsonl` language
  # uses the json grammar, so these inherit json's.
  xdg.configFile = {
    "helix/runtime/queries/jsonl/highlights.scm".source = ./jsonl/queries/highlights.scm;
    "helix/runtime/queries/jsonl/indents.scm".source = ./jsonl/queries/indents.scm;
    "helix/runtime/queries/jsonl/textobjects.scm".source = ./jsonl/queries/textobjects.scm;
  };
}
