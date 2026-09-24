# Architecture

How this flake is put together, and the conventions new code follows.
`CLAUDE.md` imports this file, so it is written for a reader who has not opened
the code yet.

- `flake.nix` outputs `darwinConfigurations.Patricks-MacBook-Pro` (named after
  `scutil --get LocalHostName`), `homeConfigurations."patrick@linux"` (a
  throwaway x86_64-linux configuration that exists only to be evaluated),
  `checks.aarch64-darwin` (both checks under aarch64-darwin on purpose; see the
  comment there) and `packages.aarch64-darwin.*`, `nix run` tools that wrap
  `scripts/`.
- `hosts/Patricks-MacBook-Pro/default.nix` is the nix-darwin system: it imports
  each `modules/darwin/*.nix` explicitly plus the work layer, declares
  `my.allowUnfree` (the only place an unfree package is allowed, by
  `lib.getName` name) and wires home-manager with `useGlobalPkgs`. Determinate
  owns Nix: settings go in `determinateNix.customSettings`, and `nix.package`,
  `nix.settings`, `nix.gc`, `nix.optimise` and `nix.linux-builder` cannot be
  set.
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
  macOS-only, so the Linux eval and the work layer's settings still succeed. An
  option consumed by a portable module is declared in that module.
- `pkgs/` holds derivations nixpkgs lacks. There is no overlay: each consumer
  calls `pkgs.callPackage ../../pkgs/<name>.nix { }`. `pkgs/claude-marketplace/`
  is the local marketplace; `modules/home/claude-code.nix` adds the LSP plugin's
  `.lsp.json`, filled with the same store paths the editors get.
- `lib/default.nix` provides `substituteFile path { name = value; }`: `@name@`
  substitution at evaluation time, asserting every placeholder exists.
  `builtins.readFile` of a `pkgs.replaceVars` result is import-from-derivation
  and breaks the Linux eval; use `substituteFile` for a string and `replaceVars`
  for a store file.
- `inputs`, `apps` and `substituteFile` reach every module as special arguments;
  home modules also get `isDarwin`, which `home/patrick/default.nix` needs
  inside `imports`, where anything derived from `pkgs` recurses infinitely.
  Inside `config`, `pkgs.stdenv.hostPlatform.isDarwin` is fine.

## Conventions

- Scripts, jq filters, TOML fragments and Nushell are real files in a directory
  named after the module (`modules/home/foo/bar.sh` beside
  `modules/home/foo.nix`, `pkgs/foo/install.sh` beside `pkgs/foo.nix`). Each is
  linted on its own, so a bare `@name@` where the language cannot parse one is
  avoided by moving the data to a side file (`theme-dirs.nuon`) or coercing it
  (`Number("@x@")`).
- Theme checkouts (`my.theme.dracula.*`) are nullable: anything linking into
  them is `lib.mkIf (extras != null)` with `mkOutOfStoreSymlink`.
- Apps that rewrite their own settings file (Claude Code, Claude desktop,
  Agentastic, Zed) get no link; their keys are merged or rendered by an
  activation entry after `writeBoundary`.
- `codebook.toml` at the root is this repository's spellcheck word list; jargon
  used in a comment goes there.
