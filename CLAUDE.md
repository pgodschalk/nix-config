# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

One machine's Nix configuration: a nix-darwin system plus a home-manager user
environment, on Determinate Nix. There is no application code and no test suite;
"the tests" are that both configurations evaluate and the per-language checks
pass. `/etc/nix-darwin` symlinks here, so `darwin-rebuild` needs no `--flake`.
See @docs/architecture.md for the layout, the layering and the conventions new
code follows.

## Commands

The `work` input is a private employer layer that exists only on this machine.
Every `nix` command run anywhere else needs
`--override-input work path:./stubs/work`; the scripts in `.github/scripts/`
always pass it and are exactly what CI runs.

Flakes and every check see only files git knows about. A new file that is not in
the index fails with "path does not exist" naming the file rather than the
cause. This is a colocated jj repository; with plain git, `git add` it first.

```sh
# The macOS system. CI runs this on a macOS runner because
# claude-skills.nix reads fetched store paths at evaluation time.
.github/scripts/nix-eval.sh \
  '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'

# The portable half, forced through the whole module system on
# x86_64-linux: the only check that catches a macOS assumption
# leaking out of modules/home/darwin into modules/home. On this Mac
# run it after the macOS eval: git.nix reads two fetched sources at
# evaluation time and only the aarch64-darwin fetch can realise them
# here, so after a garbage collection this fails with "platform
# mismatch" until the macOS eval has run.
.github/scripts/nix-eval.sh \
  '.#homeConfigurations."patrick@linux".activationPackage.drvPath'

nix flake check --override-input work path:./stubs/work
darwin-rebuild build --flake /etc/nix-darwin   # builds, activates nothing
```

Activation is Patrick's to run: `sudo -H darwin-rebuild switch`, undone with
`sudo -H darwin-rebuild --rollback`. `nix flake update brew-api` refreshes cask
pins on its own. Garbage collection belongs to Determinate Nix rather than
`nh clean`.

### Per-language checks

One script per check in `.github/scripts/`, run by `ci.yml` on Linux with the
editor's own configuration, so a file clean in Zed is clean in CI. These run
unchanged on this Mac, from the profile or through `npx`/`uvx`:

```sh
.github/scripts/oxfmt-check.sh '*.json'     # or '*.jsonc', '*.yaml' '*.yml'
.github/scripts/schema-check.sh '*.json'    # or '*.yaml' '*.yml'
.github/scripts/markdown-format.sh
.github/scripts/tombi-check.sh lint         # or: format --check
.github/scripts/ty-check.sh
.github/scripts/shell-lint.sh
ruff check && ruff format --check
npx --yes markdownlint-cli2 '**/*.md'
```

`nix-format.sh`, `nix-lint.sh`, `nu-format.sh` and `nu-lint.sh` take their tool
from the x86_64-linux home configuration through `nix-tool.sh`,
`shell-format.sh` downloads a linux_amd64 shfmt and `xml-format.sh` runs
`apt-get`, so those six are Linux-only. The profile carries the same tools:

```sh
git ls-files '*.nix' | xargs nixfmt --check
git ls-files '*.nu' | xargs nufmt --dry-run
git ls-files '*.nu' | xargs nu-lint --format compact
git ls-files '*.sh' \
  | xargs shfmt --indent 2 --binary-next-line --case-indent --diff

# nixf-tidy, the linter behind nixd's diagnostics, is not on PATH.
# It prints [] when a file is clean.
nixf=$(nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro.pkgs.nixf')
"$nixf/bin/nixf-tidy" --variable-lookup <modules/home/git.nix
```

### Claude Code's own environment

- Inside the Bash sandbox `nix` cannot write its cache under Library/Caches and
  fails with "Operation not permitted"; run `nix` with the sandbox off.
- `git` prints `fsmonitor_ipc__send_query: unspecified error` inside the
  sandbox. It is noise; exit codes and output are unaffected.
- An agent hook (PostToolUse) checks this file, the agent docs and `CONTEXT.md`
  with `prettier-md` and markdownlint, and all but the glossary with
  `agnix validate`. CI's markdownlint config has no code-block exemption, so
  every line here stays within 80 columns.

## Git and jj

`main` is the bookmark CI runs on. The global commit hooks and jj's `ui.editor`
apply; this repository sets no `commitmsg.profile`, so the global commitlint
profile validates every message.

## Agent skills

### Issue tracker

GitHub issues on `pgodschalk/nix-config`, through `gh`. See
`docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, each label equal to its role name. See
`docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` at the root is the glossary and `docs/adr/` holds
the decisions. See `docs/agents/domain.md`.
