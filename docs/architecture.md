# Architecture

How this flake is put together, and the conventions new code follows.
`CLAUDE.md` imports this file, so it is written for a reader who has not opened
the code yet.

- `flake.nix` outputs `darwinConfigurations.Patricks-MacBook-Pro` (named after
  `scutil --get LocalHostName`), `homeConfigurations."patrick@linux"` (a
  throwaway x86_64-linux configuration that exists only to be evaluated),
  `checks.aarch64-darwin` (the system build and the Linux eval, both under
  aarch64-darwin on purpose, see the comment there, plus merge-json's fixture
  tests, release-binary's archive-kind check and `lib/tests.nix` as `lib`, which
  `checks.x86_64-linux` carries for CI) and `packages.aarch64-darwin.*`,
  `nix run` tools that wrap `scripts/` plus nix-darwin's `darwin-rebuild`,
  re-exported for the first activation.
- `hosts/Patricks-MacBook-Pro/default.nix` is the nix-darwin system: it imports
  each `modules/darwin/*.nix` explicitly plus the work layer, declares
  `my.allowUnfree` (the host's only allowlist of unfree packages, by
  `lib.getName` name; the Linux eval allows every unfree package, so only the
  macOS eval catches a missing entry, and casks carry no licence and bypass it)
  and wires home-manager with `useGlobalPkgs`. Determinate owns Nix: settings go
  in `determinateNix.customSettings`, and `nix.package`, `nix.settings`,
  `nix.gc`, `nix.optimise` and `nix.linux-builder` cannot be set.
- `home/patrick/default.nix` imports `common.nix`, then `darwin.nix` or
  `linux.nix`. `common.nix` lists every `modules/home/*.nix`; `darwin.nix` lists
  `modules/home/darwin/*.nix`, remaps XDG into `~/Library` and adds casks with
  `lib.lowPrio`; `linux.nix` is headless and imports no GUI module.
- `modules/darwin/` is nix-darwin and macOS-only. `modules/home/` is
  home-manager and portable: it has to evaluate on Linux. `modules/home/darwin/`
  is home-manager and macOS-only. The split is by directory, not by guards
  inside modules, so only the Linux eval catches a leak.
- Imports are explicit lists. A new module goes into `common.nix`, `darwin.nix`
  or the host file, and nowhere else.
- `apps.nix` is pure data (no `pkgs` or `lib` at the top level), passed to every
  module as `apps`: App Store ids, cask tokens, and package lists as functions
  of `pkgs`. Most edits land here.
- `modules/home/options.nix` declares the `my.*` options whose consumers are
  macOS-only, so the Linux eval and the work layer's settings still succeed, and
  those shared across modules (the theme checkouts, the MCP servers). Any other
  option consumed by a portable module is declared in that module. A read-only
  option is declared by the module that sets it, such as `my.java.jdk` in
  `java.nix`, however many modules read it.
- `pkgs/` holds derivations nixpkgs lacks. There is no overlay: each consumer
  calls `pkgs.callPackage ../../pkgs/<name>.nix { }`. `pkgs/claude-marketplace/`
  is the local marketplace; `modules/home/claude-code.nix` renders the LSP
  plugin's `.lsp.json` from `claude-code/nix-lsp.json`'s commands and the
  `config` Helix's `languages.toml` gives eight of the servers (ADR-0014).
  `pkgs/lib/` holds the builders packages share, `release-binary.nix` for
  upstream release binaries, `bun-package.nix` for npm tarballs bun runs and
  `python-lsp-wheel.nix` for the Rust language servers PyPI ships as wheels; a
  caller reaches one through `callPackage` and passes its own arguments in a
  second call, so `callPackage` never fills them from `pkgs`.
- `lib/default.nix` provides `substituteFile path { name = value; }`: `@name@`
  substitution at evaluation time, asserting every replacement and every
  placeholder is matched. `substituteValue value { name = value; }` does the
  same into every string and attribute name of a parsed value, keeping
  store-path context; `lib/tests.nix` holds its cases, built as
  `checks.<system>.lib`. `builtins.readFile` of a `pkgs.replaceVars` result is
  import-from-derivation and breaks the Linux eval; use `substituteFile` for a
  string and `replaceVars` for a store file.
- `inputs`, `apps`, `substituteFile` and `substituteValue` reach every module as
  special arguments; home modules also get `isDarwin`, which
  `home/patrick/default.nix` needs inside `imports`, where anything derived from
  `pkgs` recurses infinitely. Inside `config`,
  `pkgs.stdenv.hostPlatform.isDarwin` is fine.

## Conventions

- Scripts, jq filters, TOML fragments and Nushell are real files in a directory
  named after the module (`modules/home/foo/bar.sh` beside
  `modules/home/foo.nix`, `pkgs/foo/install.sh` beside `pkgs/foo.nix`). Each is
  linted on its own, so a bare `@name@` where the language cannot parse one is
  avoided by moving the data to a side file (`theme-dirs.nuon`) or coercing it
  (`Number("@x@")`).
- Theme checkouts (`my.theme.dracula.*`) are nullable: anything linking into
  them is `lib.mkIf (extras != null)` with `mkOutOfStoreSymlink`.
- Apps that rewrite their own settings file (Claude Code, Claude desktop, Zed)
  get no link; their keys are merged or rendered by an activation entry after
  `writeBoundary`. Claude desktop's JSON is merged through `my.mergedSettings`
  (`modules/home/merged-settings.nix`), where new app-owned JSON goes too: an
  entry names the file, its declared value and a strategy for any top-level key
  that is not deep-merged (`replace` or `union`), and what it stops declaring is
  taken back at the next switch (ADR-0012). Claude Code's `settings.json` keeps
  its own entry, `claudePluginSettings`, and Zed's is rendered with its token.
- A skill reaches every directory in `my.agentSkills.destinations`, which
  `modules/home/claude-skills.nix` sets. A module adds a destination through
  `my.agentSkills.extraDirs`, or through `recursiveDirs` for a reader that does
  not descend into a linked directory, as `darwin/xcode.nix` does for the
  `nix-agents` plugin (with `subagentDirs` for its subagents). A skill an
  activation entry writes instead, such as SnippetsLab's, copies itself into
  each destination and names itself in `my.agentSkills.generatedSkills`, so the
  duplicate-name check covers it.
- `codebook.toml` at the root is this repository's spellcheck word list; jargon
  used in a comment goes there.
