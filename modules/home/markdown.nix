{ pkgs, ... }:
{
  # Four servers, each owning a different question:
  #
  #   marksman               navigation -- headings, wiki links,
  #                          references, symbols
  #   agnix-lsp              diagnostics for agent configuration --
  #                          CLAUDE.md, AGENTS.md, SKILL.md, hook and
  #                          MCP JSON
  #   skill-language-server  navigation for skill references
  #   markdownlint-lsp       style and structure of the prose
  home.packages = [
    pkgs.marksman

    # agnix's extension never calls `which` and would fetch a release of
    # its own; skill-language-server's resolves `which` first, so being
    # on PATH under that exact name pins it.
    (pkgs.callPackage ../../pkgs/agnix-lsp.nix { })
    (pkgs.callPackage ../../pkgs/markdownlint-lsp.nix { })
    (pkgs.callPackage ../../pkgs/skill-language-server.nix { })
  ];

  # `.agnix.toml` at the repo root turns off the prose-advice rules,
  # which fire on every deliberate "Do not …" line; the structural ones
  # stay on.
}
