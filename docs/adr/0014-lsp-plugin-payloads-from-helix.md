# The LSP plugin takes its payloads from Helix's languages.toml

Claude Code's LSP plugin has to give eight language servers the settings the
editors give them: astro-ls, clangd, gopls, jdtls, nixd, rust-analyzer,
terraform-ls and yaml-language-server. `modules/home/claude-code.nix` parses
this repository's `modules/home/helix/languages.toml` at evaluation time, fills
its placeholders with `substituteValue`, and sends each of the eight servers'
`config` as both `initializationOptions` and `settings`, since Claude Code hands
the first to the server as it is and answers `workspace/configuration` from the
second. `claude-code/nix-lsp.json` keeps only each server's command, arguments
and file extensions, and evaluation fails when one of the eight has no `config`.

A registry declaring each server once for Zed, Helix and the plugin was
rejected: about half the servers need a per-editor override, such as oxfmt's
option given twice for Helix, so the registry would carry every editor's shape
anyway. Helix's built-in `languages.toml` is not read either: it sits in a
fetched source, and reading it is import-from-derivation, which ADR-0004 rules
out.

The costs:

- A setting only Zed gives a server, such as jdtls's `java_home` or gopls's test
  code lens, does not reach Claude Code.
- Settings Helix takes from its built-in file, such as
  typescript-language-server's inlay hints, do not reach Claude Code either.
- A `config` shaped for Helix alone reaches Claude Code unchanged.
