# Architecture deepening implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the shallow modules the 2026-11-12 architecture review found into
deep ones, and land the small fixes it found on the way, in the order below.

**Architecture:** Each card gives one concept a single owner: GUI variables are
declared beside their setters, the LSP plugin derives its payloads from Helix's
file, skills reach every destination from one list, Claude Code's settings join
`my.mergedSettings`, Variant variables are declared by their tools, wheels
become release binaries, and CI runs the editor's own Formatter wrapper. Fixes
land first, one commit each.

**Tech Stack:** Nix (nix-darwin, home-manager, nixpkgs builders,
`pkgs.formats.json`), jq (merge-json and its fixture tests), bash and Nushell
side files, the repository's check scripts and `mise` tasks.

**Spec:** the "Spec" section below; it is the decision record of the
2026-11-12/13 architecture review and its three grilling rounds, copied so the
plan travels with it.

## Spec

### Fixes, first, one commit each

- Add `CARGO_HOME`, `RUSTUP_HOME` and `XDG_BIN_HOME` to the GUI export (card 1
  later moves them beside their setters).
- snippetslab's skill reaches every destination, and joins the duplicate-name
  check (card 5 later moves it).
- `rex/claude-hook.sh` seeds a missing settings file like the other writers
  (card 4 later deletes it).
- Helix's Markdown `rulers` become `[73, 81]`; prettier-md wraps at 80.
- `pkgs/prettier-with-plugins.nix`: one `@VERSION`-annotated Astro version,
  interpolated into the compiler-rs, compiler-binding and per-target binding
  URLs (today `astroBindingVersion = "0.5.2"` against 0.5.3).
- `modules/home/nomad.nix` filters with `lib.meta.availableOn` instead of an
  `isDarwin` guard.
- `modules/home/commit-messages.nix` quotes each profile directory in its `case`
  patterns, so a directory holding a space works.
- `pkgs/lib/release-binary.nix` defaults `meta.mainProgram` to the first binary;
  the 11 callers stop restating it. `passthru.archive` gets its test: a flake
  check that maps URL suffixes to archive kinds.
- The LSP plugin's nixd `settings` take the wrapped `{ nixd = { … }; }` shape,
  which Claude Code walks by section.
- Stale comments: `pkgs/dockerhub-mcp-server.nix:10-12`, `java.nix` (nixpkgs
  runs jdtls on jdk25, not JDK 21), `ruby.nix:17-19`,
  `helix/languages.toml:697-701`, `launchd-env.nix` ("every variable redirects
  state").
- The commitlint skill's `@VERSION` names where its commit pin is read.
- GLOSSARY.md (Secret) and SECURITY.md count four login-keychain readers, Orca's
  forge-cli.sh included; CONTRIBUTING.md stops claiming CI runs every tool the
  editor runs.
- To test, not fix: the plugin sends Helix language names as LSP languageIds
  (`tsx`, `hcl`) where Helix sends `typescriptreact` and `terraform`. The task
  reports what it finds and commits nothing.

### Card 1: GUI variables

- Rule: a session variable is a GUI variable when a CLI an app spawns needs it
  to behave as in a shell: state redirects, tool locators, telemetry and update
  opt-outs, `SSH_AUTH_SOCK`, `HELM_REGISTRY_CONFIG`, `REGISTRY_AUTH_FILE`,
  `OP_ACCOUNT`, `AUBE_RUNTIME_INSTALLER`, `RESEND_CREDENTIAL_STORE` and
  `RESEND_NO_UPDATE_NOTIFIER`. Shell-only and never exported: `EDITOR`, `PAGER`,
  `MANPAGER`, `BAT_*`, `FZF_*`, `MISE_COLOR_THEME`, `STARSHIP_CONFIG`,
  `XDG_*_DIR`, `TERMINFO_DIRS`, `LC_ALL`, `LC_CTYPE`, `PYTHONIOENCODING`,
  `MANROFFOPT`, `NH_DARWIN_FLAKE`. `TERMINFO_DIRS` is set upstream, so
  `launchd-env.nix` names it beside the upstream `XDG_*_HOME` names.
- Every name this repository sets moves beside its setter through the existing
  `my.launchd.extraVariables` (name and shape unchanged, the work layer uses
  it). `launchd-env.nix` keeps only the names upstream home-manager sets
  (`XDG_{BIN,CACHE,CONFIG,DATA,STATE}_HOME`). PATH stays as it is.
- A module marks its shell-only names beside their setter through a new
  `my.launchd.shellOnlyVariables` (list of names, declared beside
  `my.launchd.extraVariables`); `MOOR` and `PAGER` are among them.
- Evaluation fails for an exported value holding `'`, `$` or a newline, and for
  a session variable whose value lies under the home directory that is neither
  exported nor shell-only.
- Precondition for the home-directory check: the work layer at its locked
  revision sets `CLOUDSDK_CONFIG`, `PI_AGENT_DIR`, `PI_CODING_AGENT_DIR` and
  `VIBE_HOME` without exporting them. That check's task waits until Patrick has
  merged the work layer's export and bumped the `work` lock, and it evaluates
  against the real work layer as well as the stub.
- ADR-0013 is amended in place to the rule above; GLOSSARY.md gains **GUI
  variable**: a session variable launchd also exports to processes started from
  the Dock or by an app, so a CLI an app spawns behaves as in a shell.

### Cards 2 and 3: language servers

- `lib/default.nix` gains `substituteValue value replacements`: `@name@`
  substitution into every string and attribute name of a parsed value, with
  `substituteFile`'s two assertions (a replacement with no placeholder, a
  placeholder with no replacement unless passed as null).
- `claude-code.nix` parses the raw `modules/home/helix/languages.toml` with
  `builtins.fromTOML`, fills it with `substituteValue`, and takes the `config`
  of astro-ls, clangd, gopls, jdtls, nixd, rust-analyzer, terraform-ls and
  yaml-language-server into both `initializationOptions` and `settings`. The
  plugin's `.lsp.json` is rendered with `pkgs.formats.json` from
  `modules/home/claude-code/nix-lsp.json`, which keeps only `command`, `args`
  and `extensionToLanguage`. Evaluation fails when one of the eight has no
  `config`.
- Dropped from the plugin: the payloads copied from Helix's built-in config
  (typescript-language-server with `hostInfo: "helix"`, vscode-css, -html and
  -json), gopls's `codelenses.test` and jdtls's `java_home`.
- `helix.nix` declares a read-only `my.nixd.settings`: the unescaped
  `{ nixpkgs.expr; options.<kind>.expr; options.home-manager.expr; }` for this
  platform; Zed's `lsp.nixd.settings` reads it, and the checkout path and host
  are written once.
- `pkgs/lib/release-binary.nix` takes a `passthru ? { }` argument;
  `pkgs/mbx.nix` exposes `passthru.cargoShim`, read by every file that spells
  `libexec/mbx` today (`rust.nix`, `helix.nix`, `claude-code.nix`,
  `darwin/zed.nix`, `modules/darwin/launchd-env.nix`).
- New ADR: the LSP plugin derives only payloads from this repository's
  `languages.toml`; no three-editor language-server registry, because about half
  the servers need per-editor overrides and Helix's built-in file needs
  import-from-derivation.

### Card 5: skills

- `claude-skills.nix` exposes a read-only option listing every skill
  destination; `my.agentSkills.extraDirs` stays for the work layer; a new
  `my.agentSkills.recursiveDirs` takes destinations linked recursively, and
  `modules/home/darwin/xcode.nix` contributes the Xcode plug-in through it.
- snippetslab's skill moves into the existing
  `modules/home/darwin/snippetslab.nix` (today the `lab` wrapper), whose
  activation entry copies the generated skill into every listed destination.
- commitlint becomes a one-file directory skill in `skillSingles`, inside the
  duplicate-name check. Its old real directories are removed by a command
  Patrick runs before that switch, so home-manager does not back them up beside
  the new link.
- Every value in `claude-skills/ecc-overlaps.nix` must be a skill this module
  links, a `plugin:skill` whose plugin is enabled, or an explicit external
  marker; anything else fails evaluation.
- ECC's `git-workflow` is linked again (its overlap entry goes). The skill index
  routes "Merge or rebase conflict" to `git-workflow`, in the canonical
  `~/Library/Application Support/claude-code/skill-index.md` and every Orca
  profile's copy that carries the line.
- The set of enabled plugins has one source, a read-only
  `my.claudeCode.enabledPlugins`; the cover check and card 4's entry both read
  it.

### Card 4: Claude Code on `my.mergedSettings`

- merge-json strategies may sit at nested paths, spelled in the value's own
  shape: `strategies.hooks.PreToolUse = "union"`. A string leaf names the
  strategy; an attribute set descends.
- `claude-code.nix` owns the `claude-code` entry (its file, `union` on every
  `hooks.<Event>` and on `permissions.deny`); claude-code, jouet and rex write
  their keys and agent-hook groups straight into
  `my.mergedSettings.claude-code.value`. Evaluation fails on an event name
  outside Claude Code's 33.
- `enabledPlugins` is deep-merged: plugins Nix stops declaring are taken back,
  ones enabled by hand stay.
- The first switch, with no state yet, removes the groups matching the four old
  fingerprints (`/bin/claude-vcs-guard`, `/bin/claude-md-lint`,
  `jouet hook claude` followed by a space, `rex __internal session-start`)
  before merging; a follow-up commit deletes that migration once Patrick has
  switched.
- `claudePluginSettings`, `settings.jq`, `merge-settings.sh`, jouet's and rex's
  jq filters and scripts go. ADR-0012 is amended in place.

### Card 7: Variant variables

- `modules/home/options.nix` declares
  `my.theme.variantVariables.<NAME> = { pro; alucard; }`, an option shared
  across modules; `nushell.nix` renders `pro.env` and `alucard.env` from it in
  pure Nix; the owning modules declare their pairs: `starship.nix`
  (STARSHIP_CONFIG), `git.nix` (GIT_CONFIG_GLOBAL with its gitconfig shim,
  DFT_BACKGROUND), `ripgrep.nix` (RIPGREP_CONFIG_PATH), `commit-messages.nix`
  (LUMEN_THEME), `moor.nix` (MOOR). Values pointing into a theme checkout stay
  behind `lib.mkIf (extras != null)`.
- Evaluation fails unless both variants define the same names, every value is
  one line, and every name is a plain variable name.
- MOOR's non-theme flags
  (`--no-linenumbers --quit-if-one-screen --statusbar=bold`) move to
  `moor.nix`'s session variables. moor reads the one variable and `load-env`
  replaces it whole, so each Variant's MOOR is its `--style=` followed by
  `moor.nix`'s flags, from one binding.
- `path-themes.sh`, `path-themes/variant.env` and `variant.gitconfig` go.
  GLOSSARY.md gains **Variant variable**: an environment variable whose value
  differs per Variant, set by the themed shell at each Appearance switch.

### Card 6: wheels

- `pkgs/pytest-language-server.nix` and `pkgs/django-language-server.nix` call
  release-binary with PyPI's name-based URLs
  (`https://files.pythonhosted.org/packages/py3/<letter>/<project>/<filename>`),
  interpolating only the version and spelling each filename per system.
- release-binary gains a `wheel` archive kind (from a `.whl` URL): unzip, then
  install each binary from `*.data/scripts/`. `pkgs/lib/python-lsp-wheel.nix`
  and `modules/home/python-lsps-wheels.nix` go; `python-lsps.nix` adds both
  packages through `lib.meta.availableOn`.

### Card 8: formatters

- `formatters.nix` declares a read-only `my.formatters`: wrapper name to
  derivation, prettier-with-plugins' wrappers included. `nix-tool.sh` gains a
  form that resolves it under each platform's prefix; `markdown-format.sh` runs
  `prettier-md`.

### Documentation-only

- New ADRs: no package scope for `pkgs/` (special arguments cannot carry the
  host's unfree predicate; calling by path already gives locality), and
  Appearance followers stay one central list (issue #31).

## Global Constraints

- Every task ends with `mise run test` and `mise run lint` passing, run with the
  Bash sandbox off, then one unsigned commit:
  `git -c commit.gpgsign=false commit`. This worktree uses git, not jj;
  `git add` a new file before any evaluation sees it.
- Commit messages: Conventional Commits, subject at most 50 characters, body
  wrapped at 72 saying why, no trailers.
- Comments: none by default; at most 72 columns; present tense; no history,
  dates, measurements or attributions. Upstream comments stay as written.
- A hand-bumped pin carries `# @VERSION <url>` on the line above it.
- Code in another language goes in its own file beside its module, never in a
  Nix string.
- Portable modules evaluate on `homeConfigurations."patrick@linux"` with the
  theme checkouts null; macOS-only code lives under `modules/home/darwin/` or
  `modules/darwin/`.
- A read-only option is declared by the module that sets it; one consumed by a
  macOS-only module or shared across modules goes in `modules/home/options.nix`;
  any other in the portable module that consumes it.
- `substituteFile` for strings, `replaceVars` for store files; no
  import-from-derivation.
- Options the work layer uses keep their names and shapes:
  `my.launchd.extraVariables`, `my.agentSkills.extraDirs`,
  `my.agentSkills.storeSkills`, `my.mergedSettings`, `my.mcp.servers`.
- New jargon in a comment goes into `codebook.toml`.
- Every new flake check gets its own CI job, shaped like the `merge-json` job, a
  `mise` task beside `check:merge-json`, and a mention where `CLAUDE.md` lists
  the tests.
- A task that touches an option or activation entry the work layer can see also
  evaluates `.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath` without
  `--override-input`, against the real work layer, printing only the path or the
  error.
- Every line of this plan, code blocks included, is at most 80 columns; CI's
  markdownlint has no code-block exemption.

## Review Focus

- The real work layer: every per-task gate evaluates against `stubs/work`. Tasks
  touching an option the work layer sees also evaluate the real layer, but its
  activation entries first run at Patrick's switch.
- The first switch onto card 4: merge-json's read-modify-write of Claude Code's
  `settings.json` can race Claude Code itself, Orca and the Appearance watcher.
  After the switch, C4.5's query must show each Nix agent-hook group exactly
  once before the migration is deleted.
- C5.4 turns `committing-with-commitlint` from a real directory into a link in
  every flat destination, the work layer's included; skipping its pre-switch
  command leaves an `hm-backup` copy that later dangles.
- The first Linux builds happen in CI: prettier-with-plugins for x86_64-linux
  (C8.2) and the wheels' unzip and autoPatchelf (C6.1). A red Markdown check
  after a push may be a build failure, not a formatting one.
- Card 1's GUI variables reach apps only after the switch, a new login and each
  app's relaunch. `SSH_AUTH_SOCK` then sends ssh and git from apps through
  Secretive, so Touch ID prompts appear there and fail when Secretive is not
  running.
- Never run `darwin-rebuild` or `sudo`; activation is Patrick's.

---

## Section F: Fixes

The Spec's "Fixes, first, one commit each", in its order. Read these before any
task:

- Line numbers are as of HEAD `a07c2f4`. Where an earlier F task has shifted
  them (F12 in `claude-skills.nix` after F2, F13 in `GLOSSARY.md` after F9),
  anchor on the quoted text, not the number.
- Run from the repository root. Every `nix`, `mise` and `.github/scripts/*`
  command runs with the Bash sandbox off. A sandbox-off call gets a different
  `$TMPDIR` from a sandboxed one, so create, use and read a temporary file
  within one Bash call.
- This worktree uses git. `git add` a new file before any evaluation, or the
  flake reports "path does not exist".
- Formatters, as CI runs them:

  ```bash
  # Nix
  "$(.github/scripts/nix-tool.sh nixfmt)" FILE
  # Shell
  "$(.github/scripts/nix-tool.sh shfmt)" --indent 2 --binary-next-line \
    --case-indent --write FILE
  # JSON
  "$(.github/scripts/nix-tool.sh oxfmt)" \
    -c modules/home/oxc/oxfmtrc.json FILE
  # Markdown
  "$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
    --prose-wrap=always --print-width=80 FILE
  ```

- Every comment you write is at most 72 columns, present tense, and states no
  history. Check with `awk 'length > 72 && /^ *#/ {print FILENAME":"FNR}' FILE`.
  The output may list the `# @VERSION <url>` lines that are already there, which
  are exempt.
- F1, F2, F3 and F7 touch something the work layer sets or sees: the launchd
  export list its `my.launchd.extraVariables` joins, the skill destinations its
  `my.agentSkills.extraDirs` adds to, an activation entry, and the
  `my.commitMessages.profiles` it sets. Each of them also evaluates the macOS
  system against the real work layer, with no `--override-input`. The command
  prints only a store path or the error:

  ```bash
  nix eval --raw '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'
  ```

  Expected: one `/nix/store/<hash>-darwin-system-<version>.drv` path. On an
  error, stop and report it to Patrick, since the fix may belong in his work
  repository.

- The last two steps of every task but F14 are the same. Run `mise run test` and
  then `mise run lint`, sandbox off, and expect both to exit 0. Then commit with
  the exact `git add` and `git -c commit.gpgsign=false commit` shown. Each `-m`
  body is already wrapped at 72, one paragraph. F14 changes no file and commits
  nothing.
- A line starting **After the switch** or **In CI** closes a task whose effect
  no evaluation here shows. It says what Patrick checks, and when.

### Task F1: Export the Rust homes and XDG_BIN_HOME to GUI processes

**Files:**

- Modify: `modules/darwin/launchd-env.nix:18-43` (`redirectNames`)

**Interfaces:**

- Consumes: `home.sessionVariables.CARGO_HOME` and `RUSTUP_HOME`
  (`modules/home/rust.nix:11-12`), and `XDG_BIN_HOME`, which home-manager sets
  (`/Users/patrick/Library/Scripts` here).
- Produces: `launchd.user.envVariables.{CARGO_HOME,RUSTUP_HOME,XDG_BIN_HOME}` on
  `darwinConfigurations.Patricks-MacBook-Pro`. `redirectNames` keeps its name
  and lists the three new names; C1.1 later moves each one beside its setter.

- [ ] **Step 1: Write the failing test**

```bash
nix eval --override-input work path:./stubs/work --json \
  .#darwinConfigurations.Patricks-MacBook-Pro.config.launchd.user.envVariables \
  --apply '
    v: map (n: builtins.hasAttr n v)
      [ "CARGO_HOME" "RUSTUP_HOME" "XDG_BIN_HOME" ]'
```

- [ ] **Step 2: Run it and see it fail**

Expected: `[false,false,false]`

- [ ] **Step 3: Add the three names in ASCII order**

In `redirectNames`, put `"CARGO_HOME"` after `"BUN_INSTALL"` (line 24),
`"RUSTUP_HOME"` after `"PITCHFORK_STATE_DIR"` (line 35) and `"XDG_BIN_HOME"`
before `"XDG_CACHE_HOME"` (line 37). Leave the comment above the list alone,
because F11 rewrites it.

- [ ] **Step 4: Run the test and see it pass**

Expected: `[true,true,true]`. Then check the values:

```bash
nix eval --override-input work path:./stubs/work --json \
  .#darwinConfigurations.Patricks-MacBook-Pro.config.launchd.user.envVariables \
  --apply 'v: { inherit (v) CARGO_HOME RUSTUP_HOME XDG_BIN_HOME; }' | jq .
```

Expected:

```json
{
  "CARGO_HOME": "/Users/patrick/Library/Application Support/cargo",
  "RUSTUP_HOME": "/Users/patrick/Library/Application Support/rustup",
  "XDG_BIN_HOME": "/Users/patrick/Library/Scripts"
}
```

- [ ] **Step 5: Evaluate against the real work layer**, with the section's
      command. Expected: one `.drv` path.

- [ ] **Step 6: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 7: Commit**

```bash
git add modules/darwin/launchd-env.nix
git -c commit.gpgsign=false commit \
  -m "fix(launchd): export Rust homes and XDG_BIN_HOME" \
  -m "A cargo or rustup that an editor spawns saw neither CARGO_HOME nor
RUSTUP_HOME and fell back to ~/.cargo and ~/.rustup, and installers
started from an app missed XDG_BIN_HOME. The three join the exported
list until each moves beside the module that sets it."
```

### Task F2: Copy snippetslab's skill everywhere and check its name

**Files:**

- Modify: `modules/home/claude-skills.nix:105-116` (`duplicateSkills`), the
  lines after `:156` (a new `skillDirs`) and `:345-352`
  (`home.activation.snippetslabSkill`)
- Modify: `modules/home/claude-skills/snippetslab-skill.sh:1-25`

**Interfaces:**

- Produces (let bindings in `claude-skills.nix`; C5 removes both):
  - `skillDirs` (Step 6): every skill destination as an absolute path, Claude
    Code's skills directory first, then `~/.agents/skills`, the work layer's
    extra directories and the Xcode plug-in's. The first one is where the skill
    is generated. C5.1 deletes this binding and its comment, and sets
    `skillFiles` from its read-only destination list, which keeps the
    claude-code skills path first.
  - `generatedSkills` (Step 5): the names that reach the skill directories
    outside `groupedSkills`, `skillSingles`, `localSkills` and `storeSkills`.
    C5.3 deletes this binding, its comment and its `map ... generatedSkills`
    term, and feeds the check from the option `my.agentSkills.generatedSkills`
    instead, when the activation moves into the existing
    `modules/home/darwin/snippetslab.nix` (today the `lab` wrapper).
- Produces: `snippetslab-skill.sh` takes one placeholder, `@skillFiles@`. It is
  a bash array body of shell-quoted absolute `.../snippetslab/SKILL.md` file
  paths, never directories, one for each entry of `skillDirs`. The `agentSkill`
  and `claudeSkill` placeholders go. C5.3 moves the script to
  `modules/home/darwin/snippetslab/skill.sh` and replaces the placeholder with
  `@destinations@`.
- Unchanged: the assertion text
  `claude-skills: more than one collection provides <names>`.

- [ ] **Step 1: Write the destinations test**

It reads the rendered array, the one line that decides where activation writes,
into a real array, and prints its length and entries. The `sed` shortens
`/Users/patrick/Library/Application Support/` to `AS/` and `/Users/patrick/` to
`~/`:

```bash
line=$(nix eval --override-input work path:./stubs/work --raw \
  '.#darwinConfigurations.Patricks-MacBook-Pro.config' --apply '
    c: c.home-manager.users.patrick.home.activation.snippetslabSkill.data' \
  2>/dev/null | grep -F '  skillFiles=(')
if [ -z "$line" ]; then
  echo "NO skillFiles ARRAY"
else
  eval "$line"
  echo "${#skillFiles[@]}"
  printf '%s\n' "${skillFiles[@]}" | sed \
    -e 's|^/Users/patrick/Library/Application Support/|AS/|' \
    -e 's|^/Users/patrick/|~/|'
fi
```

- [ ] **Step 2: Run it and see it fail**

Expected: `NO skillFiles ARRAY`. The script still takes `agentSkill` and
`claudeSkill`, two paths only.

- [ ] **Step 3: Write the duplicate-name test**

```bash
nix eval --override-input work path:./stubs/work --json \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
    c:
    let
      ext = c.extendModules {
        modules = [
          {
            home-manager.users.patrick.my.agentSkills.localSkills = {
              snippetslab = "/tmp/a";
              committing-with-commitlint = "/tmp/b";
            };
          }
        ];
      };
    in
    builtins.length (builtins.attrNames
      ext.config.home-manager.users.patrick.home.file)' \
  2>&1 | sed -n \
    -e 's/.*error: claude-skills: more than one collection //p' \
    -e '/^[0-9][0-9]*$/p'
```

- [ ] **Step 4: Run it and see it fail**

Expected: a bare count (`1356` at `a07c2f4`) and no error, because neither name
is checked.

- [ ] **Step 5: Add `generatedSkills` to the duplicate check**

In `claude-skills.nix`, just above `duplicateSkills` (line 105), add:

```nix
  # Skills that reach the skill directories outside the sets above:
  # commitlint as a bare file, snippetslab by activation on macOS.
  generatedSkills = [
    "committing-with-commitlint"
  ]
  ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "snippetslab";
```

Then append `++ map (n: lib.nameValuePair n null) generatedSkills` to the list
that `lib.groupBy` takes (lines 110-113). `groupBy` reads only `.name`.

- [ ] **Step 6: Add `skillDirs` and pass every destination to the activation**

After `xcodeSkillsDir` (line 156):

```nix
  # Absolute, for the activation entry below; `agentSkills` is
  # home-relative because home.file takes it that way.
  skillDirs = [
    skillsDir
    agentSkillsHome
  ]
  ++ extraSkillDirs
  ++ [ xcodeSkillsDir ];
```

In `home.activation.snippetslabSkill`, replace the two arguments `agentSkill`
and `claudeSkill` (lines 348-349) with the one below, and run nixfmt, which
decides its final line breaks:

```nix
          skillFiles = lib.escapeShellArgs (
            map (dir: "${dir}/snippetslab/SKILL.md") skillDirs
          );
```

- [ ] **Step 7: Rewrite `snippetslab-skill.sh` to fill every file**

The new script generates into the first file and copies that file to the rest.
It keeps the `DRY_RUN` guard and the not-installed message:

```bash
# shellcheck shell=bash

# Generated rather than linked, because the text lives inside the app
# and changes with it. Copied rather than symlinked, since every
# destination is outside the store.
lab=/Applications/SnippetsLab.app/Contents/Helpers/lab

if [ -x "$lab" ]; then
  skillFiles=(@skillFiles@)
  for skill in "${skillFiles[@]}"; do
    run mkdir -p "$(dirname "$skill")"
  done

  # Guarded rather than wrapped in `run`, which under a dry run would
  # echo the command into the redirect's target.
  if [[ ! -v DRY_RUN ]]; then
    first=${skillFiles[0]}
    if "$lab" skill show >"$first.tmp"; then
      mv -f "$first.tmp" "$first"
      for skill in "${skillFiles[@]:1}"; do
        cp -f "$first" "$skill"
      done
    else
      rm -f "$first.tmp"
    fi
  fi
else
  echo "claude-skills: SnippetsLab not installed; skipping its agent skill" >&2
fi
```

Step 9 rewrites the `lab=` line and the indented `skillFiles=` line by pattern,
so keep both exactly as shown.

- [ ] **Step 8: Run both tests and see them pass**

Step 1 prints exactly:

```text
3
AS/claude-code/skills/snippetslab/SKILL.md
~/.agents/skills/snippetslab/SKILL.md
AS/claude-marketplace/plugins/nix-agents/skills/snippetslab/SKILL.md
```

Three entries show the quoting holds: an unquoted space would split a path in
two. Every entry ends in `/snippetslab/SKILL.md`, a file. Step 3 prints
`provides committing-with-commitlint, snippetslab`, the tail of the
`claude-skills: more than one collection` error.

- [ ] **Step 9: Run the rendered script against a stub `lab` under a scratch
      root**

It renders the activation with one extra directory, moves every destination from
`/Users/patrick/` to a scratch root, and runs it with a stand-in for
home-manager's `run`. The array is the one the configuration renders, so a
directory where a file path belongs, or a missing destination, shows here:

```bash
d=$(mktemp -d "${TMPDIR:-/tmp}/snippetslab.XXXXXX")
nix eval --override-input work path:./stubs/work --raw \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
    c:
    let
      ext = c.extendModules {
        modules = [
          {
            home-manager.users.patrick.my.agentSkills.extraDirs = [
              "/Users/patrick/extra skills"
            ];
          }
        ];
      };
      hm = ext.config.home-manager.users.patrick;
    in
    hm.home.activation.snippetslabSkill.data' \
  2>/dev/null >"$d/skill.sh"
printf '#!/bin/sh\necho stub skill\n' >"$d/lab" && chmod +x "$d/lab"
sed -i.bak \
  -e "s|^lab=.*|lab='$d/lab'|" \
  -e "/^  skillFiles=/s|/Users/patrick/|$d/root/|g" \
  "$d/skill.sh"
grep -q "^  skillFiles=('$d/root/" "$d/skill.sh" \
  && ! grep '^  skillFiles=' "$d/skill.sh" | grep -q /Users/patrick/ \
  || { echo "sed missed; not running"; exit 1; }
bash -c 'run() { "$@"; }; source "$1"' _ "$d/skill.sh"
(
  cd "$d/root" || exit 1
  find . -type f | LC_ALL=C sort \
    | sed 's|^\./Library/Application Support/|AS/|'
  find . -type f -exec cat {} + | uniq -c | awk '{$1 = $1; print}'
)
```

Expected:

```text
./.agents/skills/snippetslab/SKILL.md
AS/claude-code/skills/snippetslab/SKILL.md
AS/claude-marketplace/plugins/nix-agents/skills/snippetslab/SKILL.md
./extra skills/snippetslab/SKILL.md
4 stub skill
```

Four files, each the stub's output, and no `SKILL.md.tmp`. The guard runs the
script only when every entry of the array has moved under `$d/root`, so the test
never writes the real skill directories.

- [ ] **Step 10: Evaluate against the real work layer**, with the section's
      command. Expected: one `.drv` path. The work layer sets
      `my.agentSkills.extraDirs` and `localSkills`, which meet the new
      destinations and the duplicate check here.

- [ ] **Step 11: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 12: Commit**

```bash
git add modules/home/claude-skills.nix \
  modules/home/claude-skills/snippetslab-skill.sh
git -c commit.gpgsign=false commit \
  -m "fix(claude-skills): copy snippetslab everywhere" \
  -m "The generated snippetslab skill reached only Claude Code's and the
cross-agent directory, so the work layer's extra directories and the
Xcode plug-in never had it. Activation now copies it into every skill
directory, and snippetslab and committing-with-commitlint, which no
collection lists, join the duplicate-name check."
```

**After the switch:** Patrick runs the command below, adds each directory in the
real `my.agentSkills.extraDirs` to it, and expects one hash throughout and no
`SKILL.md.tmp`. Xcode may list the skill only after nix-agents is imported
again.

```bash
bash -c 'as="$HOME/Library/Application Support"
shasum -a 256 "$HOME/.agents/skills/snippetslab/SKILL.md" \
  "$as/claude-code/skills/snippetslab/SKILL.md" \
  "$as/claude-marketplace/plugins/nix-agents/skills/snippetslab/SKILL.md"'
```

### Task F3: Seed a missing settings file in Rex's hook writer

**Files:**

- Modify: `modules/home/darwin/rex/claude-hook.sh:3-5`. Insert two lines after
  line 3.

**Interfaces:**

- Produces: `home.activation.rexClaudeHook` creates the directory of
  `${config.xdg.configHome}/claude-code/settings.json` and an `{}` file when
  either is missing, as `modules/home/jouet/merge-claude-hooks.sh:4-5` does.
  C4.4 later deletes this writer.

- [ ] **Step 1: Write the test**

It renders the activation entry, points it at a scratch path that does not
exist, and runs it with a stand-in for home-manager's `run`. The last line
prints the hook groups with each command shortened to `CMD`:

```bash
nix build --no-link --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro.pkgs.jq.bin'
d=$(mktemp -d "${TMPDIR:-/tmp}/rex-hook.XXXXXX")
nix eval --override-input work path:./stubs/work --raw \
  '.#darwinConfigurations.Patricks-MacBook-Pro.config' --apply '
    c: c.home-manager.users.patrick.home.activation.rexClaudeHook.data' \
  2>/dev/null >"$d/hook.sh"
sed -i.bak "s|^settings=.*|settings='$d/fresh/settings.json'|" "$d/hook.sh"
grep -q "^settings='$d/fresh/settings.json'$" "$d/hook.sh" \
  || { echo "sed missed; not running"; exit 1; }
bash -c 'run() { "$@"; }; source "$1"' _ "$d/hook.sh"
jq -c '.hooks.SessionStart | .[].hooks[].command |= "CMD"' \
  "$d/fresh/settings.json"
```

The `grep` guard keeps the test away from the real `settings.json`.

- [ ] **Step 2: Run it and see it fail**

Expected: `.../fresh/settings.json.tmp: No such file or directory`, then
`mv: cannot stat '.../fresh/settings.json.tmp': No such file or directory`, then
jq's `Could not open .../fresh/settings.json: No such file or directory`.

- [ ] **Step 3: Seed the file**

After `settings=@settings@`, insert exactly the two lines jouet's writer has:

```bash
run mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' >"$settings"
```

- [ ] **Step 4: Run the test and see it pass**

Expected: `[{"hooks":[{"type":"command","command":"CMD","timeout":5}]}]`

Then run Step 1's block again with these three lines in place of its last `jq`
command. The added `source` line runs the hook a second time:

```bash
bash -c 'run() { "$@"; }; source "$1"' _ "$d/hook.sh"
jq -r '.hooks.SessionStart[].hooks[].command' "$d/fresh/settings.json"
jq '.hooks.SessionStart | length' "$d/fresh/settings.json"
```

Expected:

```text
/bin/sh -c 'rex __internal session-start --agent claude 2>/dev/null || true'
1
```

The `1` shows the filter replaces its own group rather than adding a second.

- [ ] **Step 5: Evaluate against the real work layer**, with the section's
      command. Expected: one `.drv` path.

- [ ] **Step 6: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 7: Commit**

```bash
git add modules/home/darwin/rex/claude-hook.sh
git -c commit.gpgsign=false commit \
  -m "fix(rex): seed a missing Claude settings file" \
  -m "Rex's hook merge ran jq on settings.json and redirected into a file
beside it, so with no settings file or directory yet it failed. It
now creates both first, as jouet's merge does, instead of relying on
the main settings merge having run before it."
```

### Task F4: Rule Helix's Markdown at prettier-md's width

**Files:**

- Modify: `modules/home/helix/languages.toml:9-11` (header) and `:272`
  (`rulers = [73, 101]` in the `markdown` block)

**Interfaces:**

- Consumes: `[editor] rulers = [73, 81]` in `modules/home/helix/config.toml:8`.
- Produces: the `markdown` language sets no `rulers` and inherits `[73, 81]`.
  C23.4 parses this file with `builtins.fromTOML`, and nothing there reads
  `rulers`.

- [ ] **Step 1: Write the failing test**

```bash
nix eval --impure --json --expr '
  let
    toml = f: builtins.fromTOML (builtins.readFile f);
    langs = (toml ./modules/home/helix/languages.toml).language;
    md = builtins.head (builtins.filter (l: l.name == "markdown") langs);
  in
  {
    markdown = md.rulers or null;
    editor = (toml ./modules/home/helix/config.toml).editor.rulers;
  }'
```

- [ ] **Step 2: Run it and see it fail**

Expected: `{"editor":[73,81],"markdown":[73,101]}`

- [ ] **Step 3: Drop the override and scope the header's rule**

Delete line 272, `rulers = [73, 101]`. Replace header lines 9-11 with:

```toml
# `except-features = ["format"]` routes formatting to oxfmt while
# leaving the original server everything else, and `rulers` is restated
# at [73, 101] for a language oxfmt formats, because oxfmt wraps at 100
# rather than Biome's 80.
```

- [ ] **Step 4: Run the test and see it pass**

Expected: `{"editor":[73,81],"markdown":null}`

- [ ] **Step 5: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 6: Commit**

```bash
git add modules/home/helix/languages.toml
git -c commit.gpgsign=false commit \
  -m "fix(helix): rule Markdown at prettier-md's width" \
  -m "Markdown restated the [73, 101] rulers meant for languages oxfmt
formats, but prettier-md wraps Markdown at 80. Dropping the override
gives it the editor-wide [73, 81], matching Zed's guides."
```

### Task F5: One annotated Astro compiler version

**Files:**

- Modify: `pkgs/prettier-with-plugins.nix:32-48` (`astroBindingVersion`,
  `astroBindings`) and `:76-90` (the three `@astrojs/*` fetches)

**Interfaces:**

- Produces: `astroCompilerVersion = "0.5.3"` in the package's `let`, with the
  only `@VERSION` line for the three Astro packages. `astroBindingVersion` goes.
  The package's outputs and wrappers stay as they are.

- [ ] **Step 1: Write the failing test**

```bash
out=$(nix build --no-link --print-out-paths --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin;
  in
  pkgs.callPackage ./pkgs/prettier-with-plugins.nix { }')
for p in compiler-rs compiler-binding compiler-binding-darwin-arm64; do
  m="$out/lib/node_modules/@astrojs/$p/package.json"
  echo "$p $(jq -r .version "$m")"
done
```

- [ ] **Step 2: Run it and see it fail**

Expected: `compiler-rs 0.5.3`, `compiler-binding 0.5.3`,
`compiler-binding-darwin-arm64 0.5.2`. Every line should read 0.5.3, because
compiler-binding 0.5.3 lists each per-system binding at exactly 0.5.3.

- [ ] **Step 3: Check the three per-system hashes**

```bash
r=https://registry.npmjs.org/@astrojs
for t in darwin-arm64 linux-arm64-gnu linux-x64-gnu; do
  url="$r/compiler-binding-$t/-/compiler-binding-$t-0.5.3.tgz"
  echo "$t $(nix store prefetch-file --json "$url" | jq -r .hash)"
done
```

Expected:

```text
darwin-arm64 sha256-g08P5XGZZhpMgCa2OPGPVjU0QqAHuJcVWAB2ZTU6Htk=
linux-arm64-gnu sha256-0jHu4Hbe/aU/vwjft9LmVAU777+++k2puwJHZ94grUI=
linux-x64-gnu sha256-fXpWhjS6KlJxDap5QdoOofOgRZ5TRPLghi+PpH0/obs=
```

- [ ] **Step 4: Introduce `astroCompilerVersion`**

Replace lines 32-34 with:

```nix
  # compiler-rs pins compiler-binding exactly, and compiler-binding
  # pins each per-system binding, so one version serves all three; a
  # bump also moves their five hashes.
  # @VERSION https://www.npmjs.com/package/@astrojs/compiler-rs
  astroCompilerVersion = "0.5.3";

  # The compiler's native half, one package per system.
```

Set the three `hash` values in `astroBindings` (lines 38, 42 and 46 before this
step) to the Step 3 hashes. In `"@astrojs/compiler-rs"` and
`"@astrojs/compiler-binding"`, delete the `# @VERSION` line and write the
version in the URL as `${astroCompilerVersion}`. Their hashes stay the same. In
`"@astrojs/compiler-binding-${astroBinding.target}"` (line 88), replace
`${astroBindingVersion}` with `${astroCompilerVersion}`.

- [ ] **Step 5: Run the test and see it pass**

Expected: all three lines read `0.5.3`. Then check that formatting still works:
append these two lines to Step 1's block and run it again:

```bash
printf -- '---\nconst a=1\n---\n<div>{a}</div>\n' \
  | "$out/bin/prettier-astro"
```

Expected, after the three version lines:

```text
---
const a = 1;
---

<div>{a}</div>
```

- [ ] **Step 6: Prove the Linux pins without a Linux builder**

Nothing here can build an x86_64-linux or aarch64-linux derivation, but a
fixed-output fetch's store path depends only on its name and hash. This reads
each Linux binding's URL, hash and output path out of the Linux derivation
itself, fetches the URL on this Mac against that hash, and compares the paths:

```bash
for s in aarch64-linux x86_64-linux; do
  drv=$(nix eval --raw --impure --expr "
    let
      f = builtins.getFlake (toString ./.);
      pkgs = f.inputs.nixpkgs.legacyPackages.$s;
    in
    (pkgs.callPackage ./pkgs/prettier-with-plugins.nix { }).drvPath")
  nix derivation show --recursive "$drv" | jq -r '
    .derivations[]
    | select(.name | startswith("compiler-binding-linux"))
    | .structuredAttrs as $a
    | "\($a.urls[0]) \($a.outputHash) \(.env.out)"'
done | while read -r url hash out; do
  got=$(nix store prefetch-file --json --expected-hash "$hash" "$url" \
    2>/dev/null | jq -r .storePath)
  if [ "$got" = "$out" ]; then
    echo "ok ${url##*/}"
  else
    echo "FAIL ${url##*/}"
  fi
done
```

Expected:

```text
ok compiler-binding-linux-arm64-gnu-0.5.3.tgz
ok compiler-binding-linux-x64-gnu-0.5.3.tgz
```

A wrong hash prints `FAIL` for that file. Before Step 4 the same loop prints
`ok` for the two `0.5.2` files, which are consistent but stale.

- [ ] **Step 7: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 8: Commit**

```bash
git add pkgs/prettier-with-plugins.nix
git -c commit.gpgsign=false commit \
  -m "fix(pkgs): pin one Astro compiler version" \
  -m "compiler-binding 0.5.3 was installed beside a 0.5.2 native binding,
because the per-system binding had a version of its own. compiler-rs
pins compiler-binding and it pins the bindings exactly, so a single
annotated version now serves all three URLs."
```

**In CI:** Step 6 proves the Linux fetches, not the Linux install phase. That
first runs when C8.2 makes CI's Markdown check build `prettier-md` on
x86_64-linux; Patrick watches that check on C8.2's pull request.

### Task F6: Filter nomad-ls by its platforms

**Files:**

- Modify: `modules/home/nomad.nix:1-11`

**Interfaces:**

- Produces: `home.packages` gets nomad-ls wherever
  `lib.meta.availableOn pkgs.stdenv.hostPlatform` holds. Today that means
  aarch64-darwin only (`pkgs/nomad-ls.nix` has one asset).

- [ ] **Step 1: Write the characterization test**

```bash
nix eval --override-input work path:./stubs/work --json \
  '.#darwinConfigurations.Patricks-MacBook-Pro.config' --apply '
    c: builtins.filter (n: n == "nomad-ls")
      (map (p: p.pname or "") c.home-manager.users.patrick.home.packages)'
nix eval --override-input work path:./stubs/work --json \
  '.#homeConfigurations."patrick@linux".config' --apply '
    c: builtins.filter (n: n == "nomad-ls")
      (map (p: p.pname or "") c.home.packages)'
```

- [ ] **Step 2: Run it**

Expected: `["nomad-ls"]` then `[]`. There is no red phase. The change keeps
behaviour on both configurations, and only a Linux asset added to
`pkgs/nomad-ls.nix` would show the difference.

- [ ] **Step 3: Use `availableOn`**

Replace lines 3-7 (the comment and the `lib.optionals ... isDarwin` list) with
the pattern in `modules/home/python-lsps-wheels.nix:14`:

```nix
  home.packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) [
    (pkgs.callPackage ../../pkgs/nomad-ls.nix { })
  ];
```

Keep the format-on-save comment at lines 9-10.

- [ ] **Step 4: Run the test again**

Expected: `["nomad-ls"]` then `[]`.

- [ ] **Step 5: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 6: Commit**

```bash
git add modules/home/nomad.nix
git -c commit.gpgsign=false commit \
  -m "refactor(nomad): filter nomad-ls by platform" \
  -m "An isDarwin guard restated what nomad-ls's meta.platforms already
says, and would keep excluding Linux after a Linux asset is added.
lib.meta.availableOn reads the package itself, as python-lsps does."
```

### Task F7: Quote profile directories in the commit-message `case`

**Files:**

- Modify: `modules/home/commit-messages.nix:31` (`directoryCases`)

**Interfaces:**

- Produces: each pattern in the jj editor's directory `case` reads
  `<escapeShellArg dir>/*) profile=<name> ;;`, indented two spaces. The quoted
  part is literal and the trailing `/*` stays a glob. The
  `my.commitMessages.profiles.*` options are unchanged.

- [ ] **Step 1: Write the failing test**

It builds the jj editor for a profile under a directory with a space. `readFile`
realises the script, which `writeShellScript` syntax-checks:

```bash
nix eval --override-input work path:./stubs/work --raw \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
    c:
    let
      ext = c.extendModules {
        modules = [
          {
            home-manager.users.patrick.my.commitMessages.profiles.spaced = {
              context = "x";
              commitlintConfig = "export default {};";
              directories = [ "/tmp/with space" ];
            };
          }
        ];
      };
      hm = ext.config.home-manager.users.patrick;
    in
    builtins.readFile hm.programs.jujutsu.settings.ui.editor' \
  2>&1 | grep -F -e 'syntax error' -e "'/tmp/with space'/*) profile=spaced ;;"
```

- [ ] **Step 2: Run it and see it fail**

Expected, from the failed build:
``... jj-commit-editor: line 23: syntax error near unexpected token `space/*'``

- [ ] **Step 3: Quote the directory**

On line 31, change `"  ${dir}/*) profile=${name} ;;\n"` to
`"  ${lib.escapeShellArg dir}/*) profile=${name} ;;\n"`.

- [ ] **Step 4: Run the test and see it pass**

Expected, and nothing else:

```text
  '/tmp/with space'/*) profile=spaced ;;
```

- [ ] **Step 5: Evaluate against the real work layer**, with the section's
      command. Expected: one `.drv` path. The work layer sets a profile of its
      own with `directories`; `drvPath` evaluates its `case` line but does not
      build the jj editor, so the syntax check on that directory first runs at
      Patrick's build. Step 1 covers the quoting itself.

- [ ] **Step 6: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 7: Commit**

```bash
git add modules/home/commit-messages.nix
git -c commit.gpgsign=false commit \
  -m "fix(commit-messages): quote profile directories" \
  -m "A profile directory holding a space produced an unquoted case
pattern, and the jj editor script failed its syntax check at build.
Each directory is now shell-quoted, leaving the trailing /* a glob."
```

### Task F8: Default release-binary's mainProgram to the first binary

**Files:**

- Modify: `pkgs/lib/release-binary.nix:22-23` (the `binaries` argument and its
  comment) and `:86-89` (`meta`)
- Modify: each caller's `mainProgram` line: `pkgs/agnix-lsp.nix:70`,
  `pkgs/covhl.nix:39`, `pkgs/css-variable-lsp.nix:37`, `pkgs/deps-lsp.nix:42`,
  `pkgs/impeccable-engine.nix:36`, `pkgs/jouet.nix:44`, `pkgs/mbx.nix:49`,
  `pkgs/metal-analyzer.nix:31`, `pkgs/nomad-ls.nix:30`,
  `pkgs/package-swift-lsp.nix:57`, `pkgs/path-server.nix:24`

**Interfaces:**

- Produces: `meta.mainProgram` of every release-binary derivation defaults to
  `lib.head binaries` (`pname` when `binaries` is not given). A caller's
  `meta.mainProgram` still wins, since `meta` merges over the defaults. C23.2's
  `passthru ? { }` and C6.1's `wheel` kind leave this alone.

- [ ] **Step 1: Write the failing test**

```bash
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    mk = args: p.callPackage ./pkgs/lib/release-binary.nix { } ({
      pname = "probe";
      version = "0";
      assets.aarch64-darwin = {
        url = "https://x/probe.tar.gz";
        hash = p.lib.fakeHash;
      };
      meta = { };
    } // args);
  in
  [
    (mk { }).meta.mainProgram
    (mk { binaries = [ "b" "c" ]; }).meta.mainProgram
  ]'
```

- [ ] **Step 2: Run it and see it fail**

Expected: `error: attribute 'mainProgram' missing`

- [ ] **Step 3: Default it in the builder**

At lines 86-89, the `meta` default becomes:

```nix
    meta = {
      platforms = lib.attrNames assets;
      mainProgram = lib.head binaries;
    }
    // meta;
```

Replace the comment on line 22 with:

```nix
  # installed to $out/bin; the first is the default meta.mainProgram,
  # and a bare .gz or bare file lands under it
```

- [ ] **Step 4: Run the test and see it pass**

Expected: `["probe","b"]`

- [ ] **Step 5: Record what the 11 callers resolve to**

```bash
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    names = [
      "agnix-lsp" "covhl" "css-variable-lsp" "deps-lsp"
      "impeccable-engine" "jouet" "mbx" "metal-analyzer" "nomad-ls"
      "package-swift-lsp" "path-server"
    ];
    main = n: (p.callPackage (./pkgs + "/${n}.nix") { }).meta.mainProgram;
  in
  p.lib.genAttrs names main' | jq .
```

Expected now, and the same after Step 6:

```json
{
  "agnix-lsp": "agnix-lsp",
  "covhl": "covhl",
  "css-variable-lsp": "css-variable-lsp",
  "deps-lsp": "deps-lsp",
  "impeccable-engine": "impeccable",
  "jouet": "jouet",
  "mbx": "mbx",
  "metal-analyzer": "metal-analyzer",
  "nomad-ls": "nomad-ls",
  "package-swift-lsp": "package-swift-lsp",
  "path-server": "path-server"
}
```

- [ ] **Step 6: Delete the 11 restatements**

Delete the `mainProgram = "...";` line at each caller location listed under
Files. Each one equals that caller's first binary.

- [ ] **Step 7: Run Step 5 again**, and expect identical output

- [ ] **Step 8: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 9: Commit**

```bash
git add pkgs/lib/release-binary.nix pkgs/agnix-lsp.nix pkgs/covhl.nix \
  pkgs/css-variable-lsp.nix pkgs/deps-lsp.nix pkgs/impeccable-engine.nix \
  pkgs/jouet.nix pkgs/mbx.nix pkgs/metal-analyzer.nix pkgs/nomad-ls.nix \
  pkgs/package-swift-lsp.nix pkgs/path-server.nix
git -c commit.gpgsign=false commit \
  -m "refactor(pkgs): default mainProgram to binary" \
  -m "Every release-binary caller restated its first binary as
meta.mainProgram. The builder now defaults it to the first entry of
binaries, and a caller's own meta still overrides it."
```

### Task F9: A flake check for release-binary's archive kinds

**Files:**

- Create: `pkgs/lib/release-binary/test-archive.nix`
- Modify: `flake.nix:61-65` (add `releaseBinaryArchive` after `mergeJsonTests`),
  `:191` and `:195` (the checks)
- Modify: `.github/workflows/ci.yml:92-106` (a job after `merge-json`, before
  `darwin`)
- Modify: `mise.toml:28-30` (a task after `check:merge-json`)
- Modify: `docs/architecture.md:10-12` (the `checks` sentence)
- Modify: `GLOSSARY.md:169-171` (**Flake check**)
- Modify: `CLAUDE.md:7-9` (what "the tests" are) and `:42-44` (the
  `nix-check.sh merge-json` lines in Commands)

**Interfaces:**

- Produces: `checks.aarch64-darwin.release-binary-archive` and
  `checks.x86_64-linux.release-binary-archive`, built by
  `.github/scripts/nix-check.sh release-binary-archive`, by the mise task
  `check:release-binary-archive` beside `check:merge-json`, and in CI by a job
  `release-binary-archive` ("Test release-binary archive kinds") after the
  `merge-json` job and shaped like it. Its last line is
  `run: .github/scripts/nix-check.sh release-binary-archive`. C23.1 adds its
  `lib` job after this one, shaped the same way.
- Produces: `pkgs/lib/release-binary/test-archive.nix`, which `callPackage`
  calls with `{ lib, stdenvNoCC, callPackage, writeText }`. Its `cases` attrset
  maps a URL suffix (string) to the expected `passthru.archive` kind (string).
  `cases` lives in this file, not in `flake.nix`, and as an attrset it has no
  order. C6.1 adds `".whl" = "wheel";` to it, and before its builder change sees
  `release-binary: .whl gave file, expected wheel`. C23.2's `passthru ? { }`
  must keep `archive` in `passthru`, or this check fails. A failure reads
  `release-binary: <suffix> gave <got>, expected <want>`, joined by
  `lib.concatStringsSep "; "`.
- Produces: `docs/architecture.md` says "plus merge-json's fixture tests and
  release-binary's archive-kind check, which `checks.x86_64-linux` carries for
  CI". C23.1 anchors its own edit on exactly this wording.
- Produces: GLOSSARY.md's **Flake check** lists "the system build, the Linux
  eval, merge-json's fixture tests and release-binary's archive-kind check."
  C23.1 adds `lib/tests.nix`'s cases to the end of that list.
- Produces: CLAUDE.md says "the tests" are "that both configurations evaluate,
  merge-json's fixtures and release-binary's archive-kind check pass, and the
  per-language checks pass", and its Commands block runs
  `.github/scripts/nix-check.sh merge-json` and then
  `.github/scripts/nix-check.sh release-binary-archive` under one comment.
  C23.1's `lib` check joins both places.

- [ ] **Step 1: Write the check**

Create `pkgs/lib/release-binary/test-archive.nix`. It passes nixfmt and
nixf-tidy as written:

```nix
# Asserts the archive kind release-binary.nix derives from each asset
# URL suffix, read through the `archive` attribute it exposes.
{
  lib,
  stdenvNoCC,
  callPackage,
  writeText,
}:
let
  cases = {
    ".tar.gz" = "tar";
    ".tar.xz" = "tar";
    ".tgz" = "tar";
    ".tar" = "tar";
    ".tbz" = "tar";
    ".zip" = "zip";
    ".gz" = "gzip";
    "-darwin-arm64" = "file";
  };

  kindOf =
    suffix:
    (callPackage ../release-binary.nix { } {
      pname = "probe";
      version = "0";
      assets.${stdenvNoCC.hostPlatform.system} = {
        url = "https://example.invalid/probe${suffix}";
        hash = lib.fakeHash;
      };
      meta = { };
    }).archive;

  wrong = lib.filterAttrs (suffix: kind: kindOf suffix != kind) cases;
  describe = suffix: kind: "${suffix} gave ${kindOf suffix}, expected ${kind}";
  report = lib.concatStringsSep "; " (lib.mapAttrsToList describe wrong);
in
assert lib.assertMsg (wrong == { }) "release-binary: ${report}";
writeText "release-binary-archive" (builtins.toJSON cases)
```

The asset is keyed by the host system, so the x86_64-linux check is not a
derivation for an unsupported platform. Then
`git add pkgs/lib/release-binary/test-archive.nix`.

- [ ] **Step 2: Run it and see it fail**

Run: `.github/scripts/nix-check.sh release-binary-archive`

Expected: an error that the flake does not provide the attribute, ending in
`'checks.aarch64-darwin.release-binary-archive'`.

- [ ] **Step 3: Wire it into the flake**

After `mergeJsonTests` in `flake.nix`'s `let`, add the binding below, and run
nixfmt, which decides its final line breaks:

```nix
      releaseBinaryArchive =
        system:
        inputs.nixpkgs.legacyPackages.${system}.callPackage
          ./pkgs/lib/release-binary/test-archive.nix
          { };
```

Then add `release-binary-archive = releaseBinaryArchive "aarch64-darwin";` after
`merge-json` in `checks.aarch64-darwin`, and this after line 195:

```nix
      checks.x86_64-linux.release-binary-archive =
        releaseBinaryArchive "x86_64-linux";
```

The comment above line 195 covers both.

- [ ] **Step 4: Run it and see it pass**

```bash
.github/scripts/nix-check.sh release-binary-archive
nix eval --override-input work path:./stubs/work --raw \
  '.#checks.x86_64-linux.release-binary-archive.drvPath'
```

Expected: the build exits 0. The eval prints a
`/nix/store/<hash>-release-binary-archive.drv` path.

- [ ] **Step 5: Show that the check bites, on both systems**

Change `".gz" = "gzip";` to `".gz" = "tar";`, and run Step 4's two commands.
Expected: both fail, and each error ends with
`error: release-binary: .gz gave gzip, expected tar`. The check asserts during
evaluation, so the x86_64-linux eval fails exactly as CI's Linux job would, with
no Linux builder here. Revert the change and run both again: the check exits 0
and the eval prints a `.drv` path.

- [ ] **Step 6: Run it in CI and name it in the docs**

In `.github/workflows/ci.yml`, copy the `merge-json` job, from its id line
`merge-json:` (line 92) to its last line,
`run: .github/scripts/nix-check.sh merge-json` (line 106). Insert the copy after
line 106, behind one blank line, so it sits before `darwin:`. In the copy,
change four lines:

- the job id `merge-json:` to `release-binary-archive:`
- both `Test merge-json`, the job's `name:` and its last step's `name:`, to
  `Test release-binary archive kinds`
- `nix-check.sh merge-json` to `nix-check.sh release-binary-archive`

Then compare the two jobs:

```bash
job() {
  awk -v j="  $1:" '
    $0 == j { p = 1; print; next }
    /^  [^ ]/ { p = 0 }
    p
  ' .github/workflows/ci.yml
}
diff <(job merge-json) <(job release-binary-archive)
```

Expected, and nothing else:

```text
1,2c1,2
<   merge-json:
<     name: Test merge-json
---
>   release-binary-archive:
>     name: Test release-binary archive kinds
14,15c14,15
<       - name: Test merge-json
<         run: .github/scripts/nix-check.sh merge-json
---
>       - name: Test release-binary archive kinds
>         run: .github/scripts/nix-check.sh release-binary-archive
```

In `docs/architecture.md:10-12`, change "plus merge-json's fixture tests, which
`checks.x86_64-linux` carries for CI" to "plus merge-json's fixture tests and
release-binary's archive-kind check, which `checks.x86_64-linux` carries for
CI".

In `GLOSSARY.md:169-171` (**Flake check**), change "the system build, the Linux
eval and merge-json's fixture tests." to "the system build, the Linux eval,
merge-json's fixture tests and release-binary's archive-kind check." It stays
two lines, so F13's line numbers hold.

In `CLAUDE.md:7-9`, change "merge-json's fixtures pass and the per-language
checks pass" to "merge-json's fixtures and release-binary's archive-kind check
pass, and the per-language checks pass". In its Commands block, replace lines
42-44 (the comment on merge-json's fixture tests and
`.github/scripts/nix-check.sh merge-json`) with:

```sh
# merge-json's fixture tests and release-binary's archive-kind check
# alone, for this machine's system; CI builds the x86_64-linux ones.
.github/scripts/nix-check.sh merge-json
.github/scripts/nix-check.sh release-binary-archive
```

Reflow the three files with the Markdown formatter. Then
`awk 'length > 80' CLAUDE.md docs/architecture.md GLOSSARY.md` prints nothing:
CI's markdownlint allows no longer line, code blocks included.

- [ ] **Step 7: Give it a mise task**

In `mise.toml`, after the `check:merge-json` task (lines 28-30), add a blank
line and:

```toml
[tasks."check:release-binary-archive"]
description = "Run release-binary's archive-kind check"
run = ".github/scripts/nix-check.sh release-binary-archive"
```

Run `mise run check:release-binary-archive`, sandbox off. Expected: exit 0.
`mise tasks ls` lists the task with that description.

- [ ] **Step 8: `mise run test` and `mise run lint`**, both exit 0. Do not run
      `mise run check:flake`: it builds the whole macOS system, which is
      Patrick's to build. Steps 4, 5 and 7 already build the new check alone.

- [ ] **Step 9: Commit**

```bash
git add pkgs/lib/release-binary/test-archive.nix flake.nix \
  .github/workflows/ci.yml mise.toml docs/architecture.md GLOSSARY.md \
  CLAUDE.md
git -c commit.gpgsign=false commit \
  -m "test(pkgs): check release-binary archive kinds" \
  -m "passthru.archive decides how release-binary unpacks an asset and had
no test. A flake check on both systems now maps each URL suffix to
the kind it must give. CI builds the Linux one in a job of its own,
as it does merge-json's, mise runs it as check:release-binary-archive,
and CLAUDE.md lists it with the tests."
```

### Task F10: Wrap the LSP plugin's nixd settings by section

**Files:**

- Modify: `modules/home/claude-code/nix-lsp.json:212-224` (`nixd.settings`)

**Interfaces:**

- Produces: `.nixd.settings` equals `.nixd.initializationOptions`, both of this
  shape, with the same three `expr` strings:

  ```json
  {
    "nixd": {
      "nixpkgs": { "expr": "..." },
      "options": {
        "nix-darwin": { "expr": "..." },
        "home-manager": { "expr": "..." }
      }
    }
  }
  ```

  C23.4 later derives both from `helix/languages.toml`'s
  `[language-server.nixd.config]`, which already has this shape.

- [ ] **Step 1: Write the failing test**

```bash
jq -e '.nixd.settings == .nixd.initializationOptions' \
  modules/home/claude-code/nix-lsp.json
```

- [ ] **Step 2: Run it and see it fail**

Expected: `false`, exit 1. `jq -c '.nixd.settings | keys'` shows
`["nixpkgs","options"]`.

- [ ] **Step 3: Wrap `settings`**

Replace lines 212-224 with a copy of lines 197-211, renaming the copied
`"initializationOptions"` key to `"settings"`. The result is a `"settings"`
object whose only key is `"nixd"`, holding `nixpkgs` and `options` with the same
three `expr` strings. Then run the JSON formatter on the file.

- [ ] **Step 4: Run the test and see it pass**

Expected: `true`, exit 0. `jq -c '.nixd.settings | keys'` shows `["nixd"]`.

- [ ] **Step 5: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 6: Commit**

```bash
git add modules/home/claude-code/nix-lsp.json
git -c commit.gpgsign=false commit \
  -m "fix(claude-code): wrap nixd settings by section" \
  -m "Claude Code answers workspace/configuration by looking the requested
section up in settings, and nixd asks for \"nixd\", so the unwrapped
keys were never found. settings now takes the same { nixd = ...; }
shape as initializationOptions."
```

**After the switch:** Patrick hovers the `programs.git` attribute in
`modules/home/git.nix` through Claude Code's LSP tool and expects nixd to show
home-manager's option description.

### Task F11: Correct five stale comments

Comments only, so there is no red phase. Each step ends with a `git grep` for
the stale phrase, which must print nothing, and the comment-length check from
the section notes.

**Files:**

- Modify: `pkgs/dockerhub-mcp-server.nix:9-12`
- Modify: `modules/home/java.nix:17`
- Modify: `modules/home/ruby.nix:17-22`
- Modify: `modules/home/helix/languages.toml:696-701`
- Modify: `modules/darwin/launchd-env.nix:14-17`

**Interfaces:**

- Produces: comment text only. C1.1 later replaces the `launchd-env.nix` comment
  again, when the names move.

- [ ] **Step 1: dockerhub-mcp-server.nix**

Delete lines 9-12: the bare `#` line and the paragraph "A package rather than a
`let` binding, because modules/home/mcp.nix and modules/home/darwin/zed.nix must
run the same wrapper or only one of the two authenticates." The server is
declared once now, in `modules/home/darwin/mcp.nix`. The header ends at "...
follows it rather than the manifest." Check:
`git grep -n "darwin/zed.nix" pkgs/dockerhub-mcp-server.nix` prints nothing.

- [ ] **Step 2: java.nix**

Line 17 becomes:

```nix
  # nixpkgs patches jdtls.py to run the server on a JDK of its own, so
```

The pinned nixpkgs hard-codes `jdk25` there. The new wording names no version,
so it does not go stale at the next bump. Check:
`git grep -n "JDK 21" modules/home/java.nix` prints nothing.

- [ ] **Step 3: ruby.nix**

`launchd-env.nix` exports `XDG_CONFIG_HOME` at every login, so a Dock-launched
editor is no longer missing it until the next switch. Replace lines 17-22 with:

```nix
  # rubocop reads $XDG_CONFIG_HOME/rubocop/config.yml and, without the
  # variable, silently uses its 120-column default, so the wrapper
  # supplies it; `--set-default` lets an environment that sets it win.
  # GEM_HOME names Ruby's own read-only gem tree, which keeps the user
  # gem directory off rubocop's load path.
```

Check: `git grep -n "next switch" modules/home/ruby.nix` prints nothing.

- [ ] **Step 4: helix/languages.toml**

Delete lines 696-701: the bare `#` line and the
`vscode-json-language-server deliberately gets no config at all ...` paragraph.
Keep lines 694-695 about yaml-language-server. Helix 25.07.1's bundled
`languages.toml` gives vscode-json-language-server a `config` of its own
(`provideFormatter = true` and `json.validate.enable = true`), so Helix sends it
configuration whatever this file says. Nothing here configures it, so the
paragraph has nothing left to explain. Check:
`git grep -n "deliberately gets no config" modules/home/helix/languages.toml`
prints nothing.

- [ ] **Step 5: launchd-env.nix**

`CHECKPOINT_DISABLE` is an opt-out and `IMPECCABLE_BIN` and `XDG_BIN_HOME` are
locators, so not every variable is a redirect. Replace lines 14-17 with:

```nix
  # What a CLI an app spawns needs to behave as in a shell: state
  # redirects out of $HOME, tool locators and telemetry opt-outs. A
  # GUI-spawned CLI that misses a redirect recreates the dotfile it
  # exists to prevent. Sorted, ASCII order; a module setting one of
  # its own adds it through my.launchd.extraVariables instead.
```

Check:
`git grep -n "Every variable here redirects" modules/darwin/launchd-env.nix`
prints nothing.

- [ ] **Step 6: Comment lengths**

```bash
awk 'length > 72 && /^ *#/ {print FILENAME":"FNR}' \
  pkgs/dockerhub-mcp-server.nix modules/home/java.nix \
  modules/home/ruby.nix modules/home/helix/languages.toml \
  modules/darwin/launchd-env.nix
```

Expected: nothing.

- [ ] **Step 7: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 8: Commit**

```bash
git add pkgs/dockerhub-mcp-server.nix modules/home/java.nix \
  modules/home/ruby.nix modules/home/helix/languages.toml \
  modules/darwin/launchd-env.nix
git -c commit.gpgsign=false commit \
  -m "docs: correct five stale comments" \
  -m "Five comments described code that has since changed: the Docker Hub
server's two consumers, jdtls's JDK, rubocop's missing
XDG_CONFIG_HOME in GUI apps, Helix sending no JSON server config, and
every exported launchd variable being a state redirect."
```

### Task F12: Point the commitlint skill's @VERSION at its commits

**Files:**

- Modify: `modules/home/claude-skills.nix:255` (the `# @VERSION` line inside
  `commitlintSkill`). F2 shifts this line, so find it by its text, which ends in
  `conventional-changelog/commitlint/releases`.

**Interfaces:**

- Produces: the line reads `# @VERSION $new`, indented four spaces, where `$new`
  is the commits page of commitlint's `skills/committing-with-commitlint` on
  `master`, as Step 1 builds it. The pin itself (`d8e36560...` in the URL, and
  the hash) is unchanged. C5.4 moves commitlint into `skillSingles` and keeps
  this annotation with the pin.

- [ ] **Step 1: Check that the new URL lists the skill's commits**

```bash
url=https://github.com/conventional-changelog/commitlint
new=$url/commits/master/skills/committing-with-commitlint
curl -sSfL -o /dev/null -w '%{http_code}\n' "$new"
```

Expected: `200`. `master` is commitlint's default branch.

- [ ] **Step 2: Replace the line**

In that line, replace the final `releases` with
`commits/master/skills/committing-with-commitlint`. A URL is a token that cannot
be broken, so the 72-column limit does not apply to it. Check:

```bash
url=https://github.com/conventional-changelog/commitlint
new=$url/commits/master/skills/committing-with-commitlint
f=modules/home/claude-skills.nix
grep -c -F "# @VERSION $url/releases" "$f"
grep -c -x -F "    # @VERSION $new" "$f"
```

Expected: `0`, then `1`.

- [ ] **Step 3: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 4: Commit**

```bash
git add modules/home/claude-skills.nix
git -c commit.gpgsign=false commit \
  -m "docs(claude-skills): track commitlint by commit" \
  -m "The commitlint skill is pinned by a commit in its raw URL, but its
@VERSION named the releases page, which lists tags and says nothing
about the skill. It now names the commits that touch the skill."
```

### Task F13: Count four keychain readers and correct the CI-tools claim

**Files:**

- Modify: `GLOSSARY.md:201-205` (**Secret**). F9 edits **Flake check** above it
  without changing the line count; anchor on the text all the same.
- Modify: `SECURITY.md:39-43`
- Modify: `CONTRIBUTING.md:85-87`

**Interfaces:**

- Consumes: the four login-keychain readers:
  `pkgs/github-mcp-server-keychain/wrapper.sh`,
  `pkgs/dockerhub-mcp-server/wrapper.sh`,
  `pkgs/cronometer-mcp-server/wrapper.sh` and
  `modules/home/darwin/orca/forge-cli.sh:75`. The last one is the `gh` and
  `glab` wrapper that Orca runs.
- Produces: text only. C1.1 and C7.1 later add glossary entries of their own.

- [ ] **Step 1: GLOSSARY.md, Secret**

Replace "or, for three MCP wrappers on the Mac, from the login keychain." with
"or, for four wrappers on the Mac (one each for the GitHub, Docker Hub and
Cronometer MCP servers, and one Orca runs `gh` and `glab` through), from the
login keychain."

- [ ] **Step 2: SECURITY.md**

Replace "the GitHub, Docker Hub and Cronometer MCP wrappers read their secrets
from the login keychain" with "four wrappers read their secrets from the login
keychain (one each for the GitHub, Docker Hub and Cronometer MCP servers, and
one Orca runs `gh` and `glab` through)". The rest of the paragraph stays.

- [ ] **Step 3: CONTRIBUTING.md**

Replace lines 85-87 with:

```markdown
Most checks run the same tool the editor runs, with the same configuration, so a
file that is clean in Zed passes them in CI; where they differ, that is a bug in
the configuration rather than something to work around. Two checks run a tool of
their own: CI lints Markdown with markdownlint-cli2 where the editor runs
markdownlint-lsp, and validates each declared schema with check-jsonschema where
the editor relies on its JSON and YAML language servers.
```

- [ ] **Step 4: Reflow and check**

```bash
"$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
  --prose-wrap=always --print-width=80 GLOSSARY.md SECURITY.md CONTRIBUTING.md
mise run lint:markdown
git grep -n -e "three MCP" -e "deliberately the same ones" \
  -- GLOSSARY.md SECURITY.md CONTRIBUTING.md
```

Expected: `mise run lint:markdown` exits 0, and the `git grep` prints nothing.

- [ ] **Step 5: `mise run test` and `mise run lint`**, both exit 0

- [ ] **Step 6: Commit**

```bash
git add GLOSSARY.md SECURITY.md CONTRIBUTING.md
git -c commit.gpgsign=false commit \
  -m "docs: correct keychain count and CI tool claim" \
  -m "Orca's gh and glab wrapper reads the login keychain too, so four
wrappers do, not three. CONTRIBUTING said CI runs the editor's own
tools, which is false for markdownlint and check-jsonschema."
```

### Task F14: Test the LSP plugin's languageIds

The plugin sends `extensionToLanguage` values as LSP languageIds. For four of
them, Helix sends a different id: `tsx` (Helix `typescriptreact`), `jsx`
(`javascriptreact`), `hcl` (`terraform`) and `tfvars` (`terraform-vars`). This
task runs each server once under each id of a pair and reports what it finds. It
changes no file in the repository and commits nothing.

Identical output under both ids, apart from `languageId`, means the server
treats the plugin's id as Helix's. Measured on 2026-11-13 with tsgo
`Version 7.0.2` and terraform-ls `0.39.1`: tsgo answers both ids of each pair
alike, and terraform-ls answers `hcl` and `tfvars` with no symbols and
`no feature found for language <id>`.

**Files:**

- None in the repository. The probe and its fixtures live under
  `$TMPDIR/lsp-probe`.

**Interfaces:**

- Consumes: `tsgo.extensionToLanguage` and `terraform-ls.extensionToLanguage` in
  `modules/home/claude-code/nix-lsp.json`, read only.
- Produces: a report to Patrick, nothing in the tree. `nix-lsp.json` keeps
  `".tsx": "tsx"`, `".jsx": "jsx"` and terraform-ls's `hcl` and `tfvars`, and
  C23.4 carries `extensionToLanguage` over verbatim.

- [ ] **Step 1: Print the server versions and the tree's state**

```bash
tsgo --version
terraform-ls --version
git status --short
```

Expected: `Version 7.0.2` and `0.39.1`. With other versions, re-measure rather
than trust the expected outputs below. Note what `git status` lists; Step 6
compares against it.

- [ ] **Step 2: Write the probe and fixtures outside the repository**

The probe is a throwaway test harness and is never committed. It speaks LSP over
stdio, opens one file under the given id and prints diagnostics and document
symbols. Steps 2 to 4 share one `$TMPDIR`, so run all three sandboxed, as none
of them calls `nix` or `mise`. Save it as `$TMPDIR/lsp-probe/lsp_probe.py`:

```python
"""Open FILE in a language server under LANGUAGE_ID; print diagnostics
and document symbols. Usage: lsp_probe.py LANGUAGE_ID FILE CMD..."""

from __future__ import annotations

import json
import subprocess
import sys
import threading
import time
from pathlib import Path

lang_id, path, *cmd = sys.argv[1:]
file = Path(path).resolve()
proc = subprocess.Popen(
    cmd,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
)
inbox: list[dict] = []


def read() -> None:
    while True:
        length = 0
        while line := proc.stdout.readline().strip():
            if line.lower().startswith(b"content-length:"):
                length = int(line.split(b":")[1])
        if not length:
            return
        inbox.append(json.loads(proc.stdout.read(length)))


def send(msg: dict) -> None:
    data = json.dumps({"jsonrpc": "2.0", **msg}).encode()
    proc.stdin.write(b"Content-Length: %d\r\n\r\n%s" % (len(data), data))
    proc.stdin.flush()


def call(rid: int, method: str, params: dict, wait: float = 20) -> dict:
    send({"id": rid, "method": method, "params": params})
    end = time.time() + wait
    while time.time() < end:
        for m in list(inbox):
            if "method" in m and "id" in m:  # a server request: answer null
                inbox.remove(m)
                n = 0
                if m["method"] == "workspace/configuration":
                    n = len(m["params"].get("items", []))
                send({"id": m["id"], "result": [None] * n if n else None})
            elif m.get("id") == rid:
                return m
        time.sleep(0.1)
    return {}


threading.Thread(target=read, daemon=True).start()
root = file.parent.as_uri()
call(
    1,
    "initialize",
    {
        "processId": None,
        "rootUri": root,
        "workspaceFolders": [{"uri": root, "name": "probe"}],
        "capabilities": {"workspace": {"configuration": True}},
    },
)
send({"method": "initialized", "params": {}})
doc = {"uri": file.as_uri()}
send(
    {
        "method": "textDocument/didOpen",
        "params": {
            "textDocument": {
                **doc,
                "languageId": lang_id,
                "version": 1,
                "text": file.read_text(),
            }
        },
    }
)
time.sleep(4)
symbols = call(2, "textDocument/documentSymbol", {"textDocument": doc})
pulled = call(3, "textDocument/diagnostic", {"textDocument": doc}, wait=8)
time.sleep(2)
first = lambda ds: [d["message"].splitlines()[0] for d in ds]  # noqa: E731
published = [
    d
    for m in inbox
    if m.get("method") == "textDocument/publishDiagnostics"
    and m["params"]["uri"] == doc["uri"]
    for d in m["params"]["diagnostics"]
]
pulled_items = (pulled.get("result") or {}).get("items") or []
print(
    json.dumps(
        {
            "languageId": lang_id,
            "diagnostics": sorted(first(published + pulled_items)),
            "symbols": [s["name"] for s in symbols.get("result") or []],
            "symbolError": (symbols.get("error") or {}).get("message"),
        }
    )
)
proc.kill()
```

Write the fixtures in a separate directory, `$TMPDIR/lsp-probe/ws`. `main.tf`
ends inside an open block on purpose, and `y =` in `probe.tfvars` has no value,
so both carry syntax errors:

```bash
w="$TMPDIR/lsp-probe/ws"; mkdir -p "$w/ts" "$w/tf"
cat >"$w/ts/probe.tsx" <<'EOF'
const n: number = "x";
export const el = <div>{n}</div>;
export function f() { return n; }
EOF
cat >"$w/ts/probe.jsx" <<'EOF'
const n = 1;
export const el = <div>{n}</div>;
export function f() { return n.foo(; }
EOF
cat >"$w/ts/tsconfig.json" <<'EOF'
{ "compilerOptions": { "jsx": "preserve", "strict": true } }
EOF
cat >"$w/tf/main.tf" <<'EOF'
variable "x" {
  type = string
}

output "y" {
  value = var.x
}

resource "foo" {
EOF
printf 'x = "a"\ny = \n' >"$w/tf/probe.tfvars"
```

- [ ] **Step 3: Probe tsgo**

```bash
cd "$TMPDIR/lsp-probe" || exit 1
py() { /usr/bin/python3 -I lsp_probe.py "$@"; }
{
  py typescriptreact ws/ts/probe.tsx tsgo --lsp --stdio
  py tsx ws/ts/probe.tsx tsgo --lsp --stdio
  py javascriptreact ws/ts/probe.jsx tsgo --lsp --stdio
  py jsx ws/ts/probe.jsx tsgo --lsp --stdio
} | tee tsgo.jsonl
jq -s -c '[.[] | del(.languageId)] | [.[0] == .[1], .[2] == .[3]]' tsgo.jsonl
```

Expected: four JSON lines, then `[true,true]`: within each pair the output is
identical apart from `languageId`. For the `.tsx` pair, `diagnostics` holds two
copies of the message that starts `JSX element implicitly has type 'any'`,
followed by `Type 'string' is not assignable to type 'number'.`. For the `.jsx`
pair it is `["')' expected."]`. All four return `symbols` `["n","el","f"]` and
`symbolError` `null`. tsgo looks for type packages on registry.npmjs.org, so in
a sandbox the denials for that host are noise.

- [ ] **Step 4: Probe terraform-ls**

```bash
cd "$TMPDIR/lsp-probe" || exit 1
py() { /usr/bin/python3 -I lsp_probe.py "$@"; }
{
  py terraform ws/tf/main.tf terraform-ls serve
  py hcl ws/tf/main.tf terraform-ls serve
  py terraform-vars ws/tf/probe.tfvars terraform-ls serve
  py tfvars ws/tf/probe.tfvars terraform-ls serve
} | tee terraform-ls.jsonl
jq -s -c '[.[] | del(.languageId)] | [.[0] == .[1], .[2] == .[3]]' \
  terraform-ls.jsonl
jq -c '[.languageId, .symbols, .symbolError]' terraform-ls.jsonl
jq -s -c '[.[0].diagnostics == .[1].diagnostics]' terraform-ls.jsonl
```

Expected, after the four JSON lines:

```text
[false,false]
["terraform",["variable \"x\"","output \"y\"","resource \"foo\""],null]
["hcl",[],"no feature found for language hcl"]
["terraform-vars",["x","y"],null]
["tfvars",[],"no feature found for language tfvars"]
[true]
```

`terraform` and `terraform-vars` return the symbols, `hcl` and `tfvars` return
none and the error, and `main.tf` gets the same two syntax diagnostics under
either id.

- [ ] **Step 5: Read the ids the plugin sends**

```bash
f=modules/home/claude-code/nix-lsp.json
jq -c '."terraform-ls".extensionToLanguage' "$f"
jq -c '.tsgo.extensionToLanguage | {".tsx", ".jsx"}' "$f"
```

Expected:

```text
{".hcl":"hcl",".nomad":"hcl",".tf":"hcl",".tfvars":"tfvars"}
{".tsx":"tsx",".jsx":"jsx"}
```

- [ ] **Step 6: Report, and leave the tree as it was**

Run `git status --short` and expect exactly what Step 1 listed. Do not run
`mise`, `git add` or `git commit`.

Report to Patrick, in the task's result and nowhere in the tree: both server
versions; for each of the four pairs, whether Step 3 or Step 4 printed `true`;
for a pair that printed `false`, the `symbols` and `symbolError` under each id
from Step 4's table; and Step 5's ids beside the ids Helix sends. With the
measured results that is: tsgo alike under both ids of both pairs, and
terraform-ls answering only `terraform` and `terraform-vars` for every extension
the plugin maps to `hcl` or `tfvars`. Whether the plugin's ids change is
Patrick's decision.

#### Notes for section F

- The Spec's release-binary bullet becomes two tasks and two commits: F8 (the
  `mainProgram` default) and F9 (the archive-kind check), so either can be
  reviewed or reverted alone. The stale-comments bullet stays one task and one
  commit across five files (F11), and so does the GLOSSARY, SECURITY and
  CONTRIBUTING bullet (F13).
- F4 deletes Markdown's `rulers` override, so Markdown inherits `config.toml`'s
  `[editor] rulers = [73, 81]`, where a literal reading of the Spec would
  restate `[73, 81]`. Restating it is a one-line swap, after which F4's test
  expects `"markdown":[73,81]`.
- F9's check evaluates only the archive kind each suffix gives; no unpack phase
  runs. Its header comment says "the `archive` attribute it exposes" rather than
  "passthru.archive" because `codebook.toml` lacks "passthru"; keep that
  wording.
- F9 leaves `CLAUDE.local.md` alone: it is untracked, and its task list names no
  flake check but `check:flake`.
- F11 changes only `ruby.nix`'s comment. Its `--set-default XDG_CONFIG_HOME`
  wrapper is arguably redundant now that launchd exports the variable at login,
  but removing it is outside the Spec.
- F13 counts Orca's `forge-cli.sh` as one wrapper, although it serves two
  commands, `gh` and `glab`.
- F14 probes `jsx` and `tfvars` beside the Spec's `tsx` and `hcl`. The plugin's
  other ids that Helix does not send (`jsonc`, `json-ld`, `gotmpl` and the rest)
  go untested.

---

## Section C1: GUI variables

Card 1 of the Spec. Four tasks, in this order, each leaving `mise run test`
green: C1.1 moves the names already exported beside their setters without
changing what is exported, and adds the glossary term; C1.2 exports the rest of
the GUI variables and amends ADR-0013; C1.3 and C1.4 add the two evaluation-time
checks. The home-directory check (C1.4) cannot land before C1.2, because
`SSH_AUTH_SOCK`, `HELM_REGISTRY_CONFIG` and `REGISTRY_AUTH_FILE` hold home paths
and would fail it unexported.

C1.4 also waits for Patrick: the work layer at its locked revision sets four
home-valued session variables without exporting them, so he first merges the
work layer's export of them and bumps the `work` lock. C1.4 Step 1 checks that
against the real work layer and stops the task if it has not happened. C1.1,
C1.2 and C1.3 do not wait.

**Starting state.** Section F has run: `modules/darwin/launchd-env.nix`'s
`redirectNames` also holds `CARGO_HOME`, `RUSTUP_HOME` and `XDG_BIN_HOME`, and F
has reworded the comment above it. Line numbers below are at `a07c2f4`; F shifts
some (launchd-env.nix, ruby.nix, claude-skills.nix, claude-code.nix), so anchor
every edit on the quoted text, not on the number.

**Nix snippets** are shown within 80 columns. Run
`"$(.github/scripts/nix-tool.sh nixfmt)"` on every Nix file a task changes
before `mise run lint`, and let its layout stand: it may join a line broken here
to fit.

**Shell variables.** Every command block sets the variables it uses, because
shell state does not carry from one command to the next.

**The probe pattern.** C1.3 and C1.4 test their assertions by extending the real
configuration with a module that breaks the rule and listing the failed
assertions' messages. `extendModules` is an attribute of the
`darwinConfigurations` value, and `--apply` takes a function of it:

```bash
sys='.#darwinConfigurations.Patricks-MacBook-Pro'
nix eval --json --override-input work path:./stubs/work "$sys" --apply '
c:
let
  probe = c.extendModules { modules = [ { /* the violating settings */ } ]; };
  failed = builtins.filter (a: !a.assertion) probe.config.assertions;
in
map (a: a.message) failed
'
```

**The real work layer.** Every stub eval hides the private work layer, which
sets session variables of its own. Every task here touches an option the work
layer sees, so each also evaluates the real configuration, with no
`--override-input`, printing only names, assertion messages, a store path or the
error, never a value from the work layer. The first command lists the failed
assertions' messages; the second evaluates the whole system and prints its
`.drv` path:

```bash
cfg='.#darwinConfigurations.Patricks-MacBook-Pro.config'
nix eval --json "$cfg.assertions" \
  --apply 'as: map (a: a.message) (builtins.filter (a: !a.assertion) as)'
nix eval --raw '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'
```

Every `nix` command here runs with the Bash sandbox off.

### Task C1.1: Declare GUI variables beside their setters

A refactor: the exported set stays exactly what F leaves, but each name moves
from launchd-env.nix's central list to `my.launchd.extraVariables` beside the
`home.sessionVariables` entry that sets it. launchd-env.nix keeps only the five
`XDG_*_HOME` names home-manager's own `xdg` module sets.

**Files:**

- Modify: `modules/darwin/launchd-env.nix` (at a07c2f4: lines 14-47, the comment
  above `redirectNames` through the `redirects =` binding; line 60,
  `// redirects;`)
- Modify: `modules/home/options.nix:17-18` (the `launchd.extraVariables`
  comment)
- Modify: `modules/home/claude-code.nix:155-157`
- Modify (one line or list added after the setter):
  `modules/home/darwin/android-studio.nix:27`, `modules/home/ansible.nix:3`,
  `modules/home/ruby.nix:54`, `modules/home/bun.nix:13`,
  `modules/home/rust.nix:13`, `modules/home/telemetry.nix:32`,
  `modules/home/go.nix:9`, `modules/home/hk.nix:9`,
  `modules/home/claude-skills.nix:372`, `modules/home/less.nix:3`,
  `modules/home/pitchfork.nix:10`, `modules/home/starship.nix:3`,
  `modules/home/nodejs.nix:15`
- Modify: `GLOSSARY.md:90-92` (insert after **App**, under `### Applications`)

**Interfaces:**

- Consumes: `my.launchd.extraVariables` (`listOf str`, declared in
  `modules/home/options.nix`; name and shape unchanged). At the locked `work`
  revision (`ef81795`) the work layer sets nothing through it: its export of
  `CLOUDSDK_CONFIG`, `PI_AGENT_DIR`, `PI_CODING_AGENT_DIR` and `VIBE_HOME`
  through this option is unmerged, and C1.4 waits for it.
- Produces: in launchd-env.nix, `upstreamGuiNames` (replaces `redirectNames`)
  holding exactly `XDG_BIN_HOME`, `XDG_CACHE_HOME`, `XDG_CONFIG_HOME`,
  `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `guiVariables` (replaces `redirects`),
  the session variables named by `upstreamGuiNames ++ extraVariables` that are
  set. `envVariables` keeps its shape
  (`{ PATH; NIX_SSL_CERT_FILE; } // guiVariables`); C23.2 later edits its `PATH`
  line.
- Produces: the convention later sections follow: a module setting a GUI
  variable lists it in `my.launchd.extraVariables` on the line after its setter.
- Produces: the glossary term **GUI variable** (`### Applications`, after
  **App**), which later tasks, comments and C7's **Variant variable** entry may
  use.

- [ ] **Step 1: Record the export as F leaves it**

```bash
cfg='.#darwinConfigurations.Patricks-MacBook-Pro.config'
nix eval --json --override-input work path:./stubs/work \
  "$cfg.launchd.user.envVariables" > "$TMPDIR/c1-envVariables-before.json"
jq -r 'keys[]' "$TMPDIR/c1-envVariables-before.json"
```

Expected, 29 names, one per line (F's tree is the ground truth; if it prints
anything else, stop and reconcile with F before going on):

```text
ANDROID_AVD_HOME
ANDROID_EMULATOR_HOME
ANDROID_USER_HOME
ANSIBLE_HOME
BUNDLE_USER_HOME
BUN_INSTALL
CARGO_HOME
CHECKPOINT_DISABLE
CLAUDE_CONFIG_DIR
GOMODCACHE
GOPATH
GRADLE_USER_HOME
HK_STATE_DIR
IMPECCABLE_BIN
IMPECCABLE_HOME
LESSHISTFILE
NIX_SSL_CERT_FILE
PATH
PITCHFORK_CONFIG_DIR
PITCHFORK_STATE_DIR
RUSTUP_HOME
STARSHIP_CACHE
XDG_BIN_HOME
XDG_CACHE_HOME
XDG_CONFIG_HOME
XDG_DATA_HOME
XDG_STATE_HOME
npm_config_cache
npm_config_userconfig
```

A sandbox-off call gets a different `$TMPDIR` from a sandboxed one: run this
step and Step 7's diff with the sandbox off, so both see the same file.

- [ ] **Step 2: Write the setter-side test and see it fail**

```bash
cfg='.#darwinConfigurations.Patricks-MacBook-Pro.config'
nix eval --json --override-input work path:./stubs/work \
  "$cfg.home-manager.users.patrick.my.launchd.extraVariables" \
  --apply 'builtins.sort builtins.lessThan' | jq -r '.[]'
```

Expected after this task, 22 names, one per line (the 29 less `PATH`,
`NIX_SSL_CERT_FILE` and the five upstream `XDG_*_HOME`):

```text
ANDROID_AVD_HOME
ANDROID_EMULATOR_HOME
ANDROID_USER_HOME
ANSIBLE_HOME
BUNDLE_USER_HOME
BUN_INSTALL
CARGO_HOME
CHECKPOINT_DISABLE
CLAUDE_CONFIG_DIR
GOMODCACHE
GOPATH
GRADLE_USER_HOME
HK_STATE_DIR
IMPECCABLE_BIN
IMPECCABLE_HOME
LESSHISTFILE
PITCHFORK_CONFIG_DIR
PITCHFORK_STATE_DIR
RUSTUP_HOME
STARSHIP_CACHE
npm_config_cache
npm_config_userconfig
```

Now the list is empty and it prints nothing.

- [ ] **Step 3: Declare each name on the line after its setter**

No comment on any of these; the option's name says what the line does. Each
bullet names the file, what the new line follows (line numbers at a07c2f4) and
the names. The line is `my.launchd.extraVariables = [ ... ];` holding those
names in ASCII order, one name per line when there are two or more (nixfmt's
layout).

- `modules/home/darwin/android-studio.nix`, after the
  `home.sessionVariables = { ... };` block ending line 27: `ANDROID_AVD_HOME`,
  `ANDROID_EMULATOR_HOME`, `ANDROID_USER_HOME`, `GRADLE_USER_HOME`.
- `modules/home/ansible.nix`, after line 3,
  `home.sessionVariables.ANSIBLE_HOME = ...;`: `ANSIBLE_HOME`.
- `modules/home/ruby.nix`, after line 54,
  `home.sessionVariables.BUNDLE_USER_HOME = ...;`: `BUNDLE_USER_HOME`.
- `modules/home/bun.nix`, after the block ending line 13: `BUN_INSTALL`.
- `modules/home/rust.nix`, after the block ending line 13: `CARGO_HOME`,
  `RUSTUP_HOME`.
- `modules/home/telemetry.nix`, after the block ending line 32, before the
  comment at 34: `CHECKPOINT_DISABLE`.
- `modules/home/go.nix`, after the block ending line 9: `GOMODCACHE`, `GOPATH`.
- `modules/home/hk.nix`, after line 9,
  `home.sessionVariables.HK_STATE_DIR = ...;`: `HK_STATE_DIR`.
- `modules/home/claude-skills.nix`, after the
  `home.sessionVariables = lib.mkMerge [ ... ];` ending line 372, inside
  `config`: `IMPECCABLE_BIN`, `IMPECCABLE_HOME`.
- `modules/home/less.nix`, after line 3,
  `home.sessionVariables.LESSHISTFILE = ...;`: `LESSHISTFILE`.
- `modules/home/pitchfork.nix`, after the block ending line 10:
  `PITCHFORK_CONFIG_DIR`, `PITCHFORK_STATE_DIR`.
- `modules/home/starship.nix`, after line 3,
  `home.sessionVariables.STARSHIP_CACHE = ...;`: `STARSHIP_CACHE`.
- `modules/home/nodejs.nix`, after the block ending line 15: `npm_config_cache`,
  `npm_config_userconfig`.

For example, `modules/home/rust.nix` gains:

```nix
  my.launchd.extraVariables = [
    "CARGO_HOME"
    "RUSTUP_HOME"
  ];
```

`IMPECCABLE_BIN` is listed unconditionally although its setter is inside
`lib.mkIf (impeccableEngine != null)`: launchd-env.nix drops a listed name that
no module sets. `IMPECCABLE_HOME`'s setter is unconditional (lines 367-372).

In `modules/home/claude-code.nix`, delete the two-line comment above
`home.sessionVariables.CLAUDE_CONFIG_DIR = ...;` (lines 155-156; the new line
says the same) and add, on the line after that setter, at its 4-space indent:

```nix
    my.launchd.extraVariables = [ "CLAUDE_CONFIG_DIR" ];
```

- [ ] **Step 4: Cut launchd-env.nix's list down to the upstream names**

Replace everything from the comment above `redirectNames` (F11's wording)
through the end of the `redirects = ...;` binding with:

```nix
  # The GUI variables home-manager sets itself; every module here
  # declares its own beside its setter, in my.launchd.extraVariables.
  upstreamGuiNames = [
    "XDG_BIN_HOME"
    "XDG_CACHE_HOME"
    "XDG_CONFIG_HOME"
    "XDG_DATA_HOME"
    "XDG_STATE_HOME"
  ];

  guiVariables = lib.getAttrs (builtins.filter (n: sessionVariables ? ${n}) (
    lib.unique (upstreamGuiNames ++ home.my.launchd.extraVariables)
  )) sessionVariables;
```

and in `envVariables`, `// redirects;` becomes `// guiVariables;`. The presence
filter stays: the `XDG_*_HOME` names exist only with `xdg.enable`, and
`IMPECCABLE_BIN` is set only when `impeccableEngine` is non-null.

- [ ] **Step 5: Bring the option's comment in step**

`modules/home/options.nix:17-18` becomes:

```nix
    # modules/darwin/launchd-env.nix, so the module that sets a GUI
    # variable exports it to GUI-launched processes as well.
```

The option itself (`launchd.extraVariables`, lines 19-23) is untouched.

- [ ] **Step 6: Add GUI variable to the glossary**

The term lands with its first use (this task's comment and binding names).
Insert after the **App** entry (GLOSSARY.md:90-92), before `### Profiles`, with
one blank line on each side:

```markdown
**GUI variable**:\
A session variable launchd also exports to processes started from the Dock or by
an app, so a CLI an app spawns behaves as in a shell.\
_Avoid_: redirect, which is only the kind that moves state
```

- [ ] **Step 7: Run both tests and see them pass**

Run Step 2's command: it prints the 22 names above. Then:

```bash
cfg='.#darwinConfigurations.Patricks-MacBook-Pro.config'
nix eval --json --override-input work path:./stubs/work \
  "$cfg.launchd.user.envVariables" \
  | diff - "$TMPDIR/c1-envVariables-before.json" && echo unchanged
```

Expected: `unchanged` (names and values identical, `PATH` included).

- [ ] **Step 8: Run the suite**

nixfmt on the changed Nix files, then `mise run test` and `mise run lint`,
sandbox off. Both pass; the Linux eval proves the portable modules may set
`my.launchd.extraVariables` (declared in the portable `options.nix`). Then run
the section's real-work-layer `drvPath` command (above). Expected: a store path
ending in `.drv`. An error: stop and report it to Patrick.

- [ ] **Step 9: Commit**

```bash
git add modules/darwin/launchd-env.nix modules/home/options.nix \
  modules/home/claude-code.nix modules/home/darwin/android-studio.nix \
  modules/home/ansible.nix modules/home/ruby.nix modules/home/bun.nix \
  modules/home/rust.nix modules/home/telemetry.nix modules/home/go.nix \
  modules/home/hk.nix modules/home/claude-skills.nix modules/home/less.nix \
  modules/home/pitchfork.nix modules/home/starship.nix modules/home/nodejs.nix \
  GLOSSARY.md
git -c commit.gpgsign=false commit \
  -m "refactor(launchd): move GUI variables to setters" \
  -m "launchd-env.nix kept a central list of the session variables it
exports, so a module adding a state redirect had to edit a second file,
and the list had already missed CARGO_HOME, RUSTUP_HOME and
XDG_BIN_HOME. Each module now names its GUI variables in
my.launchd.extraVariables beside the setter, and launchd-env.nix keeps
only the XDG_*_HOME variables home-manager sets itself. The exported
set is unchanged; the glossary names the term."
```

### Task C1.2: Export every GUI variable

Applies the Spec's rule: besides state redirects and tool locators, the
telemetry and update opt-outs and `SSH_AUTH_SOCK`, `HELM_REGISTRY_CONFIG`,
`REGISTRY_AUTH_FILE`, `OP_ACCOUNT`, `AUBE_RUNTIME_INSTALLER`,
`RESEND_CREDENTIAL_STORE` and `RESEND_NO_UPDATE_NOTIFIER` reach GUI-launched
processes. ADR-0013 names `SSH_AUTH_SOCK` as meant for shells today, so the
amendment lands in this commit.

**Files:**

- Modify: `modules/home/telemetry.nix` (the one-name list C1.1 added after
  line 32)
- Modify: `modules/home/darwin/ssh.nix:96-98` (add after)
- Modify: `modules/home/containers.nix:130-134` (add after, inside `config`)
- Modify: `modules/home/onepassword.nix:8` (add after)
- Modify: `modules/home/aube.nix:22-26` (add after)
- Modify: `modules/home/resend.nix:10-20` (add after)
- Modify: `docs/adr/0013-gui-environment-from-an-allowlist.md:1-13` (whole file)

**Interfaces:**

- Consumes: `my.launchd.extraVariables` and the convention from C1.1.
- Produces: `launchd.user.envVariables` with exactly the 42 names in Step 1
  (stub work layer).

- [ ] **Step 1: Write the test and see it fail**

```bash
cfg='.#darwinConfigurations.Patricks-MacBook-Pro.config'
nix eval --json --override-input work path:./stubs/work \
  "$cfg.launchd.user.envVariables" --apply builtins.attrNames \
  | jq -r '.[]'
```

Expected after this task, 42 names, one per line:

```text
ANDROID_AVD_HOME
ANDROID_EMULATOR_HOME
ANDROID_USER_HOME
ANSIBLE_HOME
AUBE_RUNTIME_INSTALLER
BUNDLE_USER_HOME
BUN_INSTALL
CARGO_HOME
CHECKPOINT_DISABLE
CLAUDE_CONFIG_DIR
CLOUDSDK_CORE_DISABLE_USAGE_REPORTING
DISABLE_AUTOUPDATER
DISABLE_ERROR_REPORTING
GOMODCACHE
GOPATH
GRADLE_USER_HOME
HELM_REGISTRY_CONFIG
HF_HUB_DISABLE_TELEMETRY
HF_HUB_DISABLE_UPDATE_CHECK
HK_STATE_DIR
IMPECCABLE_BIN
IMPECCABLE_HOME
LESSHISTFILE
NIX_SSL_CERT_FILE
OP_ACCOUNT
PATH
PITCHFORK_CONFIG_DIR
PITCHFORK_STATE_DIR
REGISTRY_AUTH_FILE
RESEND_CREDENTIAL_STORE
RESEND_NO_UPDATE_NOTIFIER
RESEND_TELEMETRY_DISABLED
RUSTUP_HOME
SSH_AUTH_SOCK
STARSHIP_CACHE
XDG_BIN_HOME
XDG_CACHE_HOME
XDG_CONFIG_HOME
XDG_DATA_HOME
XDG_STATE_HOME
npm_config_cache
npm_config_userconfig
```

Now it prints the 29 names from C1.1 Step 1.

- [ ] **Step 2: Declare the new GUI variables beside their setters**

`modules/home/telemetry.nix`: every variable it sets is an opt-out, so the list
C1.1 added becomes all seven:

```nix
  my.launchd.extraVariables = [
    "CHECKPOINT_DISABLE"
    "CLOUDSDK_CORE_DISABLE_USAGE_REPORTING"
    "DISABLE_AUTOUPDATER"
    "DISABLE_ERROR_REPORTING"
    "HF_HUB_DISABLE_TELEMETRY"
    "HF_HUB_DISABLE_UPDATE_CHECK"
    "RESEND_TELEMETRY_DISABLED"
  ];
```

The rest, each a `my.launchd.extraVariables = [ ... ];` line after its setter's
block (lines at a07c2f4), names in ASCII order and one per line when two or
more, no comments:

- `modules/home/darwin/ssh.nix`, after the block at 96-98: `SSH_AUTH_SOCK`.
- `modules/home/containers.nix`, after the block at 130-134, at its 4-space
  indent inside `config`: `HELM_REGISTRY_CONFIG`, `REGISTRY_AUTH_FILE`.
- `modules/home/onepassword.nix`, after line 8: `OP_ACCOUNT`.
- `modules/home/aube.nix`, after the block at 22-26: `AUBE_RUNTIME_INSTALLER`.
- `modules/home/resend.nix`, after the block at 10-20:
  `RESEND_CREDENTIAL_STORE`, `RESEND_NO_UPDATE_NOTIFIER`.

`RESEND_CREDENTIAL_STORE` is set only on macOS
(`lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin`); its name is listed
unconditionally, and on Linux nothing reads the list.

- [ ] **Step 3: Run the test and see it pass**

Step 1's command prints the 42 names.

- [ ] **Step 4: Amend ADR-0013 in place**

Same file name and title; the whole body is replaced with (prettier's wrap at
80, as `lint:markdown` checks):

```markdown
# GUI processes get session variables from an allowlist

A process started from the Dock or by an app inherits launchd's environment, not
a shell's, so a CLI an app spawns misses the session variables that make it
behave as in a shell: it recreates the dotfiles a state redirect exists to
prevent, reports telemetry or checks for updates, and reaches macOS's own SSH
agent or the wrong 1Password account. `modules/darwin/launchd-env.nix` exports
to launchd, together with `PATH` and the certificate bundle, only the GUI
variables: state redirects, tool locators, telemetry and update opt-outs,
`SSH_AUTH_SOCK`, `HELM_REGISTRY_CONFIG`, `REGISTRY_AUTH_FILE`, `OP_ACCOUNT`,
`AUBE_RUNTIME_INSTALLER`, `RESEND_CREDENTIAL_STORE` and
`RESEND_NO_UPDATE_NOTIFIER`. Every other session variable stays shell-only,
among them `EDITOR`, `PAGER`, `MANPAGER`, `BAT_*`, `FZF_*`, `MISE_COLOR_THEME`,
`STARSHIP_CONFIG`, `XDG_*_DIR`, `TERMINFO_DIRS`, `LC_ALL`, `LC_CTYPE`,
`PYTHONIOENCODING`, `MANROFFOPT` and `NH_DARWIN_FLAKE`: exporting them all would
put an interactive shell's settings into every GUI app's environment, and a
value that relies on shell expansion cannot pass through `launchctl setenv`
intact.

The module that sets a GUI variable exports it through
`my.launchd.extraVariables`, beside its setter, so the export cannot drift from
what is set and the work layer exports its own without this repository naming
them. `launchd-env.nix` names only the `XDG_*_HOME` variables home-manager sets
itself.
```

- [ ] **Step 5: Run the suite**

nixfmt on the changed Nix files, then `mise run test` and `mise run lint`,
sandbox off. Both pass; `.github/scripts/markdown-format.sh` and
`markdown-lint.sh` cover the ADR. Then the section's real-work-layer `drvPath`
command: a store path ending in `.drv`. An error: stop and report it to Patrick.

- [ ] **Step 6: Commit**

```bash
git add modules/home/telemetry.nix modules/home/darwin/ssh.nix \
  modules/home/containers.nix modules/home/onepassword.nix \
  modules/home/aube.nix modules/home/resend.nix \
  docs/adr/0013-gui-environment-from-an-allowlist.md
git -c commit.gpgsign=false commit \
  -m "feat(launchd): export every GUI variable" \
  -m "A CLI an app spawns ran without the telemetry and update opt-outs,
reached macOS's own SSH agent rather than Secretive, left op on
whichever account signed in last and let aube build Node installs mise
knows nothing about. These are GUI variables by the rule ADR-0013 now
records, so their modules export them."
```

**After Patrick's switch** (no evaluation shows it):
`launchctl getenv SSH_AUTH_SOCK` names Secretive's socket and
`launchctl getenv OP_ACCOUNT` prints `my.1password.eu`, and again after his next
login (the session-env agent); an app already running sees the new GUI variables
only once relaunched. Every ssh and git an app spawns now goes through
Secretive: expect Touch ID prompts from editors and Orca, and failures when
Secretive is not running at login. A `git fetch` from Zed and from an Orca
terminal, before and after a re-login, shows it.

### Task C1.3: Reject GUI variables that are not literal

nix-darwin writes each `launchd.user.envVariables` entry as
`launchctl setenv NAME 'VALUE'` (`modules/system/launchd.nix:14-16` in the
pinned nix-darwin), and `modules/darwin/launchd-env/set-env.sh` reads one
`NAME=VALUE` per line, so a `'` breaks the activation line, a newline breaks the
login agent, and a `$` reaches launchd unexpanded where a shell would expand it.
Evaluation now fails instead, naming the variables. The check covers the whole
`envVariables` set, `PATH` and `NIX_SSL_CERT_FILE` included.

**Files:**

- Modify: `modules/darwin/launchd-env.nix` (a new `let` binding after
  `envVariables`, at a07c2f4 line 59; an `assertions` attribute at the top of
  the module body, line 71)
- Modify: `docs/adr/0013-gui-environment-from-an-allowlist.md` (a third
  paragraph)

**Interfaces:**

- Consumes: `envVariables` (the `let` binding in launchd-env.nix).
- Produces: a nix-darwin assertion whose message is exactly
  `GUI variables must be literal, with no ', $ or newline: <NAMES>`, `<NAMES>`
  the offending names in ASCII order, joined by a comma and a space. C23.2's new
  `PATH` (`${dirOf mbx.cargoShim}:...`) must stay literal to pass it.

- [ ] **Step 1: Write the probe and see it fail**

```bash
sys='.#darwinConfigurations.Patricks-MacBook-Pro'
msg="GUI variables must be literal, with no ', \$ or newline"
nix eval --json --override-input work path:./stubs/work "$sys" --apply '
c:
let
  probe = c.extendModules {
    modules = [
      {
        home-manager.users.patrick = {
          home.sessionVariables = {
            PROBE_DOLLAR = "$HOME/probe";
            PROBE_NEWLINE = "a\nb";
            PROBE_PLAIN = "plain";
            PROBE_QUOTE = "a'\''b";
            PROBE_UNEXPORTED = "a'\''b";
          };
          my.launchd.extraVariables = [
            "PROBE_DOLLAR"
            "PROBE_NEWLINE"
            "PROBE_PLAIN"
            "PROBE_QUOTE"
          ];
        };
      }
    ];
  };
  failed = builtins.filter (a: !a.assertion) probe.config.assertions;
in
map (a: a.message) failed
' | jq -c --arg m "$msg: " 'map(ltrimstr($m))'
```

The `jq` filter strips the message text up to the names, so a message that does
not start with exactly that text prints in full. Expected after this task
(`PROBE_PLAIN` passes, `PROBE_UNEXPORTED` is not checked):

```json
["PROBE_DOLLAR, PROBE_NEWLINE, PROBE_QUOTE"]
```

Now it prints `[]`.

- [ ] **Step 2: Add the check**

In launchd-env.nix's `let`, after `envVariables`:

```nix
  notLiteral = builtins.attrNames (
    lib.filterAttrs (
      _: value:
      lib.any (c: lib.hasInfix c (toString value)) [
        "'"
        "$"
        "\n"
      ]
    ) envVariables
  );
```

`lib.hasInfix` per character rather than one `builtins.match`, whose `.` does
not reliably cross a newline. `toString` because a session variable may be an
int, float, bool, path or null (home-manager's `home.sessionVariables` type),
and `hasInfix` throws on anything but a string.

At the top of the module body, before `launchd.user.envVariables`:

```nix
  assertions = [
    {
      assertion = notLiteral == [ ];
      message =
        "GUI variables must be literal, with no ', $ or newline: "
        + lib.concatStringsSep ", " notLiteral;
    }
  ];
```

nixfmt joins the `message` onto one line. No comment: the message and ADR-0013
carry the why. Keep `launchctl` out of comments and messages (it is not in
`codebook.toml`).

- [ ] **Step 3: Run the probe and see it pass**

Step 1's command prints the one-element list above.

- [ ] **Step 4: Run the check against the real work layer**

The stub sets no session variables, so the check has not yet met the work
layer's. Run the section's real-work-layer assertion command (above, no
`--override-input`; it prints assertion messages only). Expected: `[]`. At the
`work` lock of `a07c2f4` the work layer exports nothing, so this proves this
repository's exports pass on the real configuration; once Patrick has bumped the
lock it also covers the work layer's exports. Anything else: stop and report the
messages to Patrick, because the value to fix lives in his work repository or in
a module here, not in this check.

- [ ] **Step 5: Add the third paragraph to ADR-0013**

Append, after the paragraph ending "home-manager sets itself.", with one blank
line before it:

```markdown
Evaluation fails for an exported value holding `'`, `$` or a newline: nix-darwin
writes each value single-quoted into a `launchctl setenv` line, the login agent
reads one variable per line, and launchd never expands what a shell would.
```

- [ ] **Step 6: Run the suite**

nixfmt on launchd-env.nix, then `mise run test` and `mise run lint`, sandbox
off. The macOS eval passing proves no current GUI variable (C1.2's 42, all
checked) holds any of the three. Then the section's real-work-layer `drvPath`
command: a store path ending in `.drv`. An error: stop and report it to Patrick.

- [ ] **Step 7: Commit**

```bash
git add modules/darwin/launchd-env.nix \
  docs/adr/0013-gui-environment-from-an-allowlist.md
git -c commit.gpgsign=false commit \
  -m "feat(launchd): reject non-literal GUI variables" \
  -m "nix-darwin writes each exported value single-quoted into a launchctl
setenv line and the login agent reads one NAME=VALUE per line, so a
quote or a newline breaks the export and a dollar sign reaches launchd
unexpanded. Evaluation now fails and names the variable instead of
activating a broken or silently different environment."
```

### Task C1.4: Declare shell-only variables and check the home directory

The second check: a session variable whose value lies under the home directory
must be a GUI variable or declared shell-only. The shell-only list is the Spec's
new option, `my.launchd.shellOnlyVariables`, set beside each setter like
`extraVariables`, so the work layer can classify its own home-valued variables
without this repository naming them. "Under the home directory" means the value,
as a string, starts with `<homeDirectory>/`: the home directory itself and a
sibling such as `/Users/patrickx` do not count.

This task waits for Patrick (Step 1). The work layer at the `work` lock of
`a07c2f4` (`ef81795`) sets `CLOUDSDK_CONFIG`, `PI_AGENT_DIR`,
`PI_CODING_AGENT_DIR` and `VIBE_HOME` under the home directory without exporting
them, so this check would fail his real build and `darwin-rebuild` while every
stub eval passes. Patrick merges the work layer's export of the four
(ubiops-nix-config, today only in its unmerged melusine worktree) and bumps the
lock with `nix flake update work`, as his own commit. Neither is the agent's to
do. The stub evals stay; Steps 1 and 8 add the real work layer.

Because it waits, this task lands in practice after C7.2 (starship.nix), C7.4
(moor.nix) and C23.3 (helix.nix), which do not. It works in either order: Step 6
says where each line goes in both cases.

**Files:**

- Modify: `modules/home/options.nix` (new option after `launchd.extraVariables`,
  at a07c2f4 after line 23)
- Modify: `modules/darwin/launchd-env.nix` (C1.1's comment and
  `upstreamGuiNames`; the `inherit (home.home)` line, at a07c2f4 line 12; a new
  `let` binding after C1.3's `notLiteral`; a second entry in `assertions`)
- Modify (one line or list added after the setter): `modules/home/helix.nix`
  (after `home.sessionVariables.EDITOR`; inside `config` once C23.3 has landed),
  `modules/home/moor.nix` (after the `home.sessionVariables = { ... };` block),
  `modules/home/bat.nix:64-75`, `modules/home/fzf.nix:21-37`,
  `modules/home/mise.nix:34-39`, `modules/home/locale.nix:6-17`,
  `modules/home/nh.nix:7-9`, `modules/home/starship.nix` (after the
  `programs.starship = { ... };` block), `home/patrick/darwin.nix:64-71`
- Modify: `docs/adr/0013-gui-environment-from-an-allowlist.md` (the second
  paragraph's last sentence, from C1.2; the third paragraph, from C1.3)
- Modify: `docs/architecture.md:78-79` (a bullet under `## Conventions`, before
  the `codebook.toml` bullet)

**Interfaces:**

- Consumes: the work layer at a `work` lock where `CLOUDSDK_CONFIG`,
  `PI_AGENT_DIR`, `PI_CODING_AGENT_DIR` and `VIBE_HOME` are in its
  `my.launchd.extraVariables` (or, once this task's option exists, its
  `my.launchd.shellOnlyVariables`). Patrick's merge and lock bump; Step 1 checks
  it.
- Produces: `my.launchd.shellOnlyVariables`, `lib.types.listOf lib.types.str`,
  default `[ ]`, declared in `modules/home/options.nix` (consumed by a
  macOS-only module, set by portable ones).
- Produces: in launchd-env.nix, `upstreamShellOnlyNames = [ "TERMINFO_DIRS" ]`
  (home-manager's `targets/darwin/terminfo.nix` sets it on macOS) and a second
  nix-darwin assertion whose message is exactly this, one line in the
  evaluation's output (the break after `in` is a space), `<NAMES>` in ASCII
  order, joined by a comma and a space:

  ```text
  Session variables under the home directory must be in
  my.launchd.extraVariables or my.launchd.shellOnlyVariables: <NAMES>
  ```

- Produces, for every later section: a new `home.sessionVariables` entry whose
  value starts with `/Users/patrick/` fails the macOS eval until its module
  lists it in one of the two options. Every name this repository sets is in
  exactly one of them after this task; Step 9 is the check that proves it.

- [ ] **Step 1: Precondition: the real work layer classifies its own**

Both commands run without `--override-input` and print only names and assertion
messages, never a value from the work layer:

```bash
cfg='.#darwinConfigurations.Patricks-MacBook-Pro.config'
nix eval --json "$cfg.home-manager.users.patrick.my.launchd" --apply '
l:
let
  classified = l.extraVariables ++ (l.shellOnlyVariables or [ ]);
in
builtins.filter (n: !(builtins.elem n classified)) [
  "CLOUDSDK_CONFIG"
  "PI_AGENT_DIR"
  "PI_CODING_AGENT_DIR"
  "VIBE_HOME"
]'
nix eval --json "$cfg.assertions" \
  --apply 'as: map (a: a.message) (builtins.filter (a: !a.assertion) as)'
```

Expected: `[]` twice. (With the stub the first prints all four names.)

If the first prints any name, or the second any message: stop, change no file in
this task, and report to Patrick that the work layer's export of the printed
names has to merge and the `work` lock has to be bumped before C1.4.

If the first fails instead with an error that the option
`home-manager.users.patrick.my.launchd.shellOnlyVariables` does not exist, the
work layer declares the four shell-only, which evaluates only once Step 3
declares the option: carry on, and Step 8 decides.

- [ ] **Step 2: Write the probe and see it fail**

```bash
sys='.#darwinConfigurations.Patricks-MacBook-Pro'
msg='Session variables under the home directory must be in'
msg+=' my.launchd.extraVariables or my.launchd.shellOnlyVariables'
nix eval --json --override-input work path:./stubs/work "$sys" --apply '
c:
let
  h = c.config.users.users.patrick.home;
  probe = c.extendModules {
    modules = [
      {
        home-manager.users.patrick = {
          home.sessionVariables = {
            PROBE_ELSEWHERE = "/opt/probe";
            PROBE_EXPORTED = "${h}/Library/probe-exported";
            PROBE_HOME = "${h}/Library/probe";
            PROBE_SHELL = "${h}/probe-shell";
            PROBE_SIBLING = "${h}x/probe";
          };
          my.launchd.extraVariables = [ "PROBE_EXPORTED" ];
          my.launchd.shellOnlyVariables = [ "PROBE_SHELL" ];
        };
      }
    ];
  };
  failed = builtins.filter (a: !a.assertion) probe.config.assertions;
in
map (a: a.message) failed
' | jq -c --arg m "$msg: " 'map(ltrimstr($m))'
```

As in C1.3 Step 1, a message that does not start with exactly `$msg` followed by
a colon and a space prints in full. Expected after this task:

```json
["PROBE_HOME"]
```

Now `nix` fails with an error that the option
`home-manager.users.patrick.my.launchd.shellOnlyVariables` does not exist, and
`jq` prints nothing.

- [ ] **Step 3: Declare the option**

In `modules/home/options.nix`, directly after the `launchd.extraVariables`
option (alphabetical within `options.my`):

```nix
    # modules/darwin/launchd-env.nix, which fails evaluation for a
    # session variable under the home directory that is in neither
    # this list nor launchd.extraVariables.
    launchd.shellOnlyVariables = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "…";
    };
```

where the `description` string, on one line, is:

```text
Session variables kept out of GUI-launched processes on purpose, by name.
```

- [ ] **Step 4: Add the check to launchd-env.nix**

`inherit (home.home) sessionVariables;` becomes
`inherit (home.home) sessionVariables homeDirectory;`. C1.1's comment above
`upstreamGuiNames` becomes the first three lines below, and the shell-only
counterpart follows the list:

```nix
  # The names home-manager sets itself. Every module here declares its
  # own beside its setter, in my.launchd.extraVariables or
  # my.launchd.shellOnlyVariables.
  upstreamGuiNames = [
    …unchanged…
  ];
  upstreamShellOnlyNames = [ "TERMINFO_DIRS" ];
```

After `notLiteral`:

```nix
  shellOnlyNames =
    upstreamShellOnlyNames ++ home.my.launchd.shellOnlyVariables;

  unclassified = builtins.filter (
    name:
    lib.hasPrefix "${homeDirectory}/" (toString sessionVariables.${name})
    && !(envVariables ? ${name})
    && !(builtins.elem name shellOnlyNames)
  ) (builtins.attrNames sessionVariables);
```

"Exported" is presence in `envVariables`, so a name the work layer exports
counts. Second entry in `assertions`:

```nix
    {
      assertion = unclassified == [ ];
      message =
        "Session variables under the home directory must be in "
        + "my.launchd.extraVariables or my.launchd.shellOnlyVariables: "
        + lib.concatStringsSep ", " unclassified;
    }
```

- [ ] **Step 5: See the real configuration fail**

```bash
msg='Session variables under the home directory must be in'
msg+=' my.launchd.extraVariables or my.launchd.shellOnlyVariables'
mise run eval:darwin 2>&1 | grep -F -- "- $msg: " | sed 's/.*: //' \
  | tr ',' '\n' | tr -d ' '
```

Expected: the eval fails on its failed assertions, and the pipeline prints the
seven unclassified names, one per line (it prints nothing if the eval passes):

```text
STARSHIP_CONFIG
XDG_DESKTOP_DIR
XDG_DOWNLOAD_DIR
XDG_MUSIC_DIR
XDG_PICTURES_DIR
XDG_PUBLICSHARE_DIR
XDG_VIDEOS_DIR
```

- [ ] **Step 6: Declare the shell-only names beside their setters**

Each a `my.launchd.shellOnlyVariables = [ ... ];` line after its setter's block
(lines at a07c2f4), no comment, names in ASCII order and one per line when two
or more:

- `modules/home/helix.nix`: `my.launchd.shellOnlyVariables = [ "EDITOR" ];` on
  the line after `home.sessionVariables.EDITOR = lib.getExe pkgs.helix;`; when
  helix.nix has `config = {` (C23.3 has landed), inside `config` at its indent,
  never at top level beside `options`.
- `modules/home/moor.nix`, after the `home.sessionVariables = { ... };` block:
  `my.launchd.shellOnlyVariables = [ "PAGER" ];`, or `[ "MOOR" "PAGER" ];` once
  C7.4 has landed (`git grep -n "MOOR = flags" modules/home/moor.nix` prints a
  line).
- `modules/home/bat.nix`, after the block at 64-75: `BAT_THEME_DARK`,
  `BAT_THEME_LIGHT`, `MANPAGER`, `MANROFFOPT`.
- `modules/home/fzf.nix`, after the block at 21-37: `FZF_ALT_C_COMMAND`,
  `FZF_ALT_C_OPTS`, `FZF_CTRL_R_OPTS`, `FZF_CTRL_T_COMMAND`, `FZF_CTRL_T_OPTS`,
  `FZF_DEFAULT_COMMAND`, `FZF_DEFAULT_OPTS_FILE`.
- `modules/home/mise.nix`, after the block at 34-39: `MISE_COLOR_THEME`.
- `modules/home/locale.nix`, after the block at 6-17: `LC_ALL`, `LC_CTYPE`,
  `PYTHONIOENCODING`.
- `modules/home/nh.nix`, after the block at 7-9: `NH_DARWIN_FLAKE`,
  unconditional, outside the `lib.mkIf`.
- `modules/home/starship.nix`, after the `programs.starship = { ... };` block
  (5-17, whose upstream module sets `STARSHIP_CONFIG`), and before C7.2's
  `my.theme.variantVariables.STARSHIP_CONFIG = lib.mkIf ...` when present:
  `STARSHIP_CONFIG`.
- `home/patrick/darwin.nix`, after the block at 64-71: `XDG_DESKTOP_DIR`,
  `XDG_DOWNLOAD_DIR`, `XDG_MUSIC_DIR`, `XDG_PICTURES_DIR`,
  `XDG_PUBLICSHARE_DIR`, `XDG_VIDEOS_DIR`.

`home/patrick/linux.nix` declares nothing: nothing reads the list on Linux.
moor.nix lists both `MOOR` and `PAGER` once C7.4 has made `MOOR` a session
variable, and `PAGER` alone before that, in which case C7.4 extends the line.

- [ ] **Step 7: Run the probe and the macOS eval and see them pass**

Step 2's command prints the one-element list above (`PROBE_ELSEWHERE` and
`PROBE_SIBLING` are not under the home directory, `PROBE_EXPORTED` and
`PROBE_SHELL` are classified). `mise run eval:darwin` passes. C1.3 Step 1's
probe still prints its one message only. If C23.3 has landed, also run C23.3
Step 7's `builtins.elem "EDITOR"` command; expect `true`.

- [ ] **Step 8: Run the check against the real work layer**

Step 1's second command again, without `--override-input`. Expected: `[]`. A
message naming the work layer's variables means it classifies them in neither
option: stop, and report the names (never their values) to Patrick. Then the
section's real-work-layer `drvPath` command: a store path ending in `.drv`.

- [ ] **Step 9: Check that every session variable is classified**

```bash
cfg='.#darwinConfigurations.Patricks-MacBook-Pro.config'
nix eval --json --override-input work path:./stubs/work "$cfg" --apply '
cfg:
let
  home = cfg.home-manager.users.patrick;
  classified =
    builtins.attrNames cfg.launchd.user.envVariables
    ++ home.my.launchd.shellOnlyVariables
    ++ [ "TERMINFO_DIRS" ];
  names = builtins.attrNames home.home.sessionVariables;
in
builtins.filter (n: !(builtins.elem n classified)) names
'
```

Expected: `[]`: 66 names (40 GUI variables, 26 shell-only), or 67 (27
shell-only) once C7.4 has landed. Not an assertion: the Spec checks only
home-valued names, so a later non-home variable can stay unclassified. If C7.4
runs after this task, it re-runs this command (C7.4 Step 4).

- [ ] **Step 10: Finish ADR-0013 and the architecture conventions**

The ADR's second paragraph (from C1.2) now has to name `TERMINFO_DIRS` as well,
so it reads:

```markdown
The module that sets a GUI variable exports it through
`my.launchd.extraVariables`, beside its setter, so the export cannot drift from
what is set and the work layer exports its own without this repository naming
them. `launchd-env.nix` names only what home-manager sets itself: the
`XDG_*_HOME` variables it exports and `TERMINFO_DIRS`, which stays shell-only.
```

The third paragraph (from C1.3) gains a second sentence, so it reads:

```markdown
Evaluation fails for an exported value holding `'`, `$` or a newline: nix-darwin
writes each value single-quoted into a `launchctl setenv` line, the login agent
reads one variable per line, and launchd never expands what a shell would. It
fails as well for a session variable whose value lies under the home directory
and that is neither exported nor declared shell-only, beside its setter, through
`my.launchd.shellOnlyVariables`, so a new state redirect cannot be left out of
the export unnoticed.
```

In `docs/architecture.md`, under `## Conventions`, insert before the
`codebook.toml` bullet (line 79 at a07c2f4):

```markdown
- A module that sets a session variable lists it beside the setter: in
  `my.launchd.extraVariables` when it is a GUI variable, in
  `my.launchd.shellOnlyVariables` when it is meant for a shell alone. The macOS
  eval fails for one whose value lies under the home directory and that is in
  neither (ADR-0013).
```

- [ ] **Step 11: Run the suite**

nixfmt on the changed Nix files, then `mise run test` and `mise run lint`,
sandbox off. Both pass.

- [ ] **Step 12: Commit**

```bash
git add modules/home/options.nix modules/darwin/launchd-env.nix \
  modules/home/helix.nix modules/home/moor.nix modules/home/bat.nix \
  modules/home/fzf.nix modules/home/mise.nix modules/home/locale.nix \
  modules/home/nh.nix modules/home/starship.nix home/patrick/darwin.nix \
  docs/adr/0013-gui-environment-from-an-allowlist.md docs/architecture.md
git -c commit.gpgsign=false commit \
  -m "feat(launchd): declare shell-only variables" \
  -m "A state redirect left out of the export lets a GUI-spawned CLI
recreate the dotfile it exists to prevent, and nothing noticed. A
session variable under the home directory must now be a GUI variable
or be declared shell-only beside its setter, and evaluation fails
otherwise; my.launchd.shellOnlyVariables lets the work layer classify
its own without this repository naming them."
```

#### Notes for section C1

- launchd-env.nix's `let` after C1, in order: `user`, `home`,
  `inherit (home.home) sessionVariables homeDirectory`, `upstreamGuiNames`,
  `upstreamShellOnlyNames`, `guiVariables` (formerly `redirects`), `mbx`,
  `envVariables`, `notLiteral`, `shellOnlyNames`, `unclassified`, `setEnv`.
  C23.2 edits only `envVariables`' `PATH` line.
- moor.nix after C1.4 and C7.4, in either order:
  `my.launchd.shellOnlyVariables = [ "MOOR" "PAGER" ];` on the line after
  home.sessionVariables. Whichever of C1.4 and C7.4 lands second writes it.
  `MOOR` is not home-valued, so C1.4's assertion does not notice it missing;
  only C1.4 Step 9's command does.
- C23.3 (helix.nix): whichever of C1.4 and C23.3 lands second puts
  `my.launchd.shellOnlyVariables = [ "EDITOR" ];` inside `config`, after
  `home.sessionVariables.EDITOR`.
- starship.nix after C1 and C7.2: C1.1's `STARSHIP_CACHE` line and C1.4's
  `STARSHIP_CONFIG` line both stay, because upstream `programs.starship` still
  sets `STARSHIP_CONFIG` as a session variable; C7.2's Variant declaration
  follows the shell-only line.
- Session variables on macOS after C1 (stub): 66 (or 67 with C7.4's MOOR): 40
  exported plus 26 (27) shell-only, `TERMINFO_DIRS` through
  `upstreamShellOnlyNames` and the rest through `my.launchd.shellOnlyVariables`.
  With the real work layer after Patrick's bump, `launchd.user.envVariables`
  holds C1.2's 42 names plus the work layer's own exports.
- A section that moves the `CLAUDE_CONFIG_DIR` or `IMPECCABLE_*` setter (C4, C5)
  moves its `my.launchd.extraVariables` line with it.
- If the work layer declares its four variables shell-only instead of exporting
  them, its lock bump cannot evaluate until C1.4 Step 3 declares the option, so
  Patrick's real build breaks between the bump and C1.4. Exporting them, as the
  unmerged melusine change does, avoids that.
- launchd-env.nix's presence filter drops a listed name that no module sets, so
  a misspelled name in `my.launchd.extraVariables` passes silently; only C1.1
  Step 2's and C1.2 Step 1's exact lists catch one.
- Nothing forbids a name that is both exported and shell-only: the Spec names
  two checks only. The Spec's patterns `BAT_*`, `FZF_*` and `XDG_*_DIR` are
  spelled out as exact names beside their setters; the check matches no
  patterns.
- The assertions are tested by one-off `extendModules` probes, not a flake
  check, so C1 adds no CI job and no `mise` task. Later edits to launchd-env.nix
  (C23.2's `PATH`) are covered by the real configuration evaluating, not by the
  probes.
- The `docs/architecture.md` convention bullet (C1.4 Step 10) goes beyond the
  Spec, because the classification is a convention new code must follow.
- A cross-reference to "C1.4 Step 7's probe" written against an earlier draft
  means Step 9's classification command.

---

## Section C23: Cards 2 and 3, language servers

Four tasks, in this order: C23.1 gives `lib/default.nix` a `substituteValue`,
with its tests as a flake check that CI and `mise` run; C23.2 publishes mbx's
Cargo shim as `passthru.cargoShim`; C23.3 declares `my.nixd.settings` once in
`helix.nix`; C23.4 renders the LSP plugin's `.lsp.json` from a commands-only
`nix-lsp.json` plus the `config` Helix's `languages.toml` gives eight servers,
and records ADR-0014.

Conventions for the whole section:

- Line numbers are those of `a07c2f4`. Find every edit by the quoted text, not
  by the number alone, because earlier tasks edit some of these files:
  - F4 and F11: `modules/home/helix/languages.toml` (Markdown `rulers`, the
    comment above yaml-language-server's config).
  - F8: `pkgs/lib/release-binary.nix` (`meta.mainProgram` default) and
    `pkgs/mbx.nix` (drops `mainProgram`).
  - F9: `flake.nix` (`releaseBinaryArchive` and the `release-binary-archive`
    checks), `.github/workflows/ci.yml` (a job `release-binary-archive` after
    the `merge-json` job), `mise.toml` (its task), `docs/architecture.md` (the
    checks sentence), `GLOSSARY.md` (**Flake check**) and, if it named its check
    there, `CLAUDE.md`.
  - F10: `modules/home/claude-code/nix-lsp.json` (nixd's `settings`); F14 tests
    languageIds and commits nothing.
  - F11: `modules/home/java.nix` (the comment at line 17).
  - C1.1 to C1.3: `modules/home/rust.nix` and `modules/home/claude-code.nix` (an
    `extraVariables` line after each setter), `modules/darwin/launchd-env.nix`.
  - C1.4 waits for Patrick's work-layer change and may land before or after this
    section. If it has landed, `modules/home/helix.nix` carries
    `my.launchd.shellOnlyVariables = [ "EDITOR" ];` after
    `home.sessionVariables.EDITOR`; C23.3 says how to treat that line either
    way.
- Run every command with the Bash sandbox off, from the repository root, so
  `nix` works and `$TMPDIR` is the same directory in every call. Shell variables
  do not carry over between calls, so each command block below defines what it
  uses. Scratch files go in `"$TMPDIR/c23"`. Create it once with
  `mkdir -p "$TMPDIR/c23"`.
- Fix formatting with the tools the checks use, `<files>` standing for the files
  to format:

  ```sh
  # Nix
  "$(.github/scripts/nix-tool.sh nixfmt)" <files>
  # JSON and YAML
  "$(.github/scripts/nix-tool.sh oxfmt)" -c modules/home/oxc/oxfmtrc.json \
    <files>
  # TOML
  "$(.github/scripts/nix-tool.sh tombi)" format <files>
  # Markdown
  "$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
    --prose-wrap=always --print-width=80 <files>
  ```

- A new file is invisible to every flake evaluation and to every lint script
  (they read `git ls-files`) until it is `git add`ed.
- Every commit body below is one paragraph wrapped at 72 columns, and every
  subject is Conventional and at most 50 characters. Check a body you change
  with `awk 'length > 72'` before committing.

### Task C23.1: substituteValue

**Files:**

- Modify: `lib/default.nix:1-40` (move the two assertions into a shared helper
  and add `substituteValue`)
- Create: `lib/tests.nix`
- Modify: `flake.nix:61-65` (add `libTests` after F9's `releaseBinaryArchive`,
  which follows `mergeJsonTests`), `flake.nix:171-195` (add `lib` to both
  `checks.<system>` sets)
- Modify: `.github/workflows/ci.yml` (a job `lib` after F9's
  `release-binary-archive` job, before `darwin:`)
- Modify: `mise.toml:28-30` (a `check:lib` task after F9's
  `check:release-binary-archive`, which follows `check:merge-json`)
- Modify: `docs/architecture.md:8-12` (the checks list),
  `docs/architecture.md:51-55` (the `lib/default.nix` bullet)
- Modify: `GLOSSARY.md:169-171` (**Flake check**)
- Modify: `CLAUDE.md:7-9` (what "the tests" are), `CLAUDE.md:42-44` (the
  commands)

**Interfaces:**

- Consumes: `lib.runTests` and `lib.debug.throwTestFailures` from the pinned
  nixpkgs (`inputs.nixpkgs.lib`, 26.11). `throwTestFailures { failures; }`
  returns null for no failures and otherwise throws `<n> tests failed:` with the
  failing names.
- Produces:
  - `(import ./lib lib).substituteValue value replacements`. `value` is a parsed
    value (attribute sets, lists, strings, numbers, booleans, null).
    `replacements` is `{ <name> = string | null; }`. The result is `value` with
    `@name@` replaced in every string and every attribute name. Store-path
    context is kept.
  - Failure messages, one per safeguard:

    ```text
    substituteValue: the value has no placeholder for @a@, @b@
    substituteValue: the value leaves @a@, @b@ unfilled; pass null to keep one
    ```

  - `substituteFile`'s messages stay byte-for-byte as they are now.
  - `lib/tests.nix :: { lib } -> { test<Name> = { expr; expected; }; }`.
  - `checks.aarch64-darwin.lib` and `checks.x86_64-linux.lib`, built by
    `.github/scripts/nix-check.sh lib`, by the CI job `lib` ("Test lib
    helpers"), shaped like F9's `release-binary-archive` job, and by
    `mise run check:lib`.
  - GLOSSARY.md's **Flake check** lists `lib/tests.nix`'s cases after
    release-binary's archive-kind check.
  - CLAUDE.md names `lib/tests.nix`'s cases among the tests and
    `.github/scripts/nix-check.sh lib` among its commands.
  - This task does not make it a special argument. C23.4 does that.

- [ ] **Step 1: Record the baselines the substituteFile refactor must not move**

```sh
mkdir -p "$TMPDIR/c23"
.github/scripts/nix-eval.sh \
  '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath' \
  > "$TMPDIR/c23/1-darwin.before"
.github/scripts/nix-eval.sh \
  '.#homeConfigurations."patrick@linux".activationPackage.drvPath' \
  > "$TMPDIR/c23/1-linux.before"
```

Expected: each file holds one `/nix/store/…-darwin-system-….drv` or
`/nix/store/…-home-manager-generation.drv` path.

- [ ] **Step 2: Write the failing test**

Create `lib/tests.nix`:

```nix
{ lib }:
let
  inherit (import ./. lib) substituteValue;

  # tryEval stops at weak head normal form, so the value is forced
  # whole first, or an assertion deeper down would go unseen.
  fails = value: !(builtins.tryEval (builtins.deepSeq value value)).success;
in
{
  testSubstitutesStringsAndNames = {
    expr = substituteValue {
      "@kind@".expr = "@options@";
      list = [ "x" 1 true null ];
    } {
      kind = "nix-darwin";
      options = "(f).options";
    };
    expected = {
      nix-darwin.expr = "(f).options";
      list = [ "x" 1 true null ];
    };
  };

  testNullKeepsPlaceholder = {
    expr = substituteValue { a = "@x@ @y@"; } {
      x = "1";
      y = null;
    };
    expected.a = "1 @y@";
  };

  testKeepsContext = {
    expr =
      let
        probe = builtins.toFile "probe" "";
      in
      builtins.hasContext (substituteValue { a = "@p@/bin"; } { p = probe; }).a;
    expected = true;
  };

  testUnusedReplacementFails = {
    expr = fails (substituteValue { a = "@x@"; } { x = "1"; y = "2"; });
    expected = true;
  };

  testUnfilledPlaceholderInNameFails = {
    expr = fails (substituteValue { "@z@" = 1; } { });
    expected = true;
  };
}
```

`kind` appears only in an attribute name. `testSubstitutesStringsAndNames`
therefore also proves that names count as uses.
`testUnfilledPlaceholderInNameFails` proves that names are scanned for
placeholders.

In `flake.nix`'s `let`, add this after F9's `releaseBinaryArchive` binding
(which follows `mergeJsonTests`, line 65 at a07c2f4):

```nix
      # lib/tests.nix's cases, run while evaluating: a failing case
      # throws with its name, and a passing run builds an empty file.
      libTests =
        system:
        let
          inherit (inputs.nixpkgs) lib;
        in
        builtins.seq (lib.debug.throwTestFailures {
          failures = lib.runTests (import ./lib/tests.nix { inherit lib; });
        }) (inputs.nixpkgs.legacyPackages.${system}.writeText "lib-tests" "");
```

In `checks.aarch64-darwin`, add `lib = libTests "aarch64-darwin";` after F9's
`release-binary-archive = releaseBinaryArchive "aarch64-darwin";` (which follows
`merge-json = mergeJsonTests "aarch64-darwin";`). Add
`checks.x86_64-linux.lib = libTests "x86_64-linux";` after F9's
`checks.x86_64-linux.release-binary-archive`. The comment above
`checks.x86_64-linux.merge-json` covers all three. Leave whatever else F added
to those sets in place.

Then run `git add lib/tests.nix`.

- [ ] **Step 3: Run it and see it fail**

```sh
.github/scripts/nix-check.sh lib
```

Expected: exit 1, and stderr contains
`error: attribute 'substituteValue' missing`.

- [ ] **Step 4: Implement**

Rewrite `lib/default.nix` as
`lib: let … in { substituteFile = …; substituteValue = …; }`:

- `checkPlaceholders = what: text: replacements: …`
  - This is the body of today's lines 20-36, moved here. It returns the names
    whose replacement is not null.
  - The messages become `"${what} has no placeholder for " + …` and
    `"${what} leaves " + … + " unfilled; pass null to keep one"`.
  - Comment above it:

    ```nix
    # The two safeguards, over `text`, with `what` naming the source in
    # each message. Returns the names whose replacement is not null.
    ```

- `substituteFile = path: replacements:`
  - Calls
    `checkPlaceholders "substituteFile: ${toString path}" file replacements`.
  - Then does the same `builtins.replaceStrings` over the filled names as today.
  - Its comment (lines 3-15) stays as it is.
- `substituteValue = value: replacements:`
  - First collect every attribute name and every string in `value`, depth-first,
    and join them with `"\n"`. No placeholder can span a newline.
  - Pass the joined text to
    `checkPlaceholders "substituteValue: the value" … replacements`.
  - Force the returned names with `builtins.seq` before returning, so both
    assertions fire at weak head normal form, as in `substituteFile`.
  - Then recurse:
    - attribute sets through `lib.mapAttrs'`, renaming each name with the same
      `builtins.replaceStrings`;
    - lists through `map`;
    - strings through `builtins.replaceStrings`;
    - anything else returned unchanged.
  - Docblock above it:

    ```nix
    # substituteFile's `@name@` substitution into a parsed value, such as
    # `builtins.fromTOML` returns: every string and every attribute name,
    # with the same two safeguards. A store path keeps its string context,
    # so a file rendered from the result depends on it.
    ```

- [ ] **Step 5: Run it and see it pass**

```sh
.github/scripts/nix-check.sh lib
```

Expected: exit 0, with no `tests failed` in the output.

- [ ] **Step 6: Check both assertion messages**

```sh
msg='substituteValue: the value has no placeholder for @y@'
nix eval --impure --expr '
  let
    lib = (builtins.getFlake (toString ./.)).inputs.nixpkgs.lib;
  in
  (import ./lib lib).substituteValue { a = "@x@"; } { x = "1"; y = "2"; }
' 2>&1 | grep -F "$msg"
msg='substituteValue: the value leaves @z@ unfilled; pass null to keep one'
nix eval --impure --expr '
  let
    lib = (builtins.getFlake (toString ./.)).inputs.nixpkgs.lib;
  in
  (import ./lib lib).substituteValue { a = "@x@ @z@"; } { x = "1"; }
' 2>&1 | grep -F "$msg"
```

Expected: each `grep` prints one matching line and exits 0.

- [ ] **Step 7: Prove substituteFile's callers are unchanged**

```sh
.github/scripts/nix-eval.sh \
  '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath' \
  > "$TMPDIR/c23/1-darwin.after"
.github/scripts/nix-eval.sh \
  '.#homeConfigurations."patrick@linux".activationPackage.drvPath' \
  > "$TMPDIR/c23/1-linux.after"
cmp "$TMPDIR/c23/1-darwin.before" "$TMPDIR/c23/1-darwin.after" &&
  cmp "$TMPDIR/c23/1-linux.before" "$TMPDIR/c23/1-linux.after"
```

Expected: no output and exit 0.

- [ ] **Step 8: Run it in CI and through mise**

In `.github/workflows/ci.yml`, after F9's `release-binary-archive` job (it ends
with `run: .github/scripts/nix-check.sh release-binary-archive`) and before
`darwin:`, add a blank line and this job, indented two spaces as a key under
`jobs:` like the others:

```yaml
lib:
  name: Test lib helpers
  runs-on: ubuntu-latest

  steps:
    - name: Checkout
      uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      with:
        persist-credentials: false

    - name: Set up Nix
      uses: DeterminateSystems/nix-installer-action@<pin> # v23

    - name: Test lib helpers
      run: .github/scripts/nix-check.sh lib
```

where `<pin>` is `3138316df39ed29be04236d7ffc686fa525866aa`, the commit the
`merge-json` job's Set up Nix step pins. Both `uses:` lines are copied from that
job unchanged.

In `mise.toml`, after F9's `[tasks."check:release-binary-archive"]` (which
follows `check:merge-json`), add a blank line and:

```toml
[tasks."check:lib"]
description = "Run lib/tests.nix's cases"
run = ".github/scripts/nix-check.sh lib"
```

```sh
"$(.github/scripts/nix-tool.sh oxfmt)" -c modules/home/oxc/oxfmtrc.json \
  .github/workflows/ci.yml
"$(.github/scripts/nix-tool.sh tombi)" format mise.toml
ci=.github/workflows/ci.yml
diff \
  <(sed -n '/^  merge-json:$/,/nix-check\.sh merge-json$/p' "$ci" |
    sed 's/merge-json/lib/; s/Test lib$/Test lib helpers/') \
  <(sed -n '/^  lib:$/,/nix-check\.sh lib$/p' "$ci")
mise tasks ls | grep -F 'check:lib'
mise run check:lib
git grep -n 'nix-check.sh lib' -- .github/workflows/ci.yml mise.toml
```

Expected: `diff` prints nothing, because the `lib` job is the `merge-json` job,
indentation included, with only its key, its names and its `run:` changed.
`mise tasks ls` prints the `check:lib` line with its description,
`mise run check:lib` exits 0, and `git grep` prints one line in each file.

- [ ] **Step 9: Document it**

In `docs/architecture.md:51-55`, after "…asserting every replacement and every
placeholder is matched.", insert: "`substituteValue value { name = value; }`
does the same into every string and attribute name of a parsed value, keeping
store-path context; `lib/tests.nix` holds its cases, built as
`checks.<system>.lib`."

In the checks list (`docs/architecture.md:10-12`), F9 has already written "plus
merge-json's fixture tests and release-binary's archive-kind check, which
`checks.x86_64-linux` carries for CI". Replace that with "plus merge-json's
fixture tests, release-binary's archive-kind check and `lib/tests.nix` as `lib`,
which `checks.x86_64-linux` carries for CI". CI builds all three after Step 8,
each in a job of its own. If F9's sentence reads differently, add
"`lib/tests.nix` as `lib`" to its list in the same way and keep the rest.

In `GLOSSARY.md` **Flake check**, change "the system build, the Linux eval,
merge-json's fixture tests and release-binary's archive-kind check." (F9's
wording) to "the system build, the Linux eval, merge-json's fixture tests,
release-binary's archive-kind check and `lib/tests.nix`'s cases."

Load the `writing-for-agents` skill before editing `CLAUDE.md`, as the skill
index routes every agent document there. In `CLAUDE.md:7-9`, the sentence on
what "the tests" are names merge-json's fixtures, and F9's archive-kind check if
F9 added it there. Add `lib/tests.nix`'s cases as the last flake check it names.
If F9 left the sentence alone, it ends: "that both configurations evaluate,
merge-json's fixtures and `lib/tests.nix`'s cases pass, and the per-language
checks pass." In the command block, after
`.github/scripts/nix-check.sh merge-json` (or after F9's
`nix-check.sh release-binary-archive` line, if F9 added one), add a blank line
and:

```sh
# lib/tests.nix's cases alone, for this machine's system; CI builds
# the x86_64-linux one.
.github/scripts/nix-check.sh lib
```

Then format all three files:

```sh
"$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
  --prose-wrap=always --print-width=80 \
  docs/architecture.md GLOSSARY.md CLAUDE.md
git grep -n -e 'lib/tests.nix' -e 'nix-check.sh lib' -- \
  docs/architecture.md GLOSSARY.md CLAUDE.md
```

Expected: `git grep` prints two lines from `docs/architecture.md`, one from
`GLOSSARY.md` and three from `CLAUDE.md` (the sentence, the comment and the
command).

- [ ] **Step 10: Format, evaluate, lint**

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" lib/default.nix lib/tests.nix flake.nix
mise run test
mise run lint
```

Expected: both evaluations print a `.drv` path, and every lint task passes,
`lint:yaml` on `ci.yml`, `lint:toml` on `mise.toml` and `lint:markdown` on the
three Markdown files included.

- [ ] **Step 11: Commit**

```sh
git add lib/default.nix lib/tests.nix flake.nix .github/workflows/ci.yml \
  mise.toml docs/architecture.md GLOSSARY.md CLAUDE.md
git -c commit.gpgsign=false commit \
  -m "feat(lib): add substituteValue for parsed values" \
  -m "The LSP plugin is to take its payloads from Helix's languages.toml,
which builtins.fromTOML parses only before its placeholders are
filled. substituteValue fills them afterwards, in every string and
attribute name, with substituteFile's two safeguards and without
dropping store-path context. lib/tests.nix pins that as a flake check,
which CI builds and mise runs as check:lib."
```

### Task C23.2: release-binary passthru and mbx.cargoShim

**Files:**

- Modify: `pkgs/lib/release-binary.nix:18-30` (argument set),
  `pkgs/lib/release-binary.nix:91` (`passthru`)
- Modify: `pkgs/mbx.nix:17-51`
- Modify: `modules/home/rust.nix:19`
- Modify: `modules/home/helix.nix:71`
- Modify: `modules/home/claude-code.nix:192`
- Modify: `modules/home/darwin/zed.nix:882` (`mbx` is bound at 1046)
- Modify: `modules/darwin/launchd-env.nix:54` (the `PATH` line; `mbx` is bound
  at 51)

**Interfaces:**

- Consumes: F9's `checks.<system>.release-binary-archive`, which reads
  `passthru.archive`.
- Produces:
  - release-binary's second-call argument `passthru ? { }`. The result's
    `passthru = { inherit archive; } // passthru`, so a caller's key wins over
    `archive`. `pkg.archive` is still exposed for F9's check and for C6.1's
    `wheel` kind.
  - With `mbx = pkgs.callPackage ../../pkgs/mbx.nix { }`,
    `mbx.cargoShim == "${mbx}/libexec/mbx/cargo"`, a string with mbx's context.
    The shim's directory is `dirOf mbx.cargoShim`.
  - After this task, no file outside `pkgs/mbx.nix` and
    `pkgs/mbx/post-install.sh` spells `libexec/mbx`.
  - launchd-env.nix's `PATH` stays a literal store path list, so C1.3's
    literal-value assertion still holds.

- [ ] **Step 1: Record the baselines; no derivation may change**

```sh
mkdir -p "$TMPDIR/c23"
.github/scripts/nix-eval.sh \
  '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath' \
  > "$TMPDIR/c23/2-darwin.before"
.github/scripts/nix-eval.sh \
  '.#homeConfigurations."patrick@linux".activationPackage.drvPath' \
  > "$TMPDIR/c23/2-linux.before"
```

- [ ] **Step 2: Write the failing test**

```sh
nix eval --raw --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    mbx = pkgs.callPackage ./pkgs/mbx.nix { };
  in
  assert mbx.cargoShim == "${mbx}/libexec/mbx/cargo";
  mbx.archive
'
```

- [ ] **Step 3: Run it and see it fail**

Expected: exit 1, with `error: attribute 'cargoShim' missing`.

- [ ] **Step 4: Give release-binary a passthru argument**

In `pkgs/lib/release-binary.nix`, between
`postInstall ? null, # a file, read into the postInstall hook` and `meta,`, add:

```nix
  # merged over the builder's own, which holds `archive`
  passthru ? { },
```

Change `passthru = { inherit archive; };` (line 91) to
`passthru = { inherit archive; } // passthru;`. The attribute set is not `rec`,
so the right-hand `passthru` is the argument.

- [ ] **Step 5: Publish the shim from mbx**

In `pkgs/mbx.nix`, bind the call to a name and return it:

```nix
let
  # @VERSION https://github.com/jdx/mr-boxington/releases
  version = "1.30.0";

  # A name of its own, so cargoShim can point into the package's
  # output; the derivation never reads cargoShim, so nothing recurses.
  mbx = callPackage ./lib/release-binary.nix { } {
    # pname, version, assets, nativeBuildInputs, postInstall: unchanged
    passthru.cargoShim = "${mbx}/libexec/mbx/cargo";
    # meta: unchanged (F8 has already dropped its mainProgram)
  };
in
mbx
```

- [ ] **Step 6: Run it and see it pass**

Run the Step 2 command again. Expected output: `tar`. Then run
`.github/scripts/nix-check.sh release-binary-archive` (F9's check). It should
exit 0, which shows that `archive` survives the merge.

- [ ] **Step 7: Point every consumer at cargoShim**

- `modules/home/rust.nix:19`: `home.sessionPath = [ "${mbx}/libexec/mbx" ];`
  becomes `home.sessionPath = [ (dirOf mbx.cargoShim) ];`
- `modules/home/helix.nix:71` and `modules/home/claude-code.nix:192`:
  `mbxCargo = "${pkgs.callPackage ../../pkgs/mbx.nix { }}/libexec/mbx/cargo";`
  becomes `mbxCargo = (pkgs.callPackage ../../pkgs/mbx.nix { }).cargoShim;`
- `modules/home/darwin/zed.nix:882`: `"${mbx}/libexec/mbx/cargo"` becomes
  `mbx.cargoShim`
- `modules/darwin/launchd-env.nix:54`: in
  `PATH = "${mbx}/libexec/mbx:/etc/profiles/per-user/${user}/bin:…";`, replace
  the leading `${mbx}/libexec/mbx` with `${dirOf mbx.cargoShim}` and leave the
  rest of the string as it is.

```sh
git grep -n 'libexec/mbx' -- '*.nix' '*.sh'
```

Expected: exactly four lines.

- `pkgs/mbx.nix:4:` (the header comment)
- the `pkgs/mbx.nix` line `passthru.cargoShim = "${mbx}/libexec/mbx/cargo";`
- `pkgs/mbx/post-install.sh:5:`
- `pkgs/mbx/post-install.sh:7:`

- [ ] **Step 8: Prove nothing evaluated changed**

```sh
.github/scripts/nix-eval.sh \
  '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath' \
  > "$TMPDIR/c23/2-darwin.after"
.github/scripts/nix-eval.sh \
  '.#homeConfigurations."patrick@linux".activationPackage.drvPath' \
  > "$TMPDIR/c23/2-linux.after"
cmp "$TMPDIR/c23/2-darwin.before" "$TMPDIR/c23/2-darwin.after" &&
  cmp "$TMPDIR/c23/2-linux.before" "$TMPDIR/c23/2-linux.after"
```

Expected: no output and exit 0. The shell `PATH`, the GUI `PATH`, Zed's and
Helix's rust-analyzer command and the plugin's are byte-identical.

- [ ] **Step 9: Format, evaluate, lint**

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" pkgs/lib/release-binary.nix \
  pkgs/mbx.nix modules/home/rust.nix modules/home/helix.nix \
  modules/home/claude-code.nix modules/home/darwin/zed.nix \
  modules/darwin/launchd-env.nix
mise run test
mise run lint
```

- [ ] **Step 10: Commit**

```sh
git add pkgs/lib/release-binary.nix pkgs/mbx.nix modules/home/rust.nix \
  modules/home/helix.nix modules/home/claude-code.nix \
  modules/home/darwin/zed.nix modules/darwin/launchd-env.nix
git -c commit.gpgsign=false commit \
  -m "refactor(mbx): expose the Cargo shim as cargoShim" \
  -m "Five modules spelled libexec/mbx after the mbx store path, so moving
the shim inside the package would have broken each of them in
silence. release-binary now takes a passthru argument beside archive,
mbx publishes the shim's path through it, and every consumer reads
that; the evaluated configurations are unchanged."
```

### Task C23.3: my.nixd.settings

**Files:**

- Modify: `modules/home/helix.nix:1-85`
  - add `options.my.nixd.settings`
  - move the module's attributes under `config = { … };`: everything from
    `home.packages = [ pkgs.helix ];` through the
    `// lib.optionalAttrs (!isDarwin) { … }` block (lines 35-84 at a07c2f4),
    plus C1.4's `my.launchd.shellOnlyVariables` line if C1.4 has landed
  - lines 14-28: the nixd let bindings
  - lines 57-72: the `replaceVars` call
- Modify: `modules/home/helix/languages.toml:554-557` (nixd's nixpkgs table and
  its comment)
- Modify: `modules/home/darwin/zed.nix:834-845` (`lsp.nixd.settings`)

**Interfaces:**

- Consumes: C1.4's `my.launchd.shellOnlyVariables = [ "EDITOR" ];` in
  `helix.nix`, only if C1.4 has landed.
- Produces:
  - Read-only home-manager option `config.my.nixd.settings`, declared in
    `modules/home/helix.nix`, with type `(pkgs.formats.json { }).type`. Its
    value holds the plain strings `nixpkgs.expr`,
    `options.<nix-darwin|nixos>.expr` and `options.home-manager.expr` for this
    platform: exactly the attribute sets Step 2's two commands compare it with,
    the darwin one and the Linux one.
  - Helix's template placeholder `@homeDirectory@` becomes `@nixpkgsExpr@`, a
    whole TOML string. The template's 11 placeholders become: nixpkgsExpr,
    systemKind, systemOptions, homeManagerOptions, jdtlsSettings, astroTsdk,
    oxfmtConfig, clangFormat, swiftFormat, terraform, mbxCargo.
  - After this task every attribute `helix.nix` sets sits under `config`. If
    C1.4 lands after this task, its
    `my.launchd.shellOnlyVariables = [ "EDITOR" ];` goes inside `config`, on the
    line after `home.sessionVariables.EDITOR`.

- [ ] **Step 1: Record the baselines**

```sh
mkdir -p "$TMPDIR/c23"
D='.#darwinConfigurations.Patricks-MacBook-Pro'
H="$D.config.home-manager.users.patrick"
nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work \
  "$H"'.xdg.configFile."helix/languages.toml".source' \
  > "$TMPDIR/c23/3-helix.before"
nix eval --raw --override-input work path:./stubs/work \
  "$H.home.activation.zedSettings.data" |
  grep -o '/nix/store/[a-z0-9]*-zed-settings\.json' \
  > "$TMPDIR/c23/3-zed.before"
```

Expected: one store path in each file. The build needs terraform, which is
unfree and not in cache.nixos.org, in the store. It is there on this Mac.

- [ ] **Step 2: Write the failing test**

The darwin value:

```sh
D='.#darwinConfigurations.Patricks-MacBook-Pro'
nix eval --override-input work path:./stubs/work \
  "$D.config.home-manager.users.patrick.my.nixd.settings" --apply '
    s:
    let
      flake =
        "(builtins.getFlake \"/Users/patrick/Developer/github.com/"
        + "pgodschalk/nix-config\")";
      host = "${flake}.darwinConfigurations.Patricks-MacBook-Pro";
    in
    s == {
      nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
      options.nix-darwin.expr = "${host}.options";
      options.home-manager.expr =
        "${host}.options.home-manager.users.type.getSubOptions [ ]";
    }
  '
```

The Linux value:

```sh
nix eval --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux".config.my.nixd.settings' --apply '
    s:
    let
      flake =
        "(builtins.getFlake \"/home/patrick/Developer/github.com/"
        + "pgodschalk/nix-config\")";
    in
    s == {
      nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
      options.nixos.expr = "{ }";
      options.home-manager.expr =
        "${flake}.homeConfigurations.\"patrick@linux\".options";
    }
  '
```

- [ ] **Step 3: Run it and see it fail**

Expected: both exit 1, with `error: attribute 'nixd' missing`.

- [ ] **Step 4: Declare the option in helix.nix**

Rework the let bindings at lines 14-28:

- Replace the comment at lines 14-16 with:

  ```nix
    # `builtins.getFlake` will not take /etc/nix-darwin, which is a
    # symlink, so the real checkout is named.
  ```

- Keep line 17, the `flake = ''(builtins.getFlake "…")'';` binding, as it is.
- Keep line 18, the `tomlString` binding, as it is, and put this comment above
  it:

  ```nix
    # The inside of a TOML basic string: JSON escapes it the same way,
    # and the template supplies the quotes.
  ```

- Replace lines 19-28, `systemKind` through the end of `homeManagerOptions`,
  with:

  ```nix
    host = "${flake}.darwinConfigurations.Patricks-MacBook-Pro";
    linuxHome = ''${flake}.homeConfigurations."${config.home.username}@linux"'';
    systemKind = if isDarwin then "nix-darwin" else "nixos";
    nixd = config.my.nixd.settings;
  ```

Add this option:

```nix
  options.my.nixd.settings = lib.mkOption {
    inherit (pkgs.formats.json { }) type;
    readOnly = true;
    default = {
      nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
      options = {
        # Linux has a standalone home configuration and no system
        # one, so its system entry is empty.
        ${systemKind}.expr = if isDarwin then "${host}.options" else "{ }";
        home-manager.expr =
          if isDarwin then
            "${host}.options.home-manager.users.type.getSubOptions [ ]"
          else
            "${linuxHome}.options";
      };
    };
  };
```

Give it, as its last attribute, a one-line `description` string, as the
repository's other options have: nixd's settings for this machine: the
expressions it evaluates for nixpkgs and for the system and home-manager
options, as plain strings. Helix, Zed and the LSP plugin send them.

Then move the module's attributes, unchanged, under `config = { … };`:
everything from `home.packages = [ pkgs.helix ];` through the closing brace of
the `// lib.optionalAttrs (!isDarwin) { … }` block. If C1.4 has landed, that
range holds its `my.launchd.shellOnlyVariables = [ "EDITOR" ];` line after
`home.sessionVariables.EDITOR`, and the line moves with the rest. Left at the
top level beside `options`, it would fail evaluation as an unsupported
attribute.

In the `replaceVars` call:

- drop `homeDirectory = config.home.homeDirectory;`;
- keep `inherit systemKind jdtlsSettings astroTsdk;`;
- set `nixpkgsExpr = tomlString nixd.nixpkgs.expr;`;
- set `systemOptions = tomlString nixd.options.${systemKind}.expr;`;
- set `homeManagerOptions = tomlString nixd.options.home-manager.expr;`.

Leave the other replacements as they are.

- [ ] **Step 5: Fill nixpkgs from the option in the template**

In `modules/home/helix/languages.toml`, delete the two comment lines 554-555,
which now sit on `flake` in `helix.nix`. Change line 557 to
`expr = "@nixpkgsExpr@"`. The table header
`[language-server.nixd.config.nixd.nixpkgs]` stays.

`git grep -n '@homeDirectory@'` should then print nothing.

- [ ] **Step 6: Let Zed read it**

Replace `modules/home/darwin/zed.nix:834-845` (the
`lsp.nixd.settings = let flake = …; host = …; in { … };` block) with
`lsp.nixd.settings = config.my.nixd.settings;`.

- [ ] **Step 7: Run the test and see it pass**

Run both Step 2 commands again. Expected: each prints `true`. If one prints
`false`, run it with `--json` in place of `--apply` and its expression, piped
through `jq .`, to see the value.

If C1.4 has landed (`git grep -n shellOnlyVariables -- modules/home/helix.nix`
prints a line), also run:

```sh
D='.#darwinConfigurations.Patricks-MacBook-Pro'
nix eval --json --override-input work path:./stubs/work \
  "$D.config.home-manager.users.patrick.my.launchd.shellOnlyVariables" \
  --apply 'builtins.elem "EDITOR"'
```

Expected: `true`. If C1.4 has not landed, `git grep` prints nothing; skip this
check.

- [ ] **Step 8: Prove Helix's file and Zed's settings are unchanged**

```sh
D='.#darwinConfigurations.Patricks-MacBook-Pro'
H="$D.config.home-manager.users.patrick"
nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work \
  "$H"'.xdg.configFile."helix/languages.toml".source' \
  > "$TMPDIR/c23/3-helix.after"
before=$(cat "$TMPDIR/c23/3-helix.before")
after=$(cat "$TMPDIR/c23/3-helix.after")
nix eval --impure --expr "
  let
    read = f: builtins.fromTOML
      (builtins.unsafeDiscardStringContext (builtins.readFile f));
  in
  read $before == read $after
"
nix eval --raw --override-input work path:./stubs/work \
  "$H.home.activation.zedSettings.data" |
  grep -o '/nix/store/[a-z0-9]*-zed-settings\.json' \
  > "$TMPDIR/c23/3-zed.after"
cmp "$TMPDIR/c23/3-zed.before" "$TMPDIR/c23/3-zed.after"
```

Expected: `true`, then no output from `cmp`. The comparison is on the parsed
TOML because the template's moved comment changes the file's bytes.

```sh
git grep -n 'pgodschalk/nix-config' -- modules
```

Expected: `modules/home/helix.nix`'s `flake` line, plus
`modules/home/claude-code/nix-lsp.json`'s six nixd lines (F10's wrap), which
C23.4 removes.

- [ ] **Step 9: Format, evaluate, lint**

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" modules/home/helix.nix \
  modules/home/darwin/zed.nix
mise run test
mise run lint
```

- [ ] **Step 10: Commit**

```sh
git add modules/home/helix.nix modules/home/helix/languages.toml \
  modules/home/darwin/zed.nix
git -c commit.gpgsign=false commit \
  -m "refactor(helix): declare my.nixd.settings once" \
  -m "Helix and Zed each spelled the checkout path and host nixd reads its
options from, and Helix's template spelled the path a third time.
helix.nix now declares the settings once as a read-only option; Helix
escapes it into its template, Zed sends it as it is, and the LSP
plugin can fill the same template from it."
```

### Task C23.4: LSP plugin payloads from Helix

**Files:**

- Modify: `modules/home/claude-code.nix`
  - lines 1-7: add `substituteValue` to the arguments
  - lines 8-137: new let bindings
  - lines 183-193: render with `json.generate`; drops `replaceVars` and
    `javaHome`
- Modify: `modules/home/claude-code/nix-lsp.json:1-557` (every
  `initializationOptions` and `settings` removed)
- Modify: `flake.nix`
  - lines 44-46: comment, and `inherit … substituteFile substituteValue`
  - line 139: Linux `extraSpecialArgs`
  - line 159: darwin `specialArgs`
- Modify: `hosts/Patricks-MacBook-Pro/default.nix:4` (argument),
  `hosts/Patricks-MacBook-Pro/default.nix:115` (home-manager `extraSpecialArgs`)
- Modify: `modules/home/java.nix:37` (`my.java.jdk`'s description)
- Modify: `docs/architecture.md:43-45` (the LSP plugin sentence),
  `docs/architecture.md:56` (the special arguments)
- Create: `docs/adr/0014-lsp-plugin-payloads-from-helix.md`

**Interfaces:**

- Consumes:
  - `substituteValue` (C23.1)
  - `mbx.cargoShim` (C23.2)
  - `config.my.nixd.settings` and the `@nixpkgsExpr@` placeholder (C23.3)
  - F10's wrapped nixd `settings` in `nix-lsp.json`; this task keeps
    `extensionToLanguage` verbatim
  - the `[language-server.X.config]` tables in
    `modules/home/helix/languages.toml`:

    | Server               | Lines   |
    | -------------------- | ------- |
    | astro-ls             | 454-455 |
    | clangd               | 489-490 |
    | gopls                | 524-534 |
    | jdtls                | 539-543 |
    | nixd                 | 551-563 |
    | rust-analyzer        | 618-642 |
    | terraform-ls         | 673-674 |
    | yaml-language-server | 702-709 |

- Produces:
  - `substituteValue` as a special argument of every nix-darwin and home-manager
    module, beside `substituteFile`.
  - `modules/home/claude-code/nix-lsp.json`: a bare map of server name to
    `{ command, args?, extensionToLanguage }` and nothing else.
  - In `claude-code.nix`'s let:
    - `helixPayloadServers`, the eight names;
    - `helixPayloads`, name to filled config;
    - `lspServers`, the rendered value. This is the commands map, with
      `{ initializationOptions = config; settings = config; }` merged into each
      of the eight.
  - The `xdg.configFile` entry `"claude-marketplace/plugins/nix-lsp/.lsp.json"`
    has `source = json.generate "nix-lsp.json" lspServers`.
  - Evaluation fails with
    `claude-code: helix/languages.toml gives no config to <names>` when one of
    the eight has no `config`.
  - `docs/adr/0014-lsp-plugin-payloads-from-helix.md`.
  - `docs/architecture.md`'s `pkgs/` bullet opens with the sentence Step 9
    writes; C6.2 and D1 edit the rest of that bullet and leave this sentence
    alone.
  - `my.java.jdk` is now read only by Zed.

- [ ] **Step 1: Write the payload test**

Create the scratch file `"$TMPDIR/c23/lsp-payloads.nix"`. It is not committed.
It compares a built `.lsp.json` with a built Helix `languages.toml`:

```nix
{ lsp, helix }:
let
  read = f: builtins.unsafeDiscardStringContext (builtins.readFile f);
  servers = builtins.fromJSON (read lsp);
  configs = (builtins.fromTOML (read helix)).language-server;
  withPayload = builtins.filter (
    n: servers.${n} ? initializationOptions || servers.${n} ? settings
  ) (builtins.attrNames servers);
in
{
  inherit withPayload;
  mismatched = builtins.filter (
    n:
    servers.${n}.initializationOptions or null != configs.${n}.config or null
    || servers.${n}.settings or null != configs.${n}.config or null
  ) withPayload;
}
```

Run it with this command (the same command is reused in Step 8):

```sh
D='.#darwinConfigurations.Patricks-MacBook-Pro'
F="$D.config.home-manager.users.patrick.xdg.configFile"
lsp=$(nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work \
  "$F"'."claude-marketplace/plugins/nix-lsp/.lsp.json".source')
helix=$(nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work \
  "$F"'."helix/languages.toml".source')
nix eval --json --impure --expr "
  import \"$TMPDIR/c23/lsp-payloads.nix\" {
    lsp = \"$lsp\";
    helix = \"$helix\";
  }
" | jq .
```

The scratch file's path is a quoted string, not a path literal, because
`$TMPDIR` ends in `/` on macOS and a Nix path literal cannot hold `//`.

- [ ] **Step 2: Write the missing-config probe**

The probe edits the file with BSD sed by absolute path, because the `sed` on
`PATH` may be GNU's, which reads `-i ''` differently.

```sh
/usr/bin/sed -i '' \
  '/^\[language-server\.clangd\.config\]$/,/^fallbackFlags = \["-Wall"\]$/d' \
  modules/home/helix/languages.toml
mise run eval:darwin 2>&1 |
  grep -F 'claude-code: helix/languages.toml gives no config to clangd'
git checkout -- modules/home/helix/languages.toml
```

- [ ] **Step 3: Run both and see them fail**

The Step 1 command prints exactly:

```json
{
  "mismatched": [
    "astro-ls",
    "clangd",
    "gopls",
    "jdtls",
    "rust-analyzer",
    "terraform-ls",
    "typescript-language-server",
    "vscode-css-language-server",
    "vscode-html-language-server",
    "vscode-json-language-server"
  ],
  "withPayload": [
    "astro-ls",
    "clangd",
    "gopls",
    "jdtls",
    "nixd",
    "rust-analyzer",
    "terraform-ls",
    "typescript-language-server",
    "vscode-css-language-server",
    "vscode-html-language-server",
    "vscode-json-language-server",
    "yaml-language-server"
  ]
}
```

nixd matches because of F10's wrap, and yaml-language-server already matches. If
F10 wrapped nixd differently, nixd also appears in `mismatched`.

The Step 2 probe: the evaluation succeeds, so `grep` prints nothing and exits 1.
That is the failing state, not a pass. Nothing reads Helix's file yet. Make sure
`git checkout` restored the file.

- [ ] **Step 4: Make substituteValue a special argument**

`flake.nix:46` becomes
`inherit (import ./lib inputs.nixpkgs.lib) substituteFile substituteValue;`. Its
comment (lines 44-45) becomes:

```nix
# `pkgs.replaceVars` without the derivation, so reading a
# substituted file or value stays a pure evaluation.
```

Add `substituteValue` after `substituteFile` in:

- `flake.nix:139` (`inherit inputs apps substituteFile;`)
- `flake.nix:159` (`specialArgs = { inherit inputs apps substituteFile; };`)
- the argument set of `hosts/Patricks-MacBook-Pro/default.nix` (after line 4)
- its `extraSpecialArgs` (line 115)

- [ ] **Step 5: Reduce nix-lsp.json to commands**

```sh
f=modules/home/claude-code/nix-lsp.json
jq 'map_values(del(.initializationOptions, .settings))' "$f" \
  > "$TMPDIR/c23/nix-lsp.json"
mv "$TMPDIR/c23/nix-lsp.json" "$f"
"$(.github/scripts/nix-tool.sh oxfmt)" -c modules/home/oxc/oxfmtrc.json "$f"
jq -c '[.[] | keys[]] | unique' "$f"
```

Expected last line: `["args","command","extensionToLanguage"]`.

This drops, as the Spec says:

- the payloads copied from Helix's built-in file: typescript-language-server's
  `hostInfo: "helix"` and inlay hints, and vscode-css/-html/-json's
  `provideFormatter` and `validate`;
- gopls's `codelenses.test`;
- jdtls's `java_home`.

The file can carry no `$schema` key, because Claude Code rejects unknown keys in
an `lspServers` entry.

- [ ] **Step 6: Derive the payloads in claude-code.nix**

Add `substituteValue` to the module's arguments. Add these to the let:

```nix
  # Helix's `config` for these servers is what the LSP plugin sends.
  # Claude Code passes initializationOptions to a server as they are
  # and answers workspace/configuration by walking `settings`, so each
  # table goes into both.
  helixPayloadServers = [
    "astro-ls"
    "clangd"
    "gopls"
    "jdtls"
    "nixd"
    "rust-analyzer"
    "terraform-ls"
    "yaml-language-server"
  ];
  helixServers =
    (builtins.fromTOML (builtins.readFile ./helix/languages.toml))
    .language-server;
  unconfigured = builtins.filter (
    name: !(helixServers.${name} or { } ? config)
  ) helixPayloadServers;

  nixd = config.my.nixd.settings;
  systemKind =
    if pkgs.stdenv.hostPlatform.isDarwin then "nix-darwin" else "nixos";

  # Filled as helix.nix fills the template, but without TOML's
  # escaping: these strings go into JSON.
  helixPayloads =
    assert lib.assertMsg (unconfigured == [ ]) (
      "claude-code: helix/languages.toml gives no config to "
      + lib.concatStringsSep ", " unconfigured
    );
    substituteValue
      (lib.genAttrs helixPayloadServers (name: helixServers.${name}.config))
      {
        astroTsdk = "${pkgs.callPackage ../../pkgs/astro-tsdk.nix { }}";
        jdtlsSettings = "${pkgs.callPackage ../../pkgs/jdtls-settings.nix { }}";
        nixpkgsExpr = nixd.nixpkgs.expr;
        inherit systemKind;
        systemOptions = nixd.options.${systemKind}.expr;
        homeManagerOptions = nixd.options.home-manager.expr;
        mbxCargo = (pkgs.callPackage ../../pkgs/mbx.nix { }).cargoShim;
        terraform = "${pkgs.terraform}";
      };
```

nixfmt in Step 10 sets the final line breaks.

`lspServers` is `lib.importJSON ./claude-code/nix-lsp.json`, with `lib.mapAttrs`
over `helixPayloads` merged on top. Each entry is
`commands.${name} // { initializationOptions = payload; settings = payload; }`,
so a name missing from `nix-lsp.json` fails with Nix's
`attribute '<name>' missing` rather than being added half-formed.

Substitute only the eight `config` tables, never the whole file. That way
exactly these eight replacements are matched, and Helix-only placeholders
(oxfmtConfig, clangFormat, swiftFormat) stay out of this module. If `systemKind`
drifts from `helix.nix`'s, evaluation fails at `nixd.options.${systemKind}`.

At lines 185-193, replace the call
`pkgs.replaceVars ./claude-code/nix-lsp.json { … }` with
`json.generate "nix-lsp.json" lspServers`, keeping the comment at 183-184.
`json` is the existing `pkgs.formats.json { }` binding at line 11.

- [ ] **Step 7: Correct my.java.jdk's description**

At `modules/home/java.nix:37`, change the end of `my.java.jdk`'s description
from "by every editor and agent." to "by Zed.", so it reads: The JDK installed
here and given to jdtls as its `java_home` by Zed.

- [ ] **Step 8: Run both tests and see them pass**

Run the Step 1 command again. Expected output, exactly:

```json
{
  "mismatched": [],
  "withPayload": [
    "astro-ls",
    "clangd",
    "gopls",
    "jdtls",
    "nixd",
    "rust-analyzer",
    "terraform-ls",
    "yaml-language-server"
  ]
}
```

Then check that the dropped payloads are gone and that no payload holds `${`.
Claude Code is reported to expand `${…}` in the `.lsp.json` of a plugin, which
Helix does not do, so a Helix `config` holding `${` could reach the server
altered:

```sh
D='.#darwinConfigurations.Patricks-MacBook-Pro'
F="$D.config.home-manager.users.patrick.xdg.configFile"
lsp=$(nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work \
  "$F"'."claude-marketplace/plugins/nix-lsp/.lsp.json".source')
jq -c '[
  .jdtls.settings.java_home,
  .gopls.initializationOptions.codelenses,
  [.. | strings | select(contains("${"))]
]' "$lsp"
```

Expected: `[null,null,[]]`. Before this task the first two held the JDK's store
path and gopls's `{"test":true}`.

Run the Step 2 probe again. Expected: `grep` prints one line containing
`claude-code: helix/languages.toml gives no config to clangd` and exits 0. Then
`git checkout` restores the file. Confirm with
`git status --short modules/home/helix/languages.toml`, which should print
nothing.

```sh
git grep -n 'pgodschalk/nix-config' -- modules
```

Expected: one line, `modules/home/helix.nix`'s `flake` binding.

- [ ] **Step 9: Record the decision**

Create `docs/adr/0014-lsp-plugin-payloads-from-helix.md`:

```markdown
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
```

In `docs/architecture.md:44-45`, replace "`modules/home/claude-code.nix` adds
the LSP plugin's `.lsp.json`, filled with the same store paths the editors get."
with "`modules/home/claude-code.nix` renders the LSP plugin's `.lsp.json` from
`claude-code/nix-lsp.json`'s commands and the `config` Helix's `languages.toml`
gives eight of the servers (ADR-0014)."

In `docs/architecture.md:56`, change "`inputs`, `apps` and `substituteFile`
reach every module" to "`inputs`, `apps`, `substituteFile` and `substituteValue`
reach every module".

```sh
git add docs/adr/0014-lsp-plugin-payloads-from-helix.md
"$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
  --prose-wrap=always --print-width=80 \
  docs/adr/0014-lsp-plugin-payloads-from-helix.md docs/architecture.md
```

- [ ] **Step 10: Format, evaluate, lint**

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" modules/home/claude-code.nix \
  modules/home/java.nix flake.nix hosts/Patricks-MacBook-Pro/default.nix
mise run check:lib
mise run test
mise run lint
```

Expected: the `lib` check still passes, both evaluations print a `.drv` path,
and every lint task passes, including `lint:json` on the reduced `nix-lsp.json`
and `lint:markdown` on the ADR.

- [ ] **Step 11: Commit**

```sh
git add modules/home/claude-code.nix modules/home/claude-code/nix-lsp.json \
  modules/home/java.nix flake.nix hosts/Patricks-MacBook-Pro/default.nix \
  docs/architecture.md docs/adr/0014-lsp-plugin-payloads-from-helix.md
git -c commit.gpgsign=false commit \
  -m "feat(claude-code): derive LSP payloads from Helix" \
  -m "nix-lsp.json restated eight servers' Helix config by hand and had
drifted: jdtls's java_home, gopls's test code lens, and payloads
copied from Helix's built-in file for four more servers. The plugin
now reads Helix's languages.toml, fills it with substituteValue and
sends each of the eight configs as both initializationOptions and
settings, failing evaluation when one has none; nix-lsp.json keeps
only commands. ADR-0014 records why there is no shared registry."
```

**After Patrick's switch:** in a Claude Code session, use the LSP tool on a
Rust, Go, C, Astro, Terraform, Java, Nix and YAML file each: rust-analyzer's
check diagnostics arrive through the mbx shim, gopls shows staticcheck findings,
clangd warns under `-Wall`, astro-ls, terraform-ls and jdtls start without a
configuration error, and the dropped payloads cost nothing he relies on (no
inlay hints in .gjs/.gts, no formatting from vscode-css/-html/-json, jdtls's JDK
as the project resolves it).

#### Notes for section C23

- `cargoShim` follows the Spec and upstream's own `MBX_CARGO_SHIM_*` variables
  (`pkgs/mbx/post-install.sh`), although GLOSSARY.md's **Wrapper** entry lists
  "shim" under _Avoid_. Patrick may want another name. The comments C23.2
  prescribes bring no new jargon, so `codebook.toml` needs no change.
- The payload comparison in C23.4 Steps 1 and 8 is a scratch file rather than a
  committed flake check, because a check would need import-from-derivation or a
  build-time TOML-to-JSON converter.
- That Claude Code expands `${…}` in a plugin's `.lsp.json` comes from the
  section's review and is unconfirmed against the Claude Code binary. C23.4 Step
  8's check for `${` is harmless either way.
- `CLAUDE.local.md` is not in the repository and names no per-check task (it
  points at `mise tasks ls`), so no task here edits it.

---

## Section C5: skills (Card 5)

Task IDs in this section are `C5.1` to `C5.6`, run in that order, after F, C1
and C23 and before C4 (C4.3's entry reads the `my.claudeCode.enabledPlugins`
C5.6 declares). Line ranges are as of `a07c2f4`; F, C1 and C23 shift lines in
the files they touch (C1 adds an `extraVariables` line to `claude-skills.nix`'s
`config`, C23 adds `let` bindings to `claude-code.nix` above the region C5.6
edits), so find each region by the binding it names.

F2 left three things in `claude-skills.nix` that this section replaces:

- the let binding `skillDirs`, every destination built from `extraSkillDirs` and
  `xcodeSkillsDir`, under a two-line comment about the home-relative
  `agentSkills`;
- `home.activation.snippetslabSkill`, still in `claude-skills.nix`, whose script
  `claude-skills/snippetslab-skill.sh` takes one placeholder, `@skillFiles@`: an
  array of `<dir>/snippetslab/SKILL.md` file paths built from `skillDirs`,
  generated into the first and copied to the rest;
- the let binding `generatedSkills` (`"committing-with-commitlint"`, plus
  `"snippetslab"` on macOS, under a two-line comment), appended to the list the
  duplicate check groups as `map (n: lib.nameValuePair n null) generatedSkills`.

C5.1 deletes `skillDirs`, C5.3 deletes `generatedSkills` and moves the
activation, and C5.4 deletes the commitlint literal C5.3 leaves. F12 has
repointed commitlint's `@VERSION`; C5.4 keeps it as F12 left it.

### Test harness for this section

Run every command in this section with the Bash sandbox off, the `jq`, `cmp` and
scratch-directory steps included: `nix` cannot run inside the sandbox, and a
sandboxed call sees a different `$TMPDIR` from an unsandboxed one, so a dump
written by one is missing in the other. The macOS command comes before the Linux
one, as in `mise run test`. The macOS user configuration is at
`config.home-manager.users.patrick` inside the darwin output; on the Linux
output the same paths are under `config` directly. Several blocks name the macOS
one through two shell variables, `darwin` and `hm`, assigned at the top of each
block that uses them.

Write the dump helper outside the repository, once. It lists every `home.file`
entry by target, with the flake's own store path replaced by `<self>` so an edit
to the repository does not change the output:

```sh
cat >"${TMPDIR%/}/c5-dump.nix" <<'EOF'
c:
let
  hm = c.config.home-manager.users.patrick or c.config;
  self = toString c._module.specialArgs.inputs.self.outPath;
in
builtins.sort (a: b: a.target < b.target) (
  map (v: {
    inherit (v) target recursive;
    source = builtins.replaceStrings [ self ] [ "<self>" ] (toString v.source);
  }) (builtins.attrValues hm.home.file)
)
EOF
```

To dump, with `<label>` such as `c51-before`. Outside the sandbox `$TMPDIR` ends
in `/`, and a Nix path literal holding `//` is a syntax error, hence
`${TMPDIR%/}` in `--apply`:

```sh
nix eval --impure --json --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' \
  --apply "import ${TMPDIR%/}/c5-dump.nix" \
  | jq -cS . >"$TMPDIR/darwin-<label>.json"
nix eval --impure --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux"' \
  --apply "import ${TMPDIR%/}/c5-dump.nix" \
  | jq -cS . >"$TMPDIR/linux-<label>.json"
```

At `a07c2f4` these hold 1352 (macOS) and 1301 (Linux) entries; earlier sections
may change the totals, so each task compares against its own before-dump.

Option probes use `extendModules`, which both outputs have. The macOS form of
the `--apply` expression is the one below, and the Linux form drops the
`home-manager.users.patrick.` prefix:

```nix
c:
(c.extendModules {
  modules = [ { home-manager.users.patrick.<option> = <value>; } ];
}).<path>
```

A probe skill directory is `c.pkgs.emptyDirectory`. This is how the existing
duplicate check is exercised today:

```sh
nix eval --raw --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
c:
let
  probe = {
    home-manager.users.patrick.my.agentSkills.storeSkills.tdd =
      c.pkgs.emptyDirectory;
  };
in
(c.extendModules { modules = [ probe ]; })
  .config.system.build.toplevel.drvPath'
# error: claude-skills: more than one collection provides tdd
```

A flake attribute that does not exist fails with
`error: flake '…' does not provide attribute … '<the attribute path>'`.

Activation scripts are tested by rendering an entry's `.data`, rewriting the
lines that name real directories to scratch ones with `sed`, refusing to run if
the rewrite missed, and sourcing the result with `run() { "$@"; }`, the one
helper home-manager's activation supplies that these scripts use.

**The real work layer.** `stubs/work` sets none of the work layer's skill
directories or skills, so every task here also evaluates the system against the
real work layer, with no `--override-input`. It prints only a store path or the
error:

```sh
nix eval --raw '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'
```

Expected: one line, `/nix/store/<hash>-darwin-system-<version>.drv`. Anything
else is an error: report its `error:` lines to Patrick, naming options and
skills but never a value from the work layer, and stop, because the fix may lie
in his work repository. Run it once before C5.1 Step 1 as a baseline; a failure
there predates this section, so report it and stop before C5.1.

### Task C5.1: One list of skill destinations

**Files:**

- Modify: `modules/home/claude-skills.nix` L9-16 (`agentSkills`,
  `agentSkillsHome`), L133-173 (`skillFilesRecursiveIn`, `extraSkillDirs`,
  `xcodePluginDir`, `xcodeSkillsDir`, F2's `skillDirs`, `claudeSkillFiles`),
  L310-314 (the `extraDirs` option), L340-361 (`config`: `home.file`, F2's
  `snippetslabSkill` argument, `localSkillsXcode`)
- Rename: `modules/home/claude-skills/local-skills-xcode.sh` (L1-26) to
  `modules/home/claude-skills/local-skills-recursive.sh`

**Interfaces:**

- Consumes: `my.agentSkills.extraDirs` (unchanged name and shape, the work layer
  sets it); F2's `home.activation.snippetslabSkill` and its `@skillFiles@`
  placeholder (file paths, unchanged here).
- Produces:
  - `my.agentSkills.recursiveDirs`: `listOf str`, default `[ ]`, absolute
    directories linked with `recursive = true`; declared in
    `modules/home/claude-skills.nix` beside `extraDirs`.
  - `my.agentSkills.destinations`: `listOf str`, `readOnly = true`,
    `default = destinations`, declared in `modules/home/claude-skills.nix`; the
    order is `skillsDir`, `agentSkillsHome`, then `extraDirs`, then
    `recursiveDirs`.
  - `home.activation.localSkillsRecursive` (replaces `localSkillsXcode`), from
    `claude-skills/local-skills-recursive.sh` with placeholders
    `@recursiveDirs@` and `@localSkills@`; a local skill with no `SKILL.md` is
    skipped with `claude-skills: no <src>/SKILL.md; skipping <name> in <dir>` on
    stderr, once per directory.

- [ ] **Step 1: Take the before-dumps.** Run both dump commands with label
      `c51-before`. Expected: two files; the macOS one has 317 targets directly
      under each of the three directories below, and
      `jq '[.[] | select(.target | startswith(".agents/skills/"))] | length'` on
      it gives 318, commitlint's `SKILL.md` included. Run Step 8's `skillFiles`
      probe too: it already prints the line given there, from F2's `skillDirs`.

```text
Library/Application Support/claude-code/skills
.agents/skills
Library/Application Support/claude-marketplace/plugins/nix-agents/skills
```

- [ ] **Step 2: Write the failing test.**

```sh
darwin='.#darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
nix eval --json --override-input work path:./stubs/work \
  "$hm.my.agentSkills.destinations" \
  | jq -r 'length, (.[] | sub("^/Users/patrick/"; "~/"))'
nix eval --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux".config.my.agentSkills.destinations' \
  | jq -r 'length, (.[] | sub("^/home/patrick/"; "~/"))'
```

Expected after the change, exactly (a path outside the home directory would
print unshortened):

```text
3
~/Library/Application Support/claude-code/skills
~/.agents/skills
~/Library/Application Support/claude-marketplace/plugins/nix-agents/skills
3
~/.config/claude-code/skills
~/.agents/skills
~/.config/claude-marketplace/plugins/nix-agents/skills
```

- [ ] **Step 3: Run it and see it fail.** Both commands fail with
      `does not provide attribute` naming `…my.agentSkills.destinations`.

- [ ] **Step 4: Declare the options.** In `claude-skills.nix`, after the
      `extraDirs` option (L310-314), add `options.my.agentSkills.recursiveDirs`
      (`lib.types.listOf lib.types.str`, `default = [ ]`, description: "Extra
      absolute directories to link every skill into as real directories of file
      links, for a reader that does not descend into a linked directory.") and
      `options.my.agentSkills.destinations` (`lib.types.listOf lib.types.str`,
      `readOnly = true`, `default = destinations`, description: "Every absolute
      directory each skill reaches: Claude Code's, the cross-agent one,
      `extraDirs`, then `recursiveDirs`."). Follow `my.java.jdk` in
      `modules/home/java.nix` L32-38 for the read-only shape.

- [ ] **Step 5: Link from the list.** In the `let`:
  - `agentSkillsHome = "${config.home.homeDirectory}/.agents/skills";` and
    delete the relative `agentSkills` (L15); the L9-14 comment stays above
    `agentSkillsHome`.
  - Add these three bindings, and delete `extraSkillDirs` (L147):

    ```nix
    flatDirs = [
      skillsDir
      agentSkillsHome
    ]
    ++ config.my.agentSkills.extraDirs;
    recursiveDirs = config.my.agentSkills.recursiveDirs;
    destinations = flatDirs ++ recursiveDirs;
    ```

  - Delete F2's `skillDirs` binding and the two-line comment above it, which
    names the relative `agentSkills` this step deletes. In
    `home.activation.snippetslabSkill`, set the argument to exactly the
    following. The script keeps taking file paths, not directories; C5.3 changes
    it to take `@destinations@`.

    ```nix
    skillFiles = lib.escapeShellArgs (
      map (dir: "${dir}/snippetslab/SKILL.md") destinations
    );
    ```

  - `claudeSkillFiles` (L158-173) becomes: `skillFilesIn` folded over
    `flatDirs`, `skillFilesRecursiveIn` folded over `recursiveDirs`,
    commitlint's
    `"${dir}/committing-with-commitlint/SKILL.md".source = commitlintSkill` for
    every `dir` in `destinations`, and the `subagentCatalogDir` entry. The four
    hand-written commitlint lines and the `genAttrs` over `extraSkillDirs` go;
    keep the L163-164 comment above the commitlint entries.
  - Reword the comment above `skillFilesRecursiveIn` (L133-136) to "for a reader
    that does not descend into a symlinked directory" rather than naming Xcode;
    the `recursive = true` sentence stays.
  - In `config`, add `my.agentSkills.recursiveDirs = [ xcodeSkillsDir ];` (C5.2
    moves this to `darwin/xcode.nix`). `xcodePluginDir` and `xcodeSkillsDir`
    stay for now.

- [ ] **Step 6: Generalise the local-skills mirror.** Rename the script:

```sh
git mv modules/home/claude-skills/local-skills-xcode.sh \
  modules/home/claude-skills/local-skills-recursive.sh
```

In it, replace `xcodeSkillsDir=@xcodeSkillsDir@` with
`recursiveDirs=(@recursiveDirs@)`, at column 0 like `localSkills=` (Step 10
rewrites both lines by pattern). Wrap the existing per-skill loop in
`for dir in "${recursiveDirs[@]}"; do … done`, with `dest="$dir/$name"`, and
change the skip message to
`claude-skills: no $src/SKILL.md; skipping $name in $dir`. Reword the header
comment to the reader that does not descend into a linked directory, without
naming Xcode. In `claude-skills.nix` replace `home.activation.localSkillsXcode`
(L354-361) with `home.activation.localSkillsRecursive`, guarded by
`lib.mkIf (localSkills != { } && recursiveDirs != [ ])`, substituting
`recursiveDirs = lib.escapeShellArgs recursiveDirs;` and the unchanged
`localSkills`.

- [ ] **Step 7: Run the test and see it pass.** The Step 2 commands print
      exactly the lines shown there.

- [ ] **Step 8: Prove nothing linked moved.** Dump with label `c51-after`, then
      compare. Expected: both identical, although the `.agents/skills` attribute
      names became absolute.

```sh
for p in darwin linux; do
  cmp "$TMPDIR/$p-c51-before.json" "$TMPDIR/$p-c51-after.json"
done
```

Then the `skillFiles` probe, a regression guard that passes before and after the
change:

```sh
darwin='.#darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
as='/Users/patrick/Library/Application Support'
f=snippetslab/SKILL.md
expected="  skillFiles=('$as/claude-code/skills/$f'"
expected+=" /Users/patrick/.agents/skills/$f"
expected+=" '$as/claude-marketplace/plugins/nix-agents/skills/$f')"
nix eval --raw --override-input work path:./stubs/work \
  "$hm.home.activation.snippetslabSkill.data" \
  | grep -Fx -e "$expected"
```

Expected: that line printed. Its first element is Claude Code's `SKILL.md`,
where the script generates, and every element is a file path, not a directory.

- [ ] **Step 9: Probe the new options.**

```sh
nix eval --json --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
c:
let
  probe = {
    home-manager.users.patrick.my.agentSkills = {
      recursiveDirs = [ "/Users/patrick/probe" ];
      extraDirs = [ "/Users/patrick/flat-probe" ];
    };
  };
  hm = (c.extendModules { modules = [ probe ]; })
    .config.home-manager.users.patrick;
  at = t: builtins.head (
    builtins.filter (v: v.target == t) (builtins.attrValues hm.home.file)
  );
in
map (t: (at t).recursive) [
  "probe/tdd"
  "flat-probe/tdd"
  "probe/committing-with-commitlint/SKILL.md"
  "flat-probe/committing-with-commitlint/SKILL.md"
]'
```

Expected: `[true,false,false,false]`.

```sh
opt=home-manager.users.patrick.my.agentSkills.destinations
nix eval --json --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
c:
(c.extendModules {
  modules = [
    { home-manager.users.patrick.my.agentSkills.destinations = [ "/tmp/x" ]; }
  ];
}).config.home-manager.users.patrick.my.agentSkills.destinations' 2>&1 \
  | grep -cF "The option \`$opt' is read-only, but it's set multiple times."
```

Expected: `1`, the evaluation failing with that read-only error.

```sh
plugin='/Users/patrick/Library/Application Support/claude-marketplace'
plugin+=/plugins/nix-agents/skills
nix eval --raw --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
c:
let
  probe = {
    home-manager.users.patrick.my.agentSkills.localSkills.demo =
      "/tmp/demo-skill";
  };
  hm = (c.extendModules { modules = [ probe ]; })
    .config.home-manager.users.patrick;
in
hm.home.activation.localSkillsRecursive.data' \
  | grep -F -e "recursiveDirs=('$plugin')" \
    -e "localSkills=('demo=/tmp/demo-skill')"
```

Expected: both lines printed.

- [ ] **Step 10: Run the mirror against scratch directories.** The rendered
      script, pointed at two scratch destinations (one holding a space) and a
      scratch skill with a nested file, a `.git` directory and a missing sibling
      skill:

```sh
d=$(mktemp -d "${TMPDIR:-/tmp}/c51.XXXXXX")
nix eval --raw --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
c:
let
  probe = {
    home-manager.users.patrick.my.agentSkills.localSkills.demo =
      "/tmp/demo-skill";
  };
  hm = (c.extendModules { modules = [ probe ]; })
    .config.home-manager.users.patrick;
in
hm.home.activation.localSkillsRecursive.data' \
  2>/dev/null >"$d/mirror.sh"
mkdir -p "$d/src/refs" "$d/src/.git"
printf 'skill\n' >"$d/src/SKILL.md"
printf 'ref\n' >"$d/src/refs/a.md"
printf 'x\n' >"$d/src/.git/HEAD"
sed -i.bak \
  -e "s|^recursiveDirs=.*|recursiveDirs=('$d/x' '$d/y z')|" \
  -e "s|^localSkills=.*|localSkills=('demo=$d/src' 'gone=$d/missing')|" \
  "$d/mirror.sh"
grep -q "^recursiveDirs=('$d/x'" "$d/mirror.sh" \
  || { echo "sed missed; not running"; exit 1; }
bash -c 'run() { "$@"; }; source "$1"' _ "$d/mirror.sh" 2>&1 \
  | sed "s|$d|<d>|g"
cd "$d" && find x 'y z' -type l | LC_ALL=C sort
readlink 'y z/demo/refs/a.md' | sed "s|$d|<d>|"
```

Expected, exactly:

```text
claude-skills: no <d>/missing/SKILL.md; skipping gone in <d>/x
claude-skills: no <d>/missing/SKILL.md; skipping gone in <d>/y z
x/demo/SKILL.md
x/demo/refs/a.md
y z/demo/SKILL.md
y z/demo/refs/a.md
<d>/src/refs/a.md
```

No `.git` is mirrored, and the guard keeps the run away from the real plugin
directory.

- [ ] **Step 11: Run the suites.** `mise run test` and `mise run lint`, sandbox
      off. Expected: both pass; `lint:shell` covers the renamed script.

- [ ] **Step 12: Evaluate against the real work layer.** Run the harness's
      real-work-layer command. Expected: one store path. The work layer's
      `extraDirs` now reach `my.agentSkills.destinations`, and its `localSkills`
      the renamed `localSkillsRecursive` entry, which the stub cannot show.

- [ ] **Step 13: Commit.**

```sh
git add modules/home/claude-skills.nix \
  modules/home/claude-skills/local-skills-recursive.sh
git -c commit.gpgsign=false commit \
  -m "refactor(skills): link from one destination list" \
  -m "Each skill destination was named on its own: the flat directories,
the Xcode plugin's recursive one, commitlint's four hand-written
entries, the snippetslab activation's list and the local-skills mirror
each spelled theirs. One list, read-only as my.agentSkills.destinations,
now drives all of them, and my.agentSkills.recursiveDirs lets a module
add a destination for a reader that does not descend into a linked
directory. Every linked file is unchanged on both configurations."
```

After Patrick's switch: the work layer's local `ubiops` skill is still mirrored
under the Xcode plugin's `skills/ubiops/` as real directories of links into its
checkout.

### Task C5.2: darwin/xcode.nix owns the nix-agents plugin

**Files:**

- Modify: `modules/home/claude-skills.nix` L149-156 (`xcodePluginDir`,
  `xcodeSkillsDir` and their comment), L175-211 (`voltagentFiles`), the
  `recursiveDirs` line C5.1 added to `config`, the options block (add
  `subagentDirs`)
- Modify: `modules/home/darwin/xcode.nix` L1-7 (formals), L8-77 (`let`), L78-109
  (body)
- Modify: `modules/home/darwin/mcp.nix` L1-7 (formals), L64-70 (`xcodeMcpJson`
  and its comment), L78-89 (the `.mcp.json` link and its comment)

**Interfaces:**

- Consumes: `my.agentSkills.recursiveDirs` (C5.1), `my.mcp.servers`.
- Produces:
  - `my.agentSkills.subagentDirs`: `listOf str`, default `[ ]`, absolute
    directories every subagent file is linked into besides Claude Code's own
    `agentsDir`; declared in `modules/home/claude-skills.nix`.
  - In `modules/home/darwin/xcode.nix`, one `let` binding, `pluginDir`, set to
    `"${config.xdg.configHome}/claude-marketplace/plugins/nix-agents"`, from
    which it sets `my.agentSkills.recursiveDirs = [ "${pluginDir}/skills" ];`,
    `my.agentSkills.subagentDirs = [ "${pluginDir}/agents" ];` and
    `home.file."${pluginDir}/.mcp.json".source`. It is the only place in
    `modules/` that spells `plugins/nix-agents`.
  - `modules/home/darwin/mcp.nix` keeps only `my.mcp.servers`.

- [ ] **Step 1: Take the before-dumps** with label `c52-before`.

- [ ] **Step 2: Write the failing test.**

```sh
jq 'map(select(.target | contains("claude-marketplace/plugins/nix-agents/")))
  | length' "$TMPDIR/linux-c52-before.json"
```

Expected after the change, on the `c52-after` dump: `0`. On the before-dump it
prints `474` (307 skill links, commitlint's `SKILL.md`, 166 subagents), so the
test fails now.

- [ ] **Step 3: Add `subagentDirs`.** Declare it beside `recursiveDirs`
      (description: "Extra absolute directories to link every subagent into.").
      In `voltagentFiles`, `destinations` becomes
      `[ agentsDir ] ++ config.my.agentSkills.subagentDirs`; cut the L191-194
      comment to what still holds (individual `.md` files, so no `recursive`).

- [ ] **Step 4: Move the plugin into `darwin/xcode.nix`.**
  - `claude-skills.nix`: delete `xcodePluginDir`, `xcodeSkillsDir`, their
    comment (L149-154) and the `my.agentSkills.recursiveDirs` line C5.1 added.
  - `darwin/xcode.nix`: add `pluginDir` and `mcpJson` (the `xcodeMcpJson`
    binding moved verbatim from `darwin/mcp.nix` L68-70, keeping the generator
    name `"xcode-mcp-servers.json"` and
    `lib.removeAttrs config.my.mcp.servers [ "xcode" ]`, so its store path does
    not change). In the body set the two `my.agentSkills` lists and
    `home.file."${pluginDir}/.mcp.json".source = mcpJson;`.
  - Move the comments with them: claude-skills.nix L149-154 (why one plugin) and
    mcp.nix L64-67 and L78-88 (why the servers go into the plugin, why `xcode`
    is dropped). Rewrite "plug-in" as "plugin" (GLOSSARY.md lists "plug-in"
    under _Avoid_), drop the "modules/home/claude-skills.nix fills"
    cross-reference, and keep each line within 72 columns.
  - `darwin/mcp.nix`: delete `xcodeMcpJson` and the `.mcp.json` line, and drop
    the formals that become unused (`config`, `lib`); `mise run lint:nix`
    reports any left.

- [ ] **Step 5: Run the test and see it pass.** Dump with label `c52-after`; the
      Step 2 command on `linux-c52-after.json` prints `0`.

- [ ] **Step 6: Check nothing else moved.**

```sh
cmp "$TMPDIR/darwin-c52-before.json" "$TMPDIR/darwin-c52-after.json"
jq -cS 'map(select(.target
  | contains("claude-marketplace/plugins/nix-agents/") | not))' \
  "$TMPDIR/linux-c52-before.json" | cmp - "$TMPDIR/linux-c52-after.json"
```

Expected: both identical (macOS unchanged entry for entry, `.mcp.json` included;
Linux exactly 474 entries fewer, 1301 to 827 at `a07c2f4`).

- [ ] **Step 7: Check the options and the single path.**

```sh
darwin='.#darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
nix eval --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux".config.my.agentSkills.destinations' \
  | jq -r 'length, (.[] | sub("^/home/patrick/"; "~/"))'
nix eval --json --override-input work path:./stubs/work \
  "$hm.my.agentSkills.subagentDirs" \
  | jq -r 'length, (.[] | sub("^/Users/patrick/"; "~/"))'
nix eval --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux"' --apply '
c:
let
  probe = { my.agentSkills.localSkills.demo = "/tmp/demo-skill"; };
in
(c.extendModules { modules = [ probe ]; }).config.home.activation
  ? localSkillsRecursive'
git grep -n 'plugins/nix-agents' -- modules
```

Expected, in order, these lines and then one `git grep` line, in
`modules/home/darwin/xcode.nix`:

```text
2
~/.config/claude-code/skills
~/.agents/skills
1
~/Library/Application Support/claude-marketplace/plugins/nix-agents/agents
false
```

The macOS `destinations` still prints the three paths from C5.1 Step 2. Re-run
C5.1 Step 8's `skillFiles` probe and C5.1 Step 9's last command: both print the
same lines as in C5.1, the plugin's directory now coming from
`darwin/xcode.nix`.

- [ ] **Step 8: Run the suites.** `mise run test` and `mise run lint`, sandbox
      off. Expected: both pass.

- [ ] **Step 9: Evaluate against the real work layer.** Run the harness's
      real-work-layer command. Expected: one store path. The work layer's
      `extraDirs` now come before the plugin's directory, which
      `darwin/xcode.nix` contributes through `recursiveDirs`, and every subagent
      reaches the new `subagentDirs`.

- [ ] **Step 10: Commit.**

```sh
git add modules/home/claude-skills.nix modules/home/darwin/xcode.nix \
  modules/home/darwin/mcp.nix
git -c commit.gpgsign=false commit \
  -m "refactor(xcode): own the nix-agents plugin" \
  -m "The plugin Xcode imports had its path spelled in two modules and was
filled from the portable half, so every Linux configuration linked
474 files into a plugin only Xcode reads. darwin/xcode.nix now names
the path once and contributes the skills through recursiveDirs, the
subagents through the new subagentDirs and the MCP servers' .mcp.json
itself. The macOS files are unchanged."
```

### Task C5.3: darwin/snippetslab.nix owns its generated skill

**Files:**

- Modify: `modules/home/darwin/snippetslab.nix` L1-21, the existing `lab`
  wrapper module: extend it, do not create or overwrite it
- Move: `modules/home/claude-skills/snippetslab-skill.sh` (as F2 left it) to
  `modules/home/darwin/snippetslab/skill.sh`, beside the existing `lab.sh`
- Modify: `modules/home/claude-skills.nix` F2's `generatedSkills` binding and
  its comment (above `duplicateSkills`), L105-116 (`duplicateSkills`), L340-352
  (F2's `home.activation.snippetslabSkill`), the options block (add
  `generatedSkills`)
- Modify: `docs/architecture.md` L61-80 (Conventions: one bullet before the
  `codebook.toml` one)

**Interfaces:**

- Consumes: `my.agentSkills.destinations` (C5.1); F2's `generatedSkills` let
  binding and `snippetslab-skill.sh`, both replaced here.
- Produces:
  - `my.agentSkills.generatedSkills`: `listOf str`, default `[ ]`, names of
    skills an activation entry writes into every destination; declared in
    `modules/home/claude-skills.nix`, where the duplicate-name check reads it.
  - `skillEntries` in `claude-skills.nix`'s `let`: the name-value list the
    duplicate check groups (grouped skills, `skillSingles`, `localSkills`,
    `storeSkills`, and `lib.nameValuePair n null` for
    `"committing-with-commitlint"`, which C5.4 removes, and for each generated
    name). C5.6 reads its names.
  - `home.activation.snippetslabSkill` (same entry name) in
    `modules/home/darwin/snippetslab.nix`, from
    `modules/home/darwin/snippetslab/skill.sh` with placeholders `@lab@`
    (`lib.escapeShellArg labPath`) and `@destinations@`
    (`lib.escapeShellArgs config.my.agentSkills.destinations`). The script's two
    anchor lines are `lab=@lab@` at column 0 and `destinations=(@destinations@)`
    indented two spaces; Step 7 rewrites both by pattern.

- [ ] **Step 1: Take the before-dumps** with label `c53-before`.

- [ ] **Step 2: Write the failing tests.**

```sh
darwin='.#darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
nix eval --json --override-input work path:./stubs/work \
  "$hm.my.agentSkills.generatedSkills"
nix eval --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux".config.my.agentSkills.generatedSkills'
as='/Users/patrick/Library/Application Support'
expected="  destinations=('$as/claude-code/skills'"
expected+=" /Users/patrick/.agents/skills /Users/patrick/flat-probe"
expected+=" '$as/claude-marketplace/plugins/nix-agents/skills')"
nix eval --raw --override-input work path:./stubs/work \
  "$darwin" --apply '
c:
let
  probe = {
    home-manager.users.patrick.my.agentSkills.extraDirs = [
      "/Users/patrick/flat-probe"
    ];
  };
  hm = (c.extendModules { modules = [ probe ]; })
    .config.home-manager.users.patrick;
in
hm.home.activation.snippetslabSkill.data' \
  | grep -F -e "$expected" \
    -e "lab=/Applications/SnippetsLab.app/Contents/Helpers/lab"
```

Expected after the change: `["snippetslab"]`, `[]`, and both `grep` patterns
matched, the first as the whole `destinations=(…)` line at two spaces' indent
(the probe's `extraDirs` entry sits between the cross-agent directory and the
Xcode plugin's).

- [ ] **Step 3: Run them and see them fail.** The first two fail with
      `does not provide attribute` naming `my.agentSkills.generatedSkills`; the
      `grep` prints at most the `lab=` line.

- [ ] **Step 4: Declare `generatedSkills` and build `skillEntries`.** Declare
      the option beside `subagentDirs` (description: "Names of skills an
      activation entry writes into every destination, so the duplicate-name
      check covers them."). Delete F2's `generatedSkills` let binding, its
      two-line comment and the
      `++ map (n: lib.nameValuePair n null) generatedSkills` term F2 appended to
      the list `lib.groupBy` takes. Lift that list into a new binding, and let
      `duplicateSkills` group it; the L105-106 comment stays above
      `duplicateSkills`:

```nix
  skillEntries =
    groupedSkills
    ++ lib.mapAttrsToList lib.nameValuePair skillSingles
    ++ lib.mapAttrsToList lib.nameValuePair localSkills
    ++ lib.mapAttrsToList lib.nameValuePair storeSkills
    ++ map (n: lib.nameValuePair n null) (
      [ "committing-with-commitlint" ] ++ config.my.agentSkills.generatedSkills
    );
```

`duplicateSkills` becomes:

```nix
  duplicateSkills = lib.attrNames (
    lib.filterAttrs (_: v: builtins.length v > 1) (
      lib.groupBy (x: x.name) skillEntries
    )
  );
```

`snippetslab` now reaches the check only through the option, so nothing names it
twice once Step 5 sets the option.

- [ ] **Step 5: Move the activation.** Move the script:

```sh
git mv modules/home/claude-skills/snippetslab-skill.sh \
  modules/home/darwin/snippetslab/skill.sh
```

In it, keep the header comment, F2's structure and its `DRY_RUN` guard:
`lab=@lab@` at column 0 replaces the hard-coded path;
`destinations=(@destinations@)` indented two spaces, inside the
`if [ -x "$lab" ]`, replaces `skillFiles`; `run mkdir -p` each
`"$dest/snippetslab"`; under the guard, generate `"$lab" skill show` into
`"${destinations[0]}/snippetslab/SKILL.md.tmp"`, `mv -f` it into place and
`cp -f` that file to `"$dest/snippetslab/SKILL.md"` for every other destination,
or `rm -f` the `.tmp` on failure. The message on a missing app becomes
`snippetslab: SnippetsLab not installed; skipping its agent skill`.

Extend the existing `darwin/snippetslab.nix` with the Edit tool; its `labPath`,
`lab` wrapper and comment stay as they are. Add `config` to the formals,
`my.agentSkills.generatedSkills = [ "snippetslab" ];` and the entry below, with
the two placeholders above, reusing `labPath`. Delete F2's
`home.activation.snippetslabSkill` from `claude-skills.nix`; two definitions of
the entry would conflict.

```nix
  home.activation.snippetslabSkill =
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      (substituteFile ./snippetslab/skill.sh { … });
```

- [ ] **Step 6: Run the tests and see them pass.** The Step 2 commands print
      `["snippetslab"]`, `[]` and both `grep` lines.

- [ ] **Step 7: Run the activation against a stub `lab`.** The rendered script,
      pointed at three scratch destinations (one holding a space, one nested
      like the Xcode plugin's), first with a `lab` that succeeds, then with one
      that fails:

```sh
darwin='.#darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
d=$(mktemp -d "${TMPDIR:-/tmp}/c53.XXXXXX")
nix eval --raw --override-input work path:./stubs/work \
  "$hm.home.activation.snippetslabSkill.data" 2>/dev/null >"$d/skill.sh"
printf '#!/bin/sh\necho stub skill\n' >"$d/lab" && chmod +x "$d/lab"
dests="('$d/a' '$d/b c' '$d/plugin/skills')"
sed -i.bak \
  -e "s|^lab=.*|lab='$d/lab'|" \
  -e "s|^  destinations=.*|  destinations=$dests|" \
  "$d/skill.sh"
grep -q "^lab='$d/lab'" "$d/skill.sh" \
  && grep -q "^  destinations=('$d/a'" "$d/skill.sh" \
  || { echo "sed missed; not running"; exit 1; }
bash -c 'run() { "$@"; }; source "$1"' _ "$d/skill.sh"
for s in a 'b c' plugin/skills; do cat "$d/$s/snippetslab/SKILL.md"; done
ls -A "$d/a/snippetslab"
printf '#!/bin/sh\nexit 1\n' >"$d/lab"
bash -c 'run() { "$@"; }; source "$1"' _ "$d/skill.sh"
cat "$d/a/snippetslab/SKILL.md"
ls -A "$d/a/snippetslab"
```

Expected: `stub skill` three times, then `SKILL.md` alone; then, after the
failing `lab`, `stub skill` and `SKILL.md` alone again: a failed generation
leaves the previous skill in place and no `.tmp` behind. The guard keeps the
test away from the real skill directories.

- [ ] **Step 8: Check the duplicate check and the halves.**

```sh
nix eval --raw --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
c:
let
  probe = {
    home-manager.users.patrick.my.agentSkills.storeSkills.snippetslab =
      c.pkgs.emptyDirectory;
  };
in
(c.extendModules { modules = [ probe ]; })
  .config.system.build.toplevel.drvPath'
nix eval --raw --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux"' --apply '
c:
let
  probe = { my.agentSkills.storeSkills.snippetslab = c.pkgs.emptyDirectory; };
in
(c.extendModules { modules = [ probe ]; }).activationPackage.drvPath'
nix eval --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux".config.home.activation' \
  --apply 'a: a ? snippetslabSkill'
```

Expected: the first fails with
`error: claude-skills: more than one collection provides snippetslab`; the
second prints a `/nix/store/…-home-manager-generation.drv` path; the third
prints `false`. Dump with label `c53-after`; both `cmp` against `c53-before` are
identical (nothing linked changed).

- [ ] **Step 9: Document the destination model.** In `docs/architecture.md`
      Conventions, before the `codebook.toml` bullet, add one bullet: a skill
      reaches every directory in `my.agentSkills.destinations`, which
      `modules/home/claude-skills.nix` sets; a module adds a destination through
      `my.agentSkills.extraDirs`, or `recursiveDirs` for a reader that does not
      descend into a linked directory, as `darwin/xcode.nix` does for the
      `nix-agents` plugin (with `subagentDirs` for its subagents); a skill an
      activation entry writes instead, such as SnippetsLab's, copies itself into
      each destination and names itself in `my.agentSkills.generatedSkills` so
      the duplicate-name check covers it. Format it:

```sh
"$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
  --prose-wrap=always --print-width=80 docs/architecture.md
```

- [ ] **Step 10: Run the suites.** `mise run test` and `mise run lint`, sandbox
      off. Expected: both pass; `lint:shell` covers the moved script and
      `lint:markdown` the bullet.

- [ ] **Step 11: Evaluate against the real work layer.** Run the harness's
      real-work-layer command. Expected: one store path. `snippetslabSkill` now
      writes into every destination, the work layer's `extraDirs` included, and
      the duplicate check reads `generatedSkills` beside the work layer's
      `storeSkills` and `localSkills`.

- [ ] **Step 12: Commit.**

```sh
git add modules/home/claude-skills.nix modules/home/darwin/snippetslab.nix \
  modules/home/darwin/snippetslab/skill.sh docs/architecture.md
git -c commit.gpgsign=false commit \
  -m "refactor(snippetslab): own its generated skill" \
  -m "SnippetsLab's skill is generated by the app's own lab binary, a
macOS-only fact the portable claude-skills.nix had to guard against
and whose path it repeated. darwin/snippetslab.nix now writes it into
every entry of my.agentSkills.destinations with the lab path it
already knows, and names it in the new generatedSkills so the
duplicate-name check still covers it without knowing the app."
```

After Patrick's switch, the real `lab` writes one skill everywhere; this Nushell
command prints one `sha` in every row and `tmp` false throughout, the Xcode
plugin's and the work layer's destinations included:

```nu
let attr = [
  "/etc/nix-darwin#darwinConfigurations"
  "Patricks-MacBook-Pro.config.home-manager.users.patrick"
  "my.agentSkills.destinations"
] | str join "."
nix eval --json $attr | from json | each {|dir|
  {
    dir: $dir
    sha: (open --raw ($dir | path join snippetslab SKILL.md) | hash sha256)
    tmp: ($dir | path join snippetslab SKILL.md.tmp | path exists)
  }
}
```

### Task C5.4: commitlint as a directory skill

**Files:**

- Modify: `modules/home/claude-skills.nix` L77-80 (`skillSingles`), the
  `"committing-with-commitlint"` literal C5.3 left in `skillEntries`, the
  commitlint entries C5.1 left in `claudeSkillFiles` (originally L163-173),
  L252-260 (`commitlintSkill`)

**Interfaces:**

- Consumes: `skillSingles` (linked into every destination by
  `skillFilesIn`/`skillFilesRecursiveIn`), `skillEntries` (C5.3).
- Produces: `skillSingles.committing-with-commitlint`, the one-file
  `pkgs.linkFarm` directory Step 4 adds; `commitlintSkill` stays the `fetchurl`
  of the bare `SKILL.md` and is never read at evaluation time. `skillEntries`'
  last term is
  `map (n: lib.nameValuePair n null) config.my.agentSkills.generatedSkills`.

- [ ] **Step 1: Take the before-dumps** with label `c54-before`.

- [ ] **Step 2: Write the failing test.** It prints the number of commitlint
      entries, then each one's `recursive` and its target with the trailing
      `/committing-with-commitlint` cut, then whether every source is a store
      path named `committing-with-commitlint`:

```sh
nix eval --json --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply '
c:
map (v: {
  inherit (v) target recursive;
  source = toString v.source;
}) (
  builtins.filter
    (v: builtins.match ".*committing-with-commitlint.*" v.target != null)
    (builtins.attrValues c.config.home-manager.users.patrick.home.file)
)' | jq -r --arg s /committing-with-commitlint '
  length,
  (sort_by(.target)[] | "\(.recursive) \(.target | rtrimstr($s))"),
  all(.source | test("^/nix/store/[a-z0-9]{32}-committing-with-commitlint$"))'
```

Expected after the change, exactly:

```text
3
false .agents/skills
false Library/Application Support/claude-code/skills
true Library/Application Support/claude-marketplace/plugins/nix-agents/skills
true
```

With the current nixpkgs pin every source is
`/nix/store/l7v6jg52bgirfliv229b59sivafgxvs7-committing-with-commitlint`.

- [ ] **Step 3: Run it and see it fail.** It prints `3`, three `false` lines
      whose targets still end in `/committing-with-commitlint/SKILL.md`, and a
      final `false`: each source is
      `/nix/store/4vh941as0mlnn2al7z5118skrwpqclsx-SKILL.md`.

- [ ] **Step 4: Implement.** Add this as the first entry of `skillSingles`
      (alphabetical):

```nix
    committing-with-commitlint = pkgs.linkFarm "committing-with-commitlint" {
      "SKILL.md" = commitlintSkill;
    };
```

Delete the commitlint entries and their comment from `claudeSkillFiles`, leaving
the folds and `subagentCatalogDir`. In `skillEntries`, delete the
`"committing-with-commitlint"` literal C5.3 left, so the last term reads
`map (n: lib.nameValuePair n null) config.my.agentSkills.generatedSkills`: left
in, the duplicate check fires on the skill itself. Keep `commitlintSkill`, its
`@VERSION` line and its comment; F12's `@VERSION` URL stays as F12 left it.

- [ ] **Step 5: Run the test and see it pass.** The Step 2 command prints the
      five lines shown there.

- [ ] **Step 6: Check the built skill and the rest.**

```sh
darwin='.#darwinConfigurations.Patricks-MacBook-Pro'
drv=$(nix eval --raw --override-input work path:./stubs/work \
  "$darwin" --apply '
c:
let
  skills = "Library/Application Support/claude-code/skills";
  files = builtins.attrValues c.config.home-manager.users.patrick.home.file;
  at = t: builtins.head (builtins.filter (v: v.target == t) files);
in
(at "${skills}/committing-with-commitlint").source.drvPath')
head -n 2 "$(nix build --no-link --print-out-paths "$drv^out")/SKILL.md"
nix eval --raw --override-input work path:./stubs/work \
  "$darwin" --apply '
c:
let
  probe = {
    home-manager.users.patrick.my.agentSkills.storeSkills = {
      committing-with-commitlint = c.pkgs.emptyDirectory;
    };
  };
in
(c.extendModules { modules = [ probe ]; })
  .config.system.build.toplevel.drvPath'
```

Expected: `---` then `name: committing-with-commitlint`; then the second command
fails with an `error:` line carrying this message:

```text
claude-skills: more than one collection provides committing-with-commitlint
```

Dump with label `c54-after`, then:

```sh
f='map(select(.target | contains("committing-with-commitlint") | not))'
for p in darwin linux; do
  jq -cS "$f" "$TMPDIR/$p-c54-before.json" >"$TMPDIR/a"
  jq -cS "$f" "$TMPDIR/$p-c54-after.json" | cmp - "$TMPDIR/a"
done
```

Expected: identical for both; the totals are unchanged (one entry per
destination before and after).

- [ ] **Step 7: Run the suites.** `mise run test` and `mise run lint`, sandbox
      off. Expected: both pass.

- [ ] **Step 8: Evaluate against the real work layer.** Run the harness's
      real-work-layer command. Expected: one store path. commitlint now reaches
      the work layer's `extraDirs` as a directory skill, and the duplicate check
      sees it beside the work layer's `storeSkills` and `localSkills`.
      Evaluation cannot see the switch-time collision Step 10 handles.

- [ ] **Step 9: Commit.**

```sh
git add modules/home/claude-skills.nix
git -c commit.gpgsign=false commit \
  -m "refactor(skills): link commitlint as a directory" \
  -m "commitlint publishes its skill as a bare SKILL.md, so it was named a
level deeper in every destination by hand and joined the
duplicate-name check by a hand-written entry. A one-file linkFarm
makes it a directory skill like any other in skillSingles, reaching
every destination and the check by the same path, without reading
the fetched file at evaluation time."
```

- [ ] **Step 10: Hand Patrick the pre-switch step.** No evaluation sees this, so
      put it in the report for Patrick, to run in Nushell once the branch is in
      `/etc/nix-darwin`'s checkout and before `darwin-rebuild switch`. Each flat
      destination holds `committing-with-commitlint/` as a real directory today;
      with `home-manager.backupFileExtension = "hm-backup"` the switch would
      move it aside as `committing-with-commitlint.hm-backup/`, a second skill
      of the same name whose link dangles after garbage collection, and a later
      collision on the same path then aborts activation instead of backing up
      again. The list includes the work layer's destinations:

```nu
let attr = [
  "/etc/nix-darwin#darwinConfigurations"
  "Patricks-MacBook-Pro.config.home-manager.users.patrick"
  "my.agentSkills.destinations"
] | str join "."
nix eval --json $attr | from json | each {|dir|
  rm --recursive --force ($dir | path join committing-with-commitlint)
} | ignore
```

If the switch ran first, remove the backups it left instead:

```nu
let attr = [
  "/etc/nix-darwin#darwinConfigurations"
  "Patricks-MacBook-Pro.config.home-manager.users.patrick"
  "my.agentSkills.destinations"
] | str join "."
nix eval --json $attr | from json | each {|dir|
  rm --recursive --force ($dir | path join committing-with-commitlint.hm-backup)
} | ignore
```

After the switch, check every destination: `skill` is `symlink` for each flat
destination and `dir` for the Xcode plugin's recursive one, and `backup` is
`false` throughout. The hand-placed `repo-setup`, `synced` and `.trash` in
Claude Code's skills directory and `repo-setup` in `~/.agents/skills` are still
there:

```nu
let attr = [
  "/etc/nix-darwin#darwinConfigurations"
  "Patricks-MacBook-Pro.config.home-manager.users.patrick"
  "my.agentSkills.destinations"
] | str join "."
nix eval --json $attr | from json | each {|dir|
  let skill = ($dir | path join committing-with-commitlint)
  {
    dir: $dir
    skill: ($skill | path type)
    backup: ($"($skill).hm-backup" | path exists)
  }
}
```

### Task C5.5: Link ECC's git-workflow again

**Files:**

- Modify: `modules/home/claude-skills/ecc-overlaps.nix` L45
  (`git-workflow = "resolving-merge-conflicts";`)
- Modify, outside the repository and not committed:
  `~/Library/Application Support/claude-code/skill-index.md` L26 and every
  `~/Library/Application Support/orca/claude-profiles/*/home/skill-index.md`
  that carries the line; today all three profiles do (`083b30c5-…`,
  `776c09cc-…`, `82d551a4-…`), each at L26

**Interfaces:**

- Consumes: `eccSkills` (ECC at `c05b2d66`, whose `skills/git-workflow/SKILL.md`
  covers merge-versus-rebase and conflict resolution).
- Produces: `git-workflow` linked into every destination; the canonical skill
  index and every Orca profile copy that carries the line route "Merge or rebase
  conflict" to `git-workflow`.

- [ ] **Step 1: Take the before-dumps** with label `c55-before`.

- [ ] **Step 2: Write the failing test.**

```sh
nix eval --json --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply 'c: map (v: {
    inherit (v) target recursive; source = toString v.source;
  }) (builtins.filter (v: baseNameOf v.target == "git-workflow")
    (builtins.attrValues c.config.home-manager.users.patrick.home.file))'
```

Expected after the change: three entries, under `.agents/skills/`,
`Library/Application Support/claude-code/skills/` (both `"recursive":false`) and
`Library/Application Support/claude-marketplace/plugins/nix-agents/skills/`
(`"recursive":true`), each with source
`/nix/store/wk4q0dr2y6ccf6a6nc6bf71lyw509gci-source/skills/git-workflow`.

- [ ] **Step 3: Run it and see it fail.** It prints `[]`.

- [ ] **Step 4: Implement.** Delete the `git-workflow` line from
      `ecc-overlaps.nix`. No other collection provides the name, so the
      duplicate check stays quiet.

- [ ] **Step 5: Run the test and see it pass,** then dump with label
      `c55-after`. Expected: `darwin-c55-after.json` holds exactly 3 entries
      more than `darwin-c55-before.json` and `linux-…` exactly 2 more, all
      targets ending in `/git-workflow`:

```sh
for p in darwin linux; do
  jq -cS 'map(select(.target | endswith("/git-workflow") | not))' \
    "$TMPDIR/$p-c55-after.json" | cmp - "$TMPDIR/$p-c55-before.json"
done
```

- [ ] **Step 6: Route the skill index.** List the copies that carry the line:

```sh
cd "$HOME/Library/Application Support" &&
  grep -lF -e '- **Merge or rebase conflict**:' \
    claude-code/skill-index.md orca/claude-profiles/*/home/skill-index.md
```

Expected today, four paths: `claude-code/skill-index.md` and the three
`orca/claude-profiles/<id>/home/skill-index.md`. In every listed file, with the
Edit tool (Read first; the files are outside the worktree, so it asks), change
``- **Merge or rebase conflict**: `resolving-merge-conflicts`.`` to
``- **Merge or rebase conflict**: `git-workflow`.`` and touch nothing else: the
`776c09cc-…` and `82d551a4-…` copies keep their own line 34.

If the edit is refused, or no one can approve it, change nothing outside the
repository. Commit (Step 10) and hand Patrick this Nushell command, then run
Step 7 once he has:

```nu
cd ($env.HOME | path join Library "Application Support"); [
  "claude-code/skill-index.md"
  ...(glob orca/claude-profiles/*/home/skill-index.md)
] | each {|f|
  open --raw $f | (str replace
    "- **Merge or rebase conflict**: `resolving-merge-conflicts`."
    "- **Merge or rebase conflict**: `git-workflow`."
  ) | save --force $f
} | ignore
```

Report the skill-index part as left for Patrick until Step 7 prints four lines
ending `0 1`.

- [ ] **Step 7: Verify every copy.**

```sh
cd "$HOME/Library/Application Support" || exit 1
for f in claude-code/skill-index.md \
  orca/claude-profiles/*/home/skill-index.md; do
  printf '%s %s %s\n' "$f" "$(grep -cF resolving-merge-conflicts "$f")" \
    "$(grep -cxF -e '- **Merge or rebase conflict**: `git-workflow`.' "$f")"
done
cmp claude-code/skill-index.md \
  orca/claude-profiles/083b30c5-b8df-48ec-96b3-d6f46b10a567/home/skill-index.md
for p in 776c09cc-1c3a-4c5b-a6ad-f3776aecae54 \
  82d551a4-557e-4810-83af-ccc43ec5461c; do
  diff claude-code/skill-index.md "orca/claude-profiles/$p/home/skill-index.md"
done
```

Expected: four lines, each ending `0 1`; `cmp` silent with exit 0; each `diff`
prints only the `34c34` hunk it printed before the edit (`GLOSSARY.md` in the
canonical file, `CONTEXT.md` in the copy).

- [ ] **Step 8: Run the suites.** `mise run test` and `mise run lint`, sandbox
      off. Expected: both pass.

- [ ] **Step 9: Evaluate against the real work layer.** Run the harness's
      real-work-layer command. Expected: one store path. `git-workflow` now
      joins the duplicate check, where only the real layer can show a work-layer
      `storeSkills` or `localSkills` entry of the same name; that fails with
      `claude-skills: more than one collection provides git-workflow`, which
      goes to Patrick.

- [ ] **Step 10: Commit the repository change only.**

```sh
git add modules/home/claude-skills/ecc-overlaps.nix
git -c commit.gpgsign=false commit \
  -m "feat(skills): link ECC's git-workflow again" \
  -m "ECC's git-workflow was left out as covered by resolving-merge-conflicts,
which mattpocock/skills removed in 1.3.0, so merge and rebase conflicts
had no skill at all. git-workflow covers merge versus rebase and
conflict resolution, and the skill index now routes conflicts to it."
```

After Patrick's switch: Xcode copies the plugin when it is imported, so
`git-workflow` reaches Xcode's agent only once `nix-agents` is re-imported with
"Add from file".

### Task C5.6: Every overlap names what covers it

**Files:**

- Modify: `modules/home/claude-code.nix` L131-136 (`enabledPluginKeys`, read
  only), L139-150 (options: add `my.claudeCode.enabledPlugins` after
  `my.mdLint.lineLengths`)
- Modify: `modules/home/claude-skills.nix` L82-92 (`eccOverlaps`, `eccKept`),
  L118-122 (`flatSkillSources`)
- Modify: `modules/home/claude-skills/ecc-overlaps.nix` L1-4 (header comment),
  L36 (`documentation-lookup`), L44 (`frontend-slides`)

**Interfaces:**

- Consumes: `skillEntries` (C5.3), `my.agentSkills.generatedSkills`.
- Produces:
  - `my.claudeCode.enabledPlugins`: `attrsOf bool`, `readOnly = true`, declared
    in `modules/home/claude-code.nix` with
    `default = enabledPluginKeys // { "nix-lsp@nix-config" = true; };`, keys
    `<plugin>@<marketplace>` as in settings.json's `enabledPlugins`. It is the
    one source of the enabled plugin set: the cover check here reads it, and
    C4.3's `my.mergedSettings.claude-code` entry sets
    `enabledPlugins = config.my.claudeCode.enabledPlugins;`. `settings.jq` and
    the `plugins` argument to `merge-settings.sh` are not touched; C4.3 deletes
    both.
  - The value shapes `ecc-overlaps.nix` accepts: a skill name in `skillEntries`;
    a `"<plugin>:<skill>"` string whose `<plugin>` is the part before `@` of a
    key set to `true` in `my.claudeCode.enabledPlugins`; or the external marker
    `{ external = "<what covers it>"; }` (an attribute set with exactly the one
    key, a non-empty string), written `<name>.external = "…";` so nixfmt keeps
    it on one line.
  - The assertion message, exactly the string this expression builds, all on one
    line:

```nix
"claude-skills: ecc-overlaps.nix names no linked skill, enabled plugin"
+ " or { external = \"...\"; } marker for: "
+ lib.concatStringsSep ", " uncoveredOverlaps
```

- [ ] **Step 1: Write the failing test for the plugin list.**

```sh
darwin='.#darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
nix eval --json --override-input work path:./stubs/work \
  "$hm.my.claudeCode.enabledPlugins" \
  | jq -c '[length, .["remember@claude-plugins-official"],
    .["nix-lsp@nix-config"]]'
nix eval --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux".config.my.claudeCode.enabledPlugins' \
  | jq length
```

Expected after the change: `[17,true,true]` and `17` (the 16 `officialPlugins`
plus `nix-lsp@nix-config`).

- [ ] **Step 2: Run it and see it fail** with `does not provide attribute`
      naming `…my.claudeCode.enabledPlugins`.

- [ ] **Step 3: Declare the option** in `claude-code.nix` as given under
      Interfaces (description: "The plugins Nix enables in Claude Code, keyed as
      settings.json's `enabledPlugins`."). Run Step 1 again: it prints
      `[17,true,true]` and `17`.

- [ ] **Step 4: Add the assertion.** In `claude-skills.nix`:
  - `eccOverlapTargets = import ./claude-skills/ecc-overlaps.nix;` and
    `eccOverlaps = lib.attrNames eccOverlapTargets;` in place of L84.
  - `enabledPluginNames`: the part before `@` of every key of
    `config.my.claudeCode.enabledPlugins` whose value is `true`.
  - `coversOverlap = target: bool`, true exactly for the three shapes under
    Interfaces, false for anything else (a list, a number, an empty or misspelt
    marker).
  - `uncoveredOverlaps`:

    ```nix
    uncoveredOverlaps = lib.attrNames (
      lib.filterAttrs (_: t: !coversOverlap t) eccOverlapTargets
    );
    ```

  - A second `assert lib.assertMsg (uncoveredOverlaps == [ ]) (…)` in
    `flatSkillSources`, after the duplicate one, with the message under
    Interfaces. It cannot sit in `eccKept`: ECC skills cover other ECC skills
    (`autonomous-loops = "continuous-agent-loop"`), so the linked names need
    `groupedSkills`, which needs `eccKept`.

- [ ] **Step 5: Run it and see it fail.** `mise run eval:darwin` fails with the
      message under Interfaces, ending
      `marker for: documentation-lookup, frontend-slides`. This one run rejects
      free text (`"the context7 MCP server"`) and a plugin that is not enabled
      (`anthropic-skills:pptx`), and accepts the 51 linked skill names and
      `remember:remember`.

- [ ] **Step 6: Mark one, misspell the other.** In `ecc-overlaps.nix` write
      `frontend-slides.external = "anthropic-skills:pptx";` and
      `documentation-lookup.external = "";`. Run `mise run eval:darwin`.
      Expected: fails with the same message ending
      `marker for: documentation-lookup`.

- [ ] **Step 7: Fix the marker.**
      `documentation-lookup.external = "the context7 MCP server";`. Rewrite the
      header comment (L1-4) to say each entry maps to what covers it: a skill
      `claude-skills.nix` links, a `plugin:skill` of a plugin `claude-code.nix`
      enables, or `<name>.external = "…";` for one provided outside this
      repository, and that evaluation fails on anything else; keep "Sorted
      alphabetically, as no reference order applies." Within 72 columns.

- [ ] **Step 8: Run it and see it pass.** `mise run test` passes. The overlaps
      file still satisfies the existing upstream check, because `eccMissing`
      reads only its attribute names.

- [ ] **Step 9: Run the suites.** `mise run lint`, sandbox off. Expected: passes
      (nixfmt keeps both `.external` lines on one line each).

- [ ] **Step 10: Evaluate against the real work layer.** Run the harness's
      real-work-layer command. Expected: one store path. The cover assertion
      reads `skillEntries`, the work layer's skills included, and the work layer
      must not already declare an option named `my.claudeCode.enabledPlugins`.

- [ ] **Step 11: Commit.**

```sh
git add modules/home/claude-code.nix modules/home/claude-skills.nix \
  modules/home/claude-skills/ecc-overlaps.nix
git -c commit.gpgsign=false commit \
  -m "feat(skills): check what ecc-overlaps.nix names" \
  -m "Each entry in ecc-overlaps.nix leaves an ECC skill out in favour of
another, but only the names were checked, so a cover that vanished
upstream or was never enabled left the skill unreachable in silence;
resolving-merge-conflicts was one. Evaluation now fails unless each
cover is a linked skill, a skill of a plugin claude-code.nix enables
(read from the new read-only my.claudeCode.enabledPlugins), or an
explicit external marker."
```

#### Notes for section C5

- The Spec names no option for the destination list, the subagent directories or
  the generated skills; `my.agentSkills.destinations`,
  `my.agentSkills.subagentDirs` and `my.agentSkills.generatedSkills` are this
  section's names. Nothing outside C5 reads them.
- C5.6's cover check proves that a named plugin is enabled, not that it ships
  the named skill (`remember:remember` is fetched by Claude Code at run time),
  and leaves `external` markers unchecked by design.
- The Spec does not say how commitlint's file link becomes a directory link.
  C5.4 Step 10 hands Patrick a pre-switch Nushell command, where card 4 uses an
  activation entry that a follow-up commit deletes; Patrick picks one pattern
  before C5.4 runs if he prefers card 4's.
- Xcode copies the `nix-agents` plugin when it is imported, so C5.4's commitlint
  directory, like C5.5's `git-workflow`, reaches Xcode's agent only after
  Patrick re-imports the plugin with "Add from file".
- From C5.2 on, Linux links none of the plugin's 474 files, but
  `pkgs/claude-marketplace` is still linked whole, so the Linux marketplace
  lists `nix-agents` as an empty plugin. C5.2's commit type stays `refactor`;
  its body says Linux loses the files.
- No GLOSSARY.md term is added, since the Spec names none for card 5; "Skill
  destination" is the candidate if Patrick wants one. C5.3's
  `docs/architecture.md` bullet documents the options.
- The expected store paths (the linkFarm `l7v6jg52…`, ECC `wk4q0dr2…`,
  commitlint `4vh941as…`) hold only while nixpkgs, ECC and the commitlint pin
  stay where they are at `a07c2f4`; the suffix checks are the real assertions.
- The real-work-layer steps prove only that the system evaluates with the work
  layer's directories and skills. What the switch does to them (C5.3's copies,
  C5.4's backups) shows only after Patrick's switch, through the Nushell checks
  after C5.3 and in C5.4 Step 10.

---

## Section C4: Claude Code on `my.mergedSettings`

Line numbers are those at a07c2f4. F, C1, C23 and C5 land first and shift them,
so find each region by the text quoted beside it. Every command runs from the
repository root with the Bash sandbox off. Shell variables do not carry over
between calls, so each block defines what it uses, and scratch directories have
fixed names under `$TMPDIR`. `jq` is `pkgs.jq` on PATH (`modules/home/jaq.nix`
installs it; only interactive Nushell aliases `jq` to jaq). New files are
`git add`-ed before any evaluation sees them. Every lint script only checks, so
fix formatting with the tools the checks use, for Nix, shell, JSON and Markdown
in that order:

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" <files>
"$(.github/scripts/nix-tool.sh shfmt)" --indent 2 --binary-next-line \
  --case-indent --write <files>
"$(.github/scripts/nix-tool.sh oxfmt)" -c modules/home/oxc/oxfmtrc.json <files>
"$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
  --prose-wrap=always --print-width=80 <files>
```

Two attribute paths recur. A command written for one home starts with its `h=`
line or lines; to run it on the other home, swap them for the other pair:

```sh
h='.#homeConfigurations."patrick@linux".config'
```

```sh
h='.#darwinConfigurations.Patricks-MacBook-Pro'
h="$h.config.home-manager.users.patrick"
```

**The real work layer.** Every stub eval hides the private work layer. C4.2 to
C4.5 change an option it uses (`my.mergedSettings`) or activation entries it
could order against, so each also evaluates the real configuration before its
commit, with no `--override-input`. The command prints only a store path or the
error, never a value from the work layer:

```sh
nix eval --raw \
  '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'
```

Expected: one store path named `darwin-system-<version>.drv`. On an error, stop,
change nothing further, and report the message to Patrick: the fix lives in his
work repository or in a module here, not in the check.

### Task C4.1: merge-json takes strategies at nested paths

**Files:**

- Create: seven fixture cases under `pkgs/merge-json/tests/`, each holding the
  files Step 1 shows for it:
  - `union-nested-keeps-app-group/`: `file.json`, `new.json`, `strategies.json`,
    `expected.json`
  - `union-nested-drops-undeclared-group/`: `file.json`, `old.json`, `new.json`,
    `strategies.json`, `expected.json`
  - `union-nested-adopts-identical-group/`: `file.json`, `new.json`,
    `strategies.json`, `expected.json`
  - `replace-nested-discards-app-additions/`: `file.json`, `old.json`,
    `new.json`, `strategies.json`, `expected.json`
  - `union-nested-creates-missing-parent/`: `file.json`, `new.json`,
    `strategies.json`, `expected.json`
  - `union-nested-parent-type-clash-skipped/`: `file.json`, `old.json`,
    `new.json`, `strategies.json`, `old-strategies.json` (no `expected.json`:
    skipped)
  - `union-nested-drops-key-and-strategy/`: `file.json`, `old.json`,
    `old-strategies.json`, `new.json`, `expected.json`
- Modify: `pkgs/merge-json/merge.jq` (header comment 1-7; new helpers after
  `prune`, 18-23; `merge_replace` 33-40; `merge_union` 45-67; main pipeline
  79-98)
- Modify: `pkgs/merge-json/merge-json.sh:8-11` (usage comment, "STRATEGIES maps
  a top-level key …")
- Modify: `pkgs/merge-json/test.sh:14` ("strategies.json the strategy per
  top-level key, if any")

**Interfaces:**

- Consumes: merge-json's arguments `NAME FILE DECLARED STATE [STRATEGIES]`,
  unchanged; the strategies state `${STATE%.json}.strategies.json`, unchanged.
- Produces: STRATEGIES (and its state) is a JSON tree in DECLARED's shape. A
  string leaf, `"replace"` or `"union"`, names the strategy for the key at its
  path. An object descends. A top-level `{ "packages": "union" }` means what it
  means today. C4.2's option and C4.3's entry rely on this.

- [ ] **Step 1: Write the seven fixture cases.** Write each file with the
      content shown, then format the 32 files with oxfmt. oxfmt's width is wider
      than these blocks, so it may join lines; `test.sh` compares JSON with its
      keys sorted, so only the content counts.

```sh
"$(.github/scripts/nix-tool.sh oxfmt)" -c modules/home/oxc/oxfmtrc.json \
  pkgs/merge-json/tests/union-nested-*/*.json \
  pkgs/merge-json/tests/replace-nested-*/*.json
```

`union-nested-keeps-app-group/`: an app's group in the same event list stays,
and a sibling event stays.

```json
// file.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "app-hook" }]
      }
    ],
    "Stop": [{ "hooks": [{ "type": "command", "command": "app-stop" }] }]
  },
  "theme": "dark"
}
// new.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "guard" }]
      }
    ]
  }
}
// strategies.json
{ "hooks": { "PreToolUse": "union" } }
// expected.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "app-hook" }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "guard" }]
      }
    ],
    "Stop": [{ "hooks": [{ "type": "command", "command": "app-stop" }] }]
  },
  "theme": "dark"
}
```

`union-nested-drops-undeclared-group/`: the group declared last time and not now
is taken back, and the app's group stays.

```json
// file.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "app-hook" }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "/old/bin/guard" }]
      }
    ]
  }
}
// old.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "/old/bin/guard" }]
      }
    ]
  }
}
// new.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "/new/bin/guard" }]
      }
    ]
  }
}
// strategies.json
{ "hooks": { "PreToolUse": "union" } }
// expected.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "app-hook" }]
      },
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "/new/bin/guard" }]
      }
    ]
  }
}
```

`union-nested-adopts-identical-group/`: no state yet. The file already holds a
group equal by value to the declared one, with its keys in another order. That
group is kept once, where it is.

```json
// file.json and expected.json (identical)
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "timeout": 10,
            "command": "tool hook session-start",
            "type": "command"
          }
        ]
      },
      { "hooks": [{ "type": "command", "command": "app-start" }] }
    ]
  }
}
// new.json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "tool hook session-start",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
// strategies.json
{ "hooks": { "SessionStart": "union" } }
```

`replace-nested-discards-app-additions/`: `replace` one level down. The app's
addition inside the replaced key goes, and the app's sibling key stays.

```json
// file.json
{
  "extraKnownMarketplaces": {
    "app-own": { "source": { "source": "github", "repo": "app/marketplace" } },
    "declared": {
      "autoUpdate": true,
      "source": { "source": "directory", "path": "/old" }
    }
  }
}
// old.json
{
  "extraKnownMarketplaces": {
    "declared": { "source": { "source": "directory", "path": "/old" } }
  }
}
// new.json
{
  "extraKnownMarketplaces": {
    "declared": { "source": { "source": "directory", "path": "/new" } }
  }
}
// strategies.json
{ "extraKnownMarketplaces": { "declared": "replace" } }
// expected.json
{
  "extraKnownMarketplaces": {
    "app-own": { "source": { "source": "github", "repo": "app/marketplace" } },
    "declared": { "source": { "source": "directory", "path": "/new" } }
  }
}
```

`union-nested-creates-missing-parent/`: the file has no `permissions`. The union
key and its deep-merged sibling are both written.

```json
// file.json
{ "theme": "dark" }
// new.json
{
  "permissions": {
    "defaultMode": "auto",
    "deny": ["Bash(security dump-keychain:*)"]
  }
}
// strategies.json
{ "permissions": { "deny": "union" } }
// expected.json
{
  "permissions": {
    "defaultMode": "auto",
    "deny": ["Bash(security dump-keychain:*)"]
  },
  "theme": "dark"
}
```

`union-nested-parent-type-clash-skipped/`: the strategy's parent is a string in
the file. The entry is skipped with a warning, and the file and both states are
left byte for byte.

```json
// file.json
{ "hooks": "disabled" }
// new.json and old.json (identical)
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "guard" }]
      }
    ]
  }
}
// strategies.json and old-strategies.json (identical)
{ "hooks": { "PreToolUse": "union" } }
```

`union-nested-drops-key-and-strategy/`: a nested key dropped together with its
strategy is still taken back by `union`.

```json
// file.json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "app-stop" }] },
      { "hooks": [{ "type": "command", "command": "tool hook stop" }] }
    ]
  }
}
// old.json
{
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command", "command": "tool hook stop" }] }]
  }
}
// old-strategies.json
{ "hooks": { "Stop": "union" } }
// new.json
{}
// expected.json
{
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command", "command": "app-stop" }] }]
  }
}
```

- [ ] **Step 2: Run the fixtures and watch six fail.**

```sh
git add pkgs/merge-json/tests && mise run check:merge-json
```

The build fails. Its log, each line prefixed with `merge-json-tests>` and a
space, holds 16 `ok` lines, these six `FAIL` lines, each preceded by its
`diff -u` hunk, and the summary line `6 case(s) failed`.
`ok union-nested-parent-type-clash-skipped` is among the 16: today's filter
rejects every nested strategy, so that case already passes. It guards against a
regression rather than driving the change.

```text
FAIL replace-nested-discards-app-additions: the file differs from expected.json
FAIL union-nested-adopts-identical-group: the state differs from new.json
FAIL union-nested-creates-missing-parent: the file differs from expected.json
FAIL union-nested-drops-key-and-strategy: the file differs from expected.json
FAIL union-nested-drops-undeclared-group: the file differs from expected.json
FAIL union-nested-keeps-app-group: the file differs from expected.json
6 case(s) failed
```

- [ ] **Step 3: Generalise `pkgs/merge-json/merge.jq` from keys to paths.**
      `leaves`, `prune`, `merge_default` and `without` stay as they are. Add
      these:
  - `def has_path($path):` is true when `.` holds a value at `$path`, reached
    through objects alone. A missing key or a non-object on the way gives false,
    never an error.
  - `def strategy_paths:` is
    `[paths(type == "string") as $path | [$path, getpath($path)]]`.
  - `def without_paths($paths):` deletes each path in `$paths` that `.` holds,
    then `prune`s the objects that leaves empty.
  - `merge_replace($path; $old; $new)` replaces `merge_replace($key; …)`. When
    `$new` has the path, it `setpath`s the declared value. When `$old` and the
    file both have it, it `delpaths`. Otherwise it leaves `.` alone. It does not
    prune.
  - `merge_union($path; $old; $new)` replaces `merge_union($key; …)`. The same
    rules use `has_path`, `getpath` and `setpath`. Error texts name
    `$path | join(".")` where they named `$key`. A parent that is not an object
    in the file makes `setpath` fail, which skips the entry (fixture 6).
  - The main pipeline keeps the old strategies only for paths the new
    declaration lacks and no current strategy names. It default-merges with
    every strategy path removed from both declarations, then applies each
    strategy:

```jq
| (($strategies[0] // {}) | strategy_paths) as $current
| (
    (($oldStrategies[0] // {}) | strategy_paths
      | map(select(.[0] as $path
          | ($new | has_path($path) | not)
            and all($current[]; .[0] != $path))))
    + $current
  ) as $strategies
| ($strategies | map(.[0])) as $paths
| merge_default($old | without_paths($paths); $new | without_paths($paths))
| reduce $strategies[] as [$path, $strategy] ( … same dispatch,
    error("\($path | join(".")) has no strategy \($strategy)") … )
```

Header comment, replacing lines 1-7:

```jq
# `.` is the array of JSON values in the app's file; $old[0] is what
# was declared last time, $new[0] what is declared now, and
# $oldStrategies[0] and $strategies[0] are the strategies last time
# and now, in the declared value's shape: a string names "replace" or
# "union" for the key at its path. Every other key is merged by
# default: a leaf declared before and not now is removed, along with
# any object that removal leaves empty, then the declaration is merged
# over what is left.
```

The two new helpers take these comments:

```jq
# Whether `.` holds a value at $path, reached through objects alone.
def has_path($path):
```

```jq
# Deletes each of $paths that `.` holds, with any object that leaves
# empty.
def without_paths($paths):
```

In `merge_union`'s comment, "under $key" becomes "at $path". Above the strategy
combination, the comment reads:

```jq
# A key no longer declared is taken back by the strategy it had, unless
# one is declared for its path now.
```

- [ ] **Step 4: Update the two usage comments.** `merge-json.sh:8-11` becomes:

```bash
# STRATEGIES names "replace" or "union" for a key at any depth, in
# DECLARED's shape; every other key is deep-merged. They are recorded
# beside STATE, its .json suffix replaced by .strategies.json, so a
# key no longer declared is taken back by the strategy it had.
```

`test.sh:14` becomes this line, which keeps the column alignment:

```bash
#   strategies.json      the strategies, in new.json's shape, if any
```

- [ ] **Step 5: Run the fixtures and watch all 22 pass.**
      `mise run check:merge-json` exits 0. The 15 existing cases are unchanged
      and pass with the 7 new ones.
- [ ] **Step 6: Run the suites.** `mise run test` and `mise run lint` both pass.
- [ ] **Step 7: Commit.**

```sh
git add pkgs/merge-json
git -c commit.gpgsign=false commit \
  -m "feat(merge-json): take strategies at nested paths" \
  -m "Claude Code's settings hold Orca's agent-hook groups and Nix's in the
same per-event lists under hooks, so a strategy has to reach one list
inside an object rather than a whole top-level key. Strategies take
the declared value's own shape, a string naming the strategy at its
path, and their state is recorded the same way, so a nested key
dropped with its strategy is still taken back by it. Top-level
strategies mean what they meant."
```

### Task C4.2: `my.mergedSettings` strategies nest in the value's shape

**Files:**

- Modify: `modules/home/merged-settings.nix`. Add `strategyTree` to the let
  block (8-45). Rewrite the union assertion (39-45), the `example` (50-58), the
  option `description` (59-67), and the `strategies` type and description
  (79-95).
- Modify: `docs/adr/0012-app-owned-json-merged-with-state-tracked-removal.md`,
  lines 12-13 ("Every other key is deep-merged.")
- Modify: `docs/architecture.md:75-76` ("a strategy for any top-level key that
  is not deep-merged")

**Interfaces:**

- Consumes: C4.1's STRATEGIES tree format.
- Produces: `my.mergedSettings.<name>.strategies` is a nested attribute set. A
  string leaf is `"replace"` or `"union"`, and an attribute set descends:
  `strategies.hooks.PreToolUse = "union";`. The name and the top-level spelling
  the work layer uses are unchanged. The assertion message is
  `my.mergedSettings.<name>.value.<lib.showAttrPath path>` followed by
  `is merged by union, so it must be a list`.

- [ ] **Step 1: Write the failing evaluation.** It keeps nix's output in a log
      that the later steps read.

```sh
nix eval --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux"' --apply '
c:
(c.extendModules {
  modules = [
    {
      my.mergedSettings.probe = {
        file = "/tmp/probe.json";
        value.hooks.Stop = "x";
        strategies.hooks.Stop = "union";
      };
    }
  ];
}).activationPackage.drvPath' >"${TMPDIR%/}/c4-probe.log" 2>&1
```

- [ ] **Step 2: Run it and watch it fail on the type.** Today the log holds
      nix's error that the definition for option
      `my.mergedSettings.probe.strategies.hooks` is not of type
      `` `one of "replace", "union"' ``. This prints `1` (each `.` in the
      pattern stands for one of nix's quote characters):

```sh
grep -c 'probe.strategies.hooks. is not of type .one of "replace", "union".' \
  "${TMPDIR%/}/c4-probe.log"
```

- [ ] **Step 3: Implement.** Add to the let block:

```nix
  # Recursive, so its description is given: one derived from the
  # type itself would never finish.
  strategyTree =
    lib.types.attrsOf (
      lib.types.either (lib.types.enum [
        "replace"
        "union"
      ]) strategyTree
    )
    // {
      description = "attribute set of strategies, nested in the value's shape";
    };
```

Set the `strategies` option's `type = strategyTree;`. Its description becomes:
"How a key is merged when not deep-merged, in the value's own shape: a string
names the strategy for the key at its path, an attribute set descends into the
object there." The `replace`, `union` and dropped-key sentences stay as they
are. In the top-level description, "A top-level key is deep-merged unless
`strategies` names it" becomes "A key is deep-merged unless `strategies` names
it". The example gains `value.hooks.onSave = [ "format" ];` and
`strategies.hooks.onSave = "union";`. The assertion becomes:

```nix
    ++ lib.mapAttrsToListRecursive (path: strategy: {
      assertion =
        strategy != "union"
        || !(lib.hasAttrByPath path entry.value)
        || builtins.isList (lib.getAttrFromPath path entry.value);
      message =
        "my.mergedSettings.${name}.value.${lib.showAttrPath path}"
        + " is merged by union, so it must be a list";
    }) entry.strategies;
```

Then format `modules/home/merged-settings.nix` with nixfmt.

- [ ] **Step 4: Run Step 1 again and watch the assertion fire.** This prints
      `2`, one line each for `Failed assertions:` and the message:

```sh
m='- my.mergedSettings.probe.value.hooks.Stop'
m="$m is merged by union, so it must be a list"
grep -cF -e 'Failed assertions:' -e "$m" "${TMPDIR%/}/c4-probe.log"
```

- [ ] **Step 5: Check that a valid nested strategy evaluates and that the
      top-level message is unchanged.** The first command prints
      `{"hooks":{"Stop":"union"}}`:

```sh
nix eval --json --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux"' --apply '
c:
(c.extendModules {
  modules = [
    {
      my.mergedSettings.probe = {
        file = "/tmp/probe.json";
        value.hooks.Stop = [ ];
        strategies.hooks.Stop = "union";
      };
    }
  ];
}).config.my.mergedSettings.probe.strategies'
```

Then Step 1's command with a top-level pair in place of the hooks pair fails,
and the last command below prints `1`:

```sh
nix eval --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux"' --apply '
c:
(c.extendModules {
  modules = [
    {
      my.mergedSettings.probe = {
        file = "/tmp/probe.json";
        value.packages = "x";
        strategies.packages = "union";
      };
    }
  ];
}).activationPackage.drvPath' >"${TMPDIR%/}/c4-probe.log" 2>&1
m='- my.mergedSettings.probe.value.packages'
m="$m is merged by union, so it must be a list"
grep -cF -- "$m" "${TMPDIR%/}/c4-probe.log"
```

- [ ] **Step 6: Update the documents.** In ADR-0012, insert this sentence after
      "Every other key is deep-merged." and leave the rest of the paragraph as
      it is: "A strategy sits at any depth, spelled in the value's own shape, so
      one list inside an object both sides write is merged on its own while its
      siblings are deep-merged." In `docs/architecture.md`, "a strategy for any
      top-level key that is not deep-merged" becomes "a strategy for any key, at
      any depth, that is not deep-merged". Then run:

```sh
"$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
  --prose-wrap=always --print-width=80 \
  docs/adr/0012-app-owned-json-merged-with-state-tracked-removal.md \
  docs/architecture.md
```

The architecture bullet then reads:

```markdown
- Apps that rewrite their own settings file (Claude Code, Claude desktop, Zed)
  get no link; their keys are merged or rendered by an activation entry after
  `writeBoundary`. Claude desktop's JSON is merged through `my.mergedSettings`
  (`modules/home/merged-settings.nix`), where new app-owned JSON goes too: an
  entry names the file, its declared value and a strategy for any key, at any
  depth, that is not deep-merged (`replace` or `union`), and what it stops
  declaring is taken back at the next switch (ADR-0012). Claude Code's
  `settings.json` keeps its own entry, `claudePluginSettings`, and Zed's is
  rendered with its token.
```

and the ADR's first paragraph reads, from its seventh line (its first six are
unchanged):

```markdown
key. Some are Nix's whole, such as an MCP server set where a server added in the
app must not stay; they take `replace`. Some are lists both sides add to, such
as an agent's packages; they take `union`, compared by value. Every other key is
deep-merged. A strategy sits at any depth, spelled in the value's own shape, so
one list inside an object both sides write is merged on its own while its
siblings are deep-merged. The strategies are kept as state too, so a key dropped
together with its strategy is still taken back the way it was merged. A file
that is not valid JSON, or that the app has reshaped so the merge fails, is left
as it is, state included, with a warning naming the entry: one broken file must
not stop the activation. The work layer's apps belong on the same option.
```

- [ ] **Step 7: Run the suites.** `mise run test`, `mise run check:merge-json`
      and `mise run lint` all pass.
- [ ] **Step 8: Evaluate against the real work layer.** Run the section's
      real-work-layer command; it prints one `.drv` path. Any strategy the work
      layer declares is spelled at the top level, a string leaf `strategyTree`
      still accepts.
- [ ] **Step 9: Commit.**

```sh
git add modules/home/merged-settings.nix docs/architecture.md \
  docs/adr/0012-app-owned-json-merged-with-state-tracked-removal.md
git -c commit.gpgsign=false commit \
  -m "feat(merged-settings): nest strategies by path" \
  -m "merge-json takes strategies at nested paths, so the option accepts
them in the value's own shape: a string leaf names the strategy, an
attribute set descends, and the union-must-be-a-list assertion checks
each path. A top-level strategy, the spelling the work layer uses, is
unchanged."
```

### Task C4.3: Claude Code's settings join `my.mergedSettings`

**Files:**

- Modify: `modules/home/claude-code.nix`. Rewrite the last paragraph of the
  comment above `officialPlugins` (109-111, from "The whole of the official
  marketplace is managed here: settings.jq disables"). Add `hookEvents` to the
  let block after `enabledPluginKeys` (131-136). Replace 195-224 (from
  "settings.json is Claude Code's own" through the closing `);` of
  `home.activation.claudePluginSettings`) with the entry, the assertion and the
  migration entry.
- Create: `modules/home/claude-code/migrate-hooks.jq`,
  `modules/home/claude-code/migrate-hooks.sh`
- Delete: `modules/home/claude-code/settings.jq`,
  `modules/home/claude-code/merge-settings.sh`
- Modify: `modules/home/jouet.nix:20-26`. The writer now orders after
  `mergedSettings`, and the comment "After claudePluginSettings, which rewrites
  the same file." changes to match.
- Modify: `modules/home/darwin/rex.nix:54-56`. The writer orders after
  `[ "writeBoundary" "mergedSettings" ]`.
- Modify: `docs/architecture.md:71-78` (the bullet as C4.2 left it)
- Modify: `docs/adr/0012-app-owned-json-merged-with-state-tracked-removal.md`.
  Add a new paragraph before "The costs:" and two cost bullets.
- Modify, only if the spellchecker flags a word in the new comments:
  `codebook.toml`

**Interfaces:**

- Consumes: C4.1 and C4.2. `config.my.claudeCode.enabledPlugins` (C5.6's
  read-only option, the one source of the enabled-plugin set).
  `config.xdg.configHome`, `config.xdg.stateHome`, and the `mergedSettings`
  activation entry and its state path
  `${config.xdg.stateHome}/nix-config/<name>.json` (merged-settings.nix:18). The
  `claudeVcsGuard`, `claudeMdLint` and `claudeStatusline` bindings.
- Produces:
  - `my.mergedSettings.claude-code.file` is
    `"${config.xdg.configHome}/claude-code/settings.json"`.
  - `my.mergedSettings.claude-code.value.enabledPlugins` is
    `config.my.claudeCode.enabledPlugins`.
  - `strategies.hooks.<each of 33 events> = "union"` and
    `strategies.permissions.deny = "union"`.
  - Any module adds agent-hook groups to
    `my.mergedSettings.claude-code.value.hooks.<Event>`, a list of
    `{ matcher?; hooks = [ { type; command; timeout?; } ]; }` (C4.4 relies on
    this).
  - Assertion message: `my.mergedSettings.claude-code.value.hooks.<Event>`
    followed by `is not a Claude Code hook event`.
  - Activation entry `claudeCodeHookMigration`, which is temporary and deleted
    by C4.5.
  - `claudePluginSettings` no longer exists. Anything that ordered after it
    orders after `mergedSettings`.

- [ ] **Step 1: Write the failing evaluation of the entry.**

```sh
h='.#homeConfigurations."patrick@linux".config'
nix eval --json --override-input work path:./stubs/work \
  "$h.my.mergedSettings.claude-code" --apply '
e: {
  deny = e.strategies.permissions.deny;
  events = builtins.length (builtins.attrNames e.strategies.hooks);
  hooks = builtins.mapAttrs (_: builtins.length) e.value.hooks;
  keys = builtins.attrNames e.value;
  plugins = builtins.length (builtins.attrNames e.value.enabledPlugins);
}' | jq .
```

- [ ] **Step 2: Run it and watch it fail.** It fails with an `error: flake` line
      saying the flake `does not provide attribute`, and the last attribute path
      the error names is
      `'homeConfigurations.patrick@linux.config.my.mergedSettings.claude-code'`.
      Today the Linux home has no entry at all, and the darwin home only
      `claude-desktop`.
- [ ] **Step 3: Declare the entry in `claude-code.nix`.** Add the events list to
      the let block. It holds the 33 names in the order of the hooks reference's
      lifecycle table; nixfmt puts one per line:

```nix
  # The events Claude Code runs agent hooks on, in the order of the
  # lifecycle table in https://code.claude.com/docs/en/hooks
  hookEvents = [
    "SessionStart" "Setup" "UserPromptSubmit" "UserPromptExpansion"
    "PreToolUse" "PermissionRequest" "PermissionDenied" "PostToolUse"
    "PostToolUseFailure" "PostToolBatch" "Notification" "MessageDisplay"
    "SubagentStart" "SubagentStop" "TaskCreated" "TaskCompleted" "Stop"
    "StopFailure" "TeammateIdle" "InstructionsLoaded" "ConfigChange"
    "CwdChanged" "DirectoryAdded" "FileChanged" "WorktreeCreate"
    "WorktreeRemove" "PreCompact" "PostCompact" "PreModelSwitch"
    "PostModelSwitch" "Elicitation" "ElicitationResult" "SessionEnd"
  ];
```

Replace the last paragraph of the comment above `officialPlugins` (109-111)
with:

```nix
  # These plugins reach Claude Code's enabledPlugins through
  # my.claudeCode.enabledPlugins: one dropped from this list is taken
  # back out at the next switch, and one enabled by hand stays.
```

In `config`, replace lines 195-224 with the entry below. The values are exactly
those of `settings.jq`; `enabledPlugins` is C5.6's option, so the cover check
and Claude Code read one set. The value's keys are alphabetical, the order of
Claude Code's settings reference, and formats.json sorts them either way.

```nix
    # Claude Code rewrites settings.json itself -- `theme`, `tui`,
    # Orca's agent hooks -- so the declared keys are merged in, and
    # every hook event takes `union` to keep the groups Orca adds.
    #
    # Two of the keys only stick at user scope. `permissions.defaultMode
    # = "auto"` is source-restricted, so a project or local scope
    # setting any other value overrides it; `remoteControlAtStartup` is
    # ignored outright from those scopes.
    #
    # `outputStyle` takes one of Concise, Proactive, Explanatory or
    # Learning, with the leading capital -- another name is not an
    # error, it simply does not apply. `voiceEnabled` is read as
    # `voice?.enabled ?? voiceEnabled`, so the nested object Claude Code
    # writes itself wins and only the flag is declared.
    #
    # Claude Code's settings reference lists its keys alphabetically;
    # formats.json sorts them either way.
    my.mergedSettings.claude-code = {
      file = "${config.xdg.configHome}/claude-code/settings.json";
      value = {
        enabledPlugins = config.my.claudeCode.enabledPlugins;
        extraKnownMarketplaces.nix-config.source = {
          source = "directory";
          path = "${config.xdg.configHome}/claude-marketplace";
        };
        hooks = {
          PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "${claudeVcsGuard}/bin/claude-vcs-guard";
                  timeout = 5;
                }
              ];
            }
          ];
          PostToolUse = [
            {
              matcher = "Write|Edit";
              hooks = [
                {
                  type = "command";
                  command = "${claudeMdLint}/bin/claude-md-lint";
                }
              ];
            }
          ];
        };
        outputStyle = "Concise";
        permissions = {
          defaultMode = "auto";
          deny = [
            "Bash(security find-generic-password:*)"
            "Bash(security find-internet-password:*)"
            "Bash(security dump-keychain:*)"
            "Bash(/usr/bin/security find-generic-password:*)"
            "Bash(/usr/bin/security find-internet-password:*)"
            "Bash(/usr/bin/security dump-keychain:*)"
          ];
        };
        remoteControlAtStartup = true;
        sandbox.enabled = true;
        statusLine = {
          type = "command";
          command = "${claudeStatusline}/bin/claude-statusline";
          padding = 0;
        };
        syncClaudeAiPlugins = false;
        voiceEnabled = true;
      };
      strategies = {
        hooks = lib.genAttrs hookEvents (_: "union");
        permissions.deny = "union";
      };
    };
```

Keep the hook commands in the `"${drv}/bin/<name>"` form; the migration
(Step 12) matches on that suffix.

- [ ] **Step 4: Run Step 1 again and watch it pass.** It prints the block below.
      Run it on the darwin home as well; it prints the same.

```text
{
  "deny": "union",
  "events": 33,
  "hooks": {
    "PostToolUse": 1,
    "PreToolUse": 1
  },
  "keys": [
    "enabledPlugins",
    "extraKnownMarketplaces",
    "hooks",
    "outputStyle",
    "permissions",
    "remoteControlAtStartup",
    "sandbox",
    "statusLine",
    "syncClaudeAiPlugins",
    "voiceEnabled"
  ],
  "plugins": 17
}
```

Then check the one source of the plugin set; it prints `true`:

```sh
nix eval --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux".config' --apply '
c:
c.my.mergedSettings.claude-code.value.enabledPlugins
== c.my.claudeCode.enabledPlugins'
```

- [ ] **Step 5: Write the event-name test.** It keeps nix's output in a log.

```sh
nix eval --override-input work path:./stubs/work \
  '.#homeConfigurations."patrick@linux"' --apply '
c:
(c.extendModules {
  modules = [ { my.mergedSettings.claude-code.value.hooks.PreToolUSe = [ ]; } ];
}).activationPackage.drvPath' >"${TMPDIR%/}/c4-events.log" 2>&1
```

- [ ] **Step 6: Run it and watch it pass evaluation, which is the failure.**
      `tail -n 1 "${TMPDIR%/}/c4-events.log"` prints a
      `"/nix/store/…-home-manager-generation.drv"` path.
- [ ] **Step 7: Add the assertion to `claude-code.nix`'s `config`.** `config`
      has no `assertions` attribute yet: C23.4's missing-`config` check is an
      inline `assert lib.assertMsg`, not a module assertion. So this is a new
      attribute, not a second definition:

```nix
    assertions = map (event: {
      assertion = lib.elem event hookEvents;
      message =
        "my.mergedSettings.claude-code.value.hooks.${event}"
        + " is not a Claude Code hook event";
    }) (builtins.attrNames config.my.mergedSettings.claude-code.value.hooks);
```

- [ ] **Step 8: Run Step 5 again and watch the assertion fire.** This prints
      `2`, one line each for `Failed assertions:` and the message:

```sh
m='- my.mergedSettings.claude-code.value.hooks.PreToolUSe'
m="$m is not a Claude Code hook event"
grep -cF -e 'Failed assertions:' -e "$m" "${TMPDIR%/}/c4-events.log"
```

- [ ] **Step 9: Check the list against the installed Claude Code.** This command
      prints nothing; at Claude Code 2.1.318 the binary's list is exactly these
      33 names:

```sh
bin="$(dirname "$(readlink -f "$(command -v claude)")")/.claude-wrapped"
h='.#homeConfigurations."patrick@linux".config'
/usr/bin/diff \
  <(strings -n 6 "$bin" \
    | grep -o '"PreToolUse","PostToolUse","PostToolUseFailure"[^]]*' \
    | head -n 1 | tr ',' '\n' | tr -d '"' | sort) \
  <(nix eval --json --override-input work path:./stubs/work \
    "$h.my.mergedSettings.claude-code.strategies.hooks" \
    --apply builtins.attrNames | jq -r '.[]' | sort)
```

- [ ] **Step 10: Write the migration filter's test.** The filter does not exist
      yet. The test input takes jouet's and rex's `SessionStart` groups from the
      files their writers read, so it holds their commands verbatim:

```sh
t="${TMPDIR%/}/c4-migrate-hooks"
rm -rf "$t" && mkdir -p "$t"
jouet=$(jq -c '.SessionStart[0]' modules/home/jouet/claude-hooks.json)
rex=$(echo '{}' | jq -c --from-file modules/home/darwin/rex/claude-hook.jq \
  | jq -c '.hooks.SessionStart[0]')
jq -n --argjson jouet "$jouet" --argjson rex "$rex" '{
  "theme": "custom:dracula-pro",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "orca-hook pre", "timeout": 10 }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/nix/store/x-claude-vcs-guard/bin/claude-vcs-guard",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/nix/store/y-claude-md-lint/bin/claude-md-lint"
          }
        ]
      }
    ],
    "SessionStart": [$jouet, $rex]
  }
}' >"$t/in.json"
```

The test is these two commands:

```sh
t="${TMPDIR%/}/c4-migrate-hooks"
jq --from-file modules/home/claude-code/migrate-hooks.jq "$t/in.json"
echo '{"theme":"dark"}' \
  | jq -c --from-file modules/home/claude-code/migrate-hooks.jq
```

The first must print the block below, and the second `{"theme":"dark"}`:

```text
{
  "theme": "custom:dracula-pro",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "orca-hook pre",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [],
    "SessionStart": []
  }
}
```

- [ ] **Step 11: Run it and watch it fail.** Both commands fail with
      `jq: Could not open modules/home/claude-code/migrate-hooks.jq:` followed
      by `No such file or directory`.
- [ ] **Step 12: Write `modules/home/claude-code/migrate-hooks.jq`.** It matches
      the four fingerprints the Spec names, exactly, and Step 10's two commands
      then print the expected values:

```jq
# Removes every agent-hook group that runs one of the commands this
# repository's modules declare.
def declared_here:
  (.command? // "") as $command
  | ($command | endswith("/bin/claude-vcs-guard"))
    or ($command | endswith("/bin/claude-md-lint"))
    or ($command | contains("jouet hook claude "))
    or ($command | contains("rex __internal session-start"));

if .hooks then
  .hooks |= map_values(map(select(any(.hooks[]?; declared_here) | not)))
else
  .
end
```

- [ ] **Step 13: Test the activation snippet before writing it.** Render the
      snippet into the test directory and wrap it with a stand-in for
      home-manager's `run`. The `sed` fails while the file is missing.

```sh
t="${TMPDIR%/}/c4-migrate-hooks"
f="$PWD/modules/home/claude-code/migrate-hooks.jq"
sed -e "s|@settings@|\"$t/settings.json\"|" \
  -e "s|@state@|\"$t/state.json\"|" -e "s|@jq@|jq|" -e "s|@filter@|$f|" \
  modules/home/claude-code/migrate-hooks.sh >"$t/snippet.sh"
printf '%s\n' 'run() { "$@"; }' ". $t/snippet.sh" >"$t/activate.sh"
```

Once it exists, the three scenarios below must hold. First, with no state yet,
the snippet migrates the file, and this prints Step 10's expected block:

```sh
t="${TMPDIR%/}/c4-migrate-hooks"
rm -f "$t/state.json" && cp "$t/in.json" "$t/settings.json"
bash "$t/activate.sh" && jq . "$t/settings.json"
```

Second, with state, the file is left as it is, and this prints `unchanged`:

```sh
t="${TMPDIR%/}/c4-migrate-hooks"
cp "$t/in.json" "$t/settings.json" && touch "$t/state.json"
bash "$t/activate.sh" && cmp "$t/in.json" "$t/settings.json" && echo unchanged
```

Third, a file jq cannot read is left as it is, with a warning:

```sh
t="${TMPDIR%/}/c4-migrate-hooks"
rm -f "$t/state.json" && printf '{' >"$t/settings.json"
bash "$t/activate.sh"; cat "$t/settings.json"; echo; ls "$t"
```

Its stderr ends `claude-code: <t>/settings.json not migrated`, `cat` prints `{`,
and `ls` lists `activate.sh`, `in.json`, `settings.json` and `snippet.sh`, with
no `settings.json.tmp`.

- [ ] **Step 14: Write `modules/home/claude-code/migrate-hooks.sh`.**

```bash
# shellcheck shell=bash

# A subshell keeps these variables out of the rest of the activation
# script.
(
  settings=@settings@
  state=@state@
  if [ ! -e "$state" ] && [ -s "$settings" ]; then
    if @jq@ --from-file @filter@ "$settings" >"$settings.tmp"; then
      run mv -f "$settings.tmp" "$settings"
    else
      echo "claude-code: $settings not migrated" >&2
    fi
    rm -f "$settings.tmp"
  fi
)
```

Wire it into `claude-code.nix`:

```nix
    # With no state yet the merge cannot tell this repository's
    # agent-hook groups from Orca's, so before the first merge every
    # group running one of this repository's hook commands is removed
    # rather than kept as a stale copy beside the declared one.
    home.activation.claudeCodeHookMigration =
      let
        settingsFile = config.my.mergedSettings.claude-code.file;
        stateFile = "${config.xdg.stateHome}/nix-config/claude-code.json";
      in
      lib.hm.dag.entryBetween [ "mergedSettings" ] [ "writeBoundary" ] (
        substituteFile ./claude-code/migrate-hooks.sh {
          settings = lib.escapeShellArg settingsFile;
          state = lib.escapeShellArg stateFile;
          jq = lib.getExe pkgs.jq;
          filter = "${./claude-code/migrate-hooks.jq}";
        }
      );
```

Re-run Step 13: the render, then the three scenarios. They hold. Then remove the
test directory and add both files, so Step 15's evaluation sees them:

```sh
rm -r "${TMPDIR%/}/c4-migrate-hooks"
git add modules/home/claude-code/migrate-hooks.jq \
  modules/home/claude-code/migrate-hooks.sh
```

- [ ] **Step 15: Delete the old writer and order the remaining two after the
      merge.**

```sh
git rm modules/home/claude-code/settings.jq \
  modules/home/claude-code/merge-settings.sh
```

In `jouet.nix`, `"claudePluginSettings"` becomes `"mergedSettings"`, and the
comment reads `# After mergedSettings, which rewrites the same file.` In
`darwin/rex.nix`, `entryAfter [ "claudePluginSettings" ]` becomes
`entryAfter [ "writeBoundary" "mergedSettings" ]`, and the comment above it
reads:

```nix
  # The other half of `rex skill setup`, merged after mergedSettings
  # because both rewrite the same file.
```

Format `claude-code.nix`, `jouet.nix` and `darwin/rex.nix` with nixfmt and
`migrate-hooks.sh` with shfmt. Then check the order:

```sh
h='.#darwinConfigurations.Patricks-MacBook-Pro'
h="$h.config.home-manager.users.patrick"
nix eval --json --override-input work path:./stubs/work "$h.home.activation" \
  --apply '
a:
builtins.mapAttrs (_: e: { inherit (e) after before; }) {
  inherit (a) claudeCodeHookMigration jouetClaudeHooks rexClaudeHook;
}' | jq -r 'to_entries[] | "\(.key) \(.value.after) \(.value.before)"'
```

It prints:

```text
claudeCodeHookMigration ["writeBoundary"] ["mergedSettings"]
jouetClaudeHooks ["writeBoundary","mergedSettings"] []
rexClaudeHook ["writeBoundary","mergedSettings"] []
```

Without this, rex's writer is unordered: it can run before the migration and
lose its group for one switch.

- [ ] **Step 16: Simulate Patrick's first switch on a copy, without writing his
      file.** This stands in for the activation no evaluation runs. The jouet
      and rex filters stand in for the two writers that still run after the
      merge: they are the pipeline that starts `jq --slurpfile jouet` and writes
      `$w/after.json`. The comparison of the other keys prints key paths only,
      never values, and skips `.env`. Run the whole block as one command:

```sh
w="${TMPDIR%/}/c4-claude-code-switch"
rm -rf "$w" && mkdir -p "$w"
h='.#darwinConfigurations.Patricks-MacBook-Pro'
h="$h.config.home-manager.users.patrick.my.mergedSettings.claude-code"
nix eval --json --override-input work path:./stubs/work "$h.value" \
  >"$w/declared.json"
nix eval --json --override-input work path:./stubs/work "$h.strategies" \
  >"$w/strategies.json"
echo '{}' >"$w/empty.json"
s="$HOME/Library/Application Support/claude-code/settings.json"
jq --from-file modules/home/claude-code/migrate-hooks.jq "$s" \
  | jq --slurp --slurpfile old "$w/empty.json" \
    --slurpfile new "$w/declared.json" \
    --slurpfile strategies "$w/strategies.json" \
    --slurpfile oldStrategies "$w/empty.json" \
    --from-file pkgs/merge-json/merge.jq >"$w/merged.json"
jq --slurpfile jouet modules/home/jouet/claude-hooks.json \
  --from-file modules/home/jouet/claude-hooks.jq "$w/merged.json" \
  | jq --from-file modules/home/darwin/rex/claude-hook.jq >"$w/after.json"
jq -r '
  .hooks | to_entries[]
  | .key + ": " + (.value | map(
      .hooks[0].command? // ""
      | if endswith("/bin/claude-vcs-guard") then "vcs-guard"
        elif endswith("/bin/claude-md-lint") then "md-lint"
        elif contains("jouet hook claude ") then "jouet"
        elif contains("rex __internal session-start") then "rex"
        else "app" end
    ) | join(" "))' "$w/after.json"
jq -cn --slurpfile a "$s" --slurpfile b "$w/merged.json" '
  def leaves:
    if type == "object"
    then [to_entries[] | .key as $k | .value | leaves[] | [$k] + .]
    else [[]] end;
  ($a[0] | del(.hooks, .env)) as $x
  | ($b[0] | del(.hooks, .env)) as $y
  | [(($x | leaves) + ($y | leaves) | unique)[]
      | select(. as $p
          | (try ($x | getpath($p)) catch null)
            != (try ($y | getpath($p)) catch null))
      | join(".")]'
jq --slurp --slurpfile old "$w/declared.json" \
  --slurpfile new "$w/declared.json" \
  --slurpfile strategies "$w/strategies.json" \
  --slurpfile oldStrategies "$w/strategies.json" \
  --from-file pkgs/merge-json/merge.jq "$w/merged.json" \
  | jq -S . | cmp - <(jq -S . "$w/merged.json") && echo idempotent
rm -r "$w"
```

The rule is that every event keeps its `app` (Orca) groups and each Nix group
appears exactly once. Against the live file of 2026-11-13, the classification
prints:

```text
PostToolUse: app md-lint jouet jouet
SessionStart: app jouet rex
UserPromptSubmit: app
Stop: app jouet
StopFailure: app
SubagentStart: app
SubagentStop: app
TeammateIdle: app
PreToolUse: app vcs-guard jouet
PostToolUseFailure: app jouet
PermissionRequest: app
PostCompact: app
Elicitation: app
ElicitationResult: app
SessionEnd: app
PostToolBatch: app
```

The comparison prints `[]`, or a short list of paths whose values the generation
Patrick last switched to set differently; `statusLine.command`, after a change
in the statusline's store path, is the usual one. Any other path is a key the
merge changes and must be explained before going on. The last command prints
`idempotent`.

- [ ] **Step 17: Update the documents.** The `docs/architecture.md` bullet
      becomes:

```markdown
- Apps that rewrite their own settings file (Claude Code, Claude desktop, Zed)
  get no link; their keys are merged or rendered by an activation entry after
  `writeBoundary`. Claude Code's and Claude desktop's JSON is merged through
  `my.mergedSettings` (`modules/home/merged-settings.nix`), where new app-owned
  JSON goes too: an entry names the file, its declared value and a strategy for
  any key, at any depth, that is not deep-merged (`replace` or `union`), and
  what it stops declaring is taken back at the next switch (ADR-0012). Zed's is
  rendered with its token.
```

ADR-0012 gains this paragraph before "The costs:":

```markdown
Claude Code's `settings.json` is one entry. Orca adds its own agent-hook groups
to the same per-event lists at run time and removes only those, so every
`hooks.<Event>` takes `union`. Claude Code's schema allows no key a group could
name its owner in, so the state is what tells Nix's groups from Orca's. An event
name Claude Code does not know fails evaluation, because Claude Code only warns
about one and never runs its hooks.
```

It also gains these two cost bullets:

```markdown
- A group an app writes identical to a declared one is adopted at the first
  merge, and taken back with it once Nix stops declaring it.
- Claude Code's hook events are listed in `claude-code.nix`, so an event added
  upstream fails evaluation until the list has it.
```

The ADR does not mention the migration, which is history. Run prettier `--write`
on both files; the blocks above are already in its 80-column wrap.

- [ ] **Step 18: Check the activation names.**

```sh
h='.#homeConfigurations."patrick@linux".config'
nix eval --json --override-input work path:./stubs/work "$h.home.activation" \
  --apply '
a:
builtins.filter
  (n: builtins.match ".*([Cc]laude|jouet|rex|merged).*" n != null)
  (builtins.attrNames a)' | jq -r '.[]'
```

It prints, one per line, `claudeCodeHookMigration`, `jouetClaudeHooks` and
`mergedSettings`. On the darwin home it prints `claudeCodeHookMigration`,
`claudeDesktopRunning`, `hideClaudeCodeUrlHandler`, `jouetClaudeHooks`,
`mergedSettings`, `rexClaudeHook` and `rexThemes`. (At a07c2f4 they print
`claudePluginSettings`, `jouetClaudeHooks` and `mergedSettings`, and
`claudeDesktopRunning`, `claudePluginSettings`, `hideClaudeCodeUrlHandler`,
`jouetClaudeHooks`, `mergedSettings`, `rexClaudeHook` and `rexThemes`.)

- [ ] **Step 19: Run the suites.** `mise run test`, `mise run check:merge-json`
      and `mise run lint` all pass. Add to `codebook.toml` any word the editor's
      spellchecker flags in the new comments.
- [ ] **Step 20: Evaluate against the real work layer.** Run the section's
      real-work-layer command; it prints one `.drv` path. The work layer adds no
      user-scope Claude hooks: it renders only per-repository
      `.claude/settings.local.json` fragments, and at its locked revision
      nothing in it names `claudePluginSettings`, `jouetClaudeHooks` or
      `rexClaudeHook`. So no work-layer entry orders after the removed writer,
      and this evaluation shows that its removal breaks nothing there.
- [ ] **Step 21: Commit.**

```sh
git add modules/home/claude-code.nix modules/home/claude-code/migrate-hooks.jq \
  modules/home/claude-code/migrate-hooks.sh modules/home/jouet.nix \
  modules/home/darwin/rex.nix docs/architecture.md codebook.toml \
  docs/adr/0012-app-owned-json-merged-with-state-tracked-removal.md
git -c commit.gpgsign=false commit \
  -m "feat(claude-code): join my.mergedSettings" \
  -m "Claude Code's settings.json had a writer of its own, a jq filter that
knew Nix's hook groups only by their commands and replaced the official
marketplace's plugin set whole. It is now my.mergedSettings.claude-code:
every hook event and permissions.deny merge by union, so Orca's groups
and hand-added rules stay, and everything else is deep-merged.
enabledPlugins comes from my.claudeCode.enabledPlugins, the set the
skills' cover check reads, so a plugin enabled by hand survives and one
Nix stops declaring is taken back. A misspelt event fails evaluation.
With no state the merge cannot tell the groups the old writers left
from Orca's, so a one-off activation entry removes them before the
first merge."
```

### Task C4.4: jouet and rex declare their agent hooks on the entry

**Files:**

- Modify: `modules/home/jouet.nix:1-35`. The formals become
  `{ lib, pkgs, ... }`, and the `jouetClaudeHooks` entry (20-34) is replaced.
- Delete: `modules/home/jouet/claude-hooks.jq`,
  `modules/home/jouet/merge-claude-hooks.sh` (keep
  `modules/home/jouet/claude-hooks.json`)
- Modify: `modules/home/darwin/rex.nix:54-62` (`rexClaudeHook` replaced)
- Create: `modules/home/darwin/rex/claude-hooks.json`
- Delete: `modules/home/darwin/rex/claude-hook.jq`,
  `modules/home/darwin/rex/claude-hook.sh` (F3's seeding lines go with it)
- Modify: `docs/architecture.md` (the bullet C4.3 wrote),
  `docs/adr/0012-app-owned-json-merged-with-state-tracked-removal.md` (the
  paragraph C4.3 added)

**Interfaces:**

- Consumes: `my.mergedSettings.claude-code.value.hooks.<Event>` from C4.3.
- Produces: activation entries `jouetClaudeHooks` and `rexClaudeHook` no longer
  exist. `modules/home/darwin/rex/claude-hooks.json` holds `rex skill setup`'s
  group verbatim, in jouet's `{ "<Event>": [ group ] }` shape.

- [ ] **Step 1: Write the failing evaluation.**

```sh
h='.#homeConfigurations."patrick@linux".config'
nix eval --json --override-input work path:./stubs/work \
  "$h.my.mergedSettings.claude-code.value.hooks" \
  --apply 'builtins.mapAttrs (_: builtins.length)' \
  | jq -r 'to_entries[] | "\(.key) \(.value)"'
```

The target output on Linux is the block below; on the darwin home it is the same
with `SessionStart 2`:

```text
PostToolUse 3
PostToolUseFailure 1
PreToolUse 2
SessionStart 1
Stop 1
```

- [ ] **Step 2: Run it and watch it fail.** Both homes print only
      `PostToolUse 1` and `PreToolUse 1`.
- [ ] **Step 3: jouet.** Replace lines 20-34 with the line below. The comment at
      14-17 already says the commands are setup's own. Drop the unused `config`
      and `substituteFile` formals.

```nix
  my.mergedSettings.claude-code.value.hooks =
    lib.importJSON ./jouet/claude-hooks.json;
```

```sh
git rm modules/home/jouet/claude-hooks.jq \
  modules/home/jouet/merge-claude-hooks.sh
```

- [ ] **Step 4: rex.** Create `modules/home/darwin/rex/claude-hooks.json` from
      the old filter, before deleting it, so it holds `rex skill setup`'s group
      verbatim, then format it with oxfmt and read its command back:

```sh
echo '{}' | jq --from-file modules/home/darwin/rex/claude-hook.jq \
  | jq .hooks >modules/home/darwin/rex/claude-hooks.json
"$(.github/scripts/nix-tool.sh oxfmt)" -c modules/home/oxc/oxfmtrc.json \
  modules/home/darwin/rex/claude-hooks.json
jq -c 'map_values(length)' modules/home/darwin/rex/claude-hooks.json
jq -r '.SessionStart[0].hooks[0].command' \
  modules/home/darwin/rex/claude-hooks.json
```

The two `jq` commands print:

```text
{"SessionStart":1}
/bin/sh -c 'rex __internal session-start --agent claude 2>/dev/null || true'
```

Replace lines 54-62 of `darwin/rex.nix` with:

```nix
  # The other half of `rex skill setup`: its agent hook, verbatim, so
  # `rex skill status` reports it current rather than adding a second.
  my.mergedSettings.claude-code.value.hooks =
    lib.importJSON ./rex/claude-hooks.json;
```

Then delete the old writer, add the new file, and format `jouet.nix` and
`darwin/rex.nix` with nixfmt:

```sh
git rm modules/home/darwin/rex/claude-hook.jq \
  modules/home/darwin/rex/claude-hook.sh
git add modules/home/darwin/rex/claude-hooks.json
```

- [ ] **Step 5: Run Step 1 again and watch it pass.** Both homes print the
      target values.
- [ ] **Step 6: Check that the old entries are gone.** Run C4.3 Step 18's
      command. Linux prints `claudeCodeHookMigration` and `mergedSettings`. The
      darwin home prints `claudeCodeHookMigration`, `claudeDesktopRunning`,
      `hideClaudeCodeUrlHandler`, `mergedSettings` and `rexThemes`.
- [ ] **Step 7: Simulate the first switch again, now with no writer after the
      merge.** Run C4.3 Step 16's block with its writers' stage, the pipeline
      that starts `jq --slurpfile jouet` and writes `$w/after.json`, replaced by
      `cp "$w/merged.json" "$w/after.json"`. The same rule and the same output
      hold: each Nix group once, Orca's kept. Nix's groups may come in another
      order within an event. The comparison prints `[]` or the same paths as in
      C4.3, and the last command prints `idempotent`.
- [ ] **Step 8: Update the documents.** In ADR-0012, the paragraph's first
      sentence becomes "Claude Code's `settings.json` is one entry, and every
      module that writes into it, jouet and rex included, adds to that entry's
      value rather than running a writer of its own." In `docs/architecture.md`,
      insert "A module writing into another's file, as jouet and rex do into
      Claude Code's, adds to that entry's `value`." before "Zed's is rendered
      with its token." Run prettier `--write` on both. The bullet then reads:

```markdown
- Apps that rewrite their own settings file (Claude Code, Claude desktop, Zed)
  get no link; their keys are merged or rendered by an activation entry after
  `writeBoundary`. Claude Code's and Claude desktop's JSON is merged through
  `my.mergedSettings` (`modules/home/merged-settings.nix`), where new app-owned
  JSON goes too: an entry names the file, its declared value and a strategy for
  any key, at any depth, that is not deep-merged (`replace` or `union`), and
  what it stops declaring is taken back at the next switch (ADR-0012). A module
  writing into another's file, as jouet and rex do into Claude Code's, adds to
  that entry's `value`. Zed's is rendered with its token.
```

and the ADR paragraph:

```markdown
Claude Code's `settings.json` is one entry, and every module that writes into
it, jouet and rex included, adds to that entry's value rather than running a
writer of its own. Orca adds its own agent-hook groups to the same per-event
lists at run time and removes only those, so every `hooks.<Event>` takes
`union`. Claude Code's schema allows no key a group could name its owner in, so
the state is what tells Nix's groups from Orca's. An event name Claude Code does
not know fails evaluation, because Claude Code only warns about one and never
runs its hooks.
```

- [ ] **Step 9: Run the suites.** `mise run test` and `mise run lint` both pass.
- [ ] **Step 10: Evaluate against the real work layer.** Run the section's
      real-work-layer command; it prints one `.drv` path. As in C4.3 Step 20,
      nothing in the work layer orders after `jouetClaudeHooks` or
      `rexClaudeHook` or writes user-scope Claude hooks, so their removal breaks
      nothing there.
- [ ] **Step 11: Commit.**

```sh
git add modules/home/jouet.nix modules/home/darwin/rex.nix \
  modules/home/darwin/rex/claude-hooks.json docs/architecture.md \
  docs/adr/0012-app-owned-json-merged-with-state-tracked-removal.md
git -c commit.gpgsign=false commit \
  -m "refactor: declare jouet's and rex's agent hooks" \
  -m "jouet and rex each rewrote Claude Code's settings.json after the main
merge with a jq filter of their own. Their agent hooks now go into
my.mergedSettings.claude-code's value from the JSON their setup
commands write, so one merge owns the file and a hook either tool
stops installing is taken back through the entry's state."
```

> Before Patrick's switch (onto C4.4, or onto C4.3 alone), he quits the Claude
> Code sessions he can, since a session that rewrites `settings.json` during the
> activation can leave a stale Nix group behind. After it, he runs C4.5 Step 1's
> two commands, and C4.3 Step 16's classifier (its `jq -r` command, with `"$s"`
> in place of `"$w/after.json"` and `s` set as in that block) on the live
> `settings.json`: both state files exist, every event keeps its `app` groups,
> and each Nix group appears once.

### Task C4.5 (after Patrick's switch to C4.4): drop the hook migration

**Files:**

- Modify: `modules/home/claude-code.nix` (the
  `home.activation.claudeCodeHookMigration` block and its comment from C4.3
  Step 14)
- Delete: `modules/home/claude-code/migrate-hooks.jq`,
  `modules/home/claude-code/migrate-hooks.sh`
- Modify, only if a word there was used by those comments alone: `codebook.toml`

**Interfaces:**

- Consumes: the state file
  `~/Library/Application Support/nix-config/claude-code.json` that Patrick's
  switch created.
- Produces: the activation entry `claudeCodeHookMigration` no longer exists.

- [ ] **Step 1: Confirm the precondition.** Both commands below must succeed and
      print as described. Stop if the first fails: the migration has not run
      yet. The first lists both state files:

```sh
d="$HOME/Library/Application Support/nix-config"
ls "$d/claude-code.json" "$d/claude-code.strategies.json"
```

The second prints `0`, meaning no Nix hook group, whatever its store hash,
appears twice in one event:

```sh
s="$HOME/Library/Application Support/claude-code/settings.json"
jq '[
  .hooks | to_entries[] | .key as $event | .value[]
  | (.hooks[0].command? // "") as $c
  | if ($c | endswith("/bin/claude-vcs-guard")) then "vcs-guard"
    elif ($c | endswith("/bin/claude-md-lint")) then "md-lint"
    elif ($c | contains("jouet hook claude ")) then $c
    elif ($c | contains("rex __internal session-start")) then "rex"
    else empty end
  | "\($event) \(.)"
] | group_by(.) | map(select(length > 1)) | length' "$s"
```

A count above `0` means a stale group survived the first switch, such as one a
Claude Code session wrote back during the activation. The migration is then the
only cleanup, so stop: Patrick deletes both state files and switches again,
which reruns it, and this task starts over.

- [ ] **Step 2: Write the failing check.** Run C4.3 Step 18's command. It still
      lists `claudeCodeHookMigration`. The target is `mergedSettings` alone on
      Linux, and `claudeDesktopRunning`, `hideClaudeCodeUrlHandler`,
      `mergedSettings` and `rexThemes` on the darwin home.
- [ ] **Step 3: Delete the migration.** Remove the block from `claude-code.nix`,
      then delete its files and any `codebook.toml` word that only those
      comments used:

```sh
git rm modules/home/claude-code/migrate-hooks.jq \
  modules/home/claude-code/migrate-hooks.sh
```

- [ ] **Step 4: Run Step 2 again and watch it pass.**
- [ ] **Step 5: Run the suites.** `mise run test` and `mise run lint` both pass.
- [ ] **Step 6: Evaluate against the real work layer.** Run the section's
      real-work-layer command; it prints one `.drv` path.
- [ ] **Step 7: Commit.**

```sh
git add modules/home/claude-code.nix codebook.toml
git -c commit.gpgsign=false commit \
  -m "chore(claude-code): drop the hook migration" \
  -m "The activation entry removing the agent-hook groups the earlier
writers left runs only while my.mergedSettings holds no state for
Claude Code. The first switch onto the entry created that state, so
the entry can never run again and only adds a guard to every
activation."
```

#### Notes for section C4

- C4 adds no flake check: its fixtures extend the existing merge-json check,
  which already has CI's `merge-json` job and `mise run check:merge-json`.
- C4.3 Step 16's comparison may list more paths than `statusLine.command`.
  Patrick's state directory holds `claude-desktop.json` but no
  `claude-desktop.strategies.json`, so the generation he runs predates the
  strategies state, and every declared value changed since then shows up.
- Every post-switch check reads the canonical
  `~/Library/Application Support/claude-code/settings.json`. Each Orca profile
  also holds its own `settings.json` under
  `~/Library/Application Support/orca/claude-profiles/<id>/home/`, a regular
  file rather than a link, which the entry never writes. Patrick can run C4.5
  Step 1's second command and C4.3 Step 16's classifier on each, with `s` set to
  that file.
- A rollback followed by a switch forward keeps stale groups, because the state
  survives. While the migration exists, deleting
  `~/Library/Application Support/nix-config/claude-code.json` and
  `claude-code.strategies.json` before switching forward makes it run again.
- The migration restates merged-settings.nix's state-path formula. If that
  formula changes while the migration exists, it runs at every switch, which is
  idempotent and costs one needless rewrite.
- No fixture covers old and current strategy trees whose paths overlap by
  prefix, such as `strategies.hooks = "replace"` before and
  `strategies.hooks.PreToolUse = "union"` now with nothing declared under
  `hooks`. Both run, and `replace` can delete the whole parent, Orca's groups
  included.
- A plugin dropped from `officialPlugins` loses its `enabledPlugins` key rather
  than being set to `false`, as `settings.jq` did. Whether Claude Code 2.1.318
  then treats it as disabled is unchecked.
- Strategies cover all 33 events, not only the declared ones, so a module that
  later hooks another event needs no strategy change; the assertion checks the
  names under `value.hooks`.
- `jouet/claude-hooks.json` and `rex/claude-hooks.json` declare no `$schema`: no
  published schema fits that fragment shape.
- `CLAUDE.md` says nothing about Claude Code keeping its own entry (only
  `docs/architecture.md` does), so no task touches it.

---

## Section C7: Variant variables

Card 7 of the Spec. Six environment variables differ per Variant; today all six
come from one shell-filled template (`modules/home/nushell/path-themes.sh`,
`path-themes/variant.env`, `path-themes/variant.gitconfig`) built by
`modules/home/nushell.nix:19-51`. After this section `modules/home/options.nix`
declares `my.theme.variantVariables` (an option shared across modules), each
tool's module declares its own pair in it, `nushell.nix` renders `pro.env` and
`alucard.env` from it in pure Nix, and the template goes.

Order inside the section: C7.1 adds the option, renderer and assertions and
lists the new directory **last** in `theme-dirs.nuon`, after `@pathThemes@`.
`env_for` upserts directory by directory, so a later directory wins. C7.2 to
C7.4 then move the pairs one owner at a time while the old template still sets
the same values underneath, and C7.5 deletes the template. Every intermediate
commit therefore loads the same values, and the old pipeline's
`substitute --replace-fail` plumbing (which fails only at build time, so no eval
catches it) is never edited piecemeal.

Facts these tasks rest on, checked while writing the plan:

- moor 2.19.5 (the flake's `pkgs.moor`), `cmd/moor/moor.go`: `moorEnvVarName()`
  returns `MOOR` when it is non-blank and only otherwise `MOAR`; the chosen
  value is split with `strings.Fields` and put in front of the command-line
  flags. Nothing merges two sources, and Nushell's `load-env` replaces `MOOR`
  whole. So each Variant's `MOOR` is its `--style=` followed by `moor.nix`'s
  flags, from one binding (C7.4). `MOOR='--style=nosuchstyle' moor --version`
  fails with `invalid value "nosuchstyle" for flag -style`, which shows the
  variable is parsed.
- git 2.56: one `[include]` section with two `path` values includes both, in
  order, the later one winning. That reads the same as the two sections
  `variant.gitconfig` has today (checked with `GIT_CONFIG_GLOBAL` against
  scratch files).
- `env_for` (extras checkout `src/nushell/dracula-pro.nu:231-260`, nu 0.116.1)
  reads `NAME='value'` back exactly for any one-line value: it strips one outer
  pair of single quotes and does nothing else. An env file holding the lines on
  the left reads back as the values on the right, in `env-record.jq`'s form
  (C7.1 Step 1):

  ```text
  A='x y'       A="x y"
  B=''          B=""
  C=''q''       C="'q'"
  D='a=b'       D="a=b"
  E=' lead'     E=" lead"
  F='it'\''s'   F="it'\\''s"
  ```

- `config.assertions` is not lazy in the renderer: home-manager's file checks
  force `home.file`, hence `programs.nushell.extraConfig`, hence
  `theme-dirs.nuon` and both env files. Each env file therefore lists only the
  names whose value for **its** Variant is non-null; interpolating a null would
  abort the evaluation with `cannot coerce null to a string` before the
  one-Variant assertion could report.
- Today's rendered values (HEAD's realised
  `/nix/store/lkays908q538j1kxrq5xn5mirm7my29j-dracula-path-themes`) are the
  golden values in C7.1 Step 2.

C7.1's probes, each task's formatting and C7.5's end state were run on a scratch
copy of a07c2f4, with a stand-in for C1.4's option; the intermediate outputs of
C7.2 to C7.4 are subsets of that end state. The helpers' output format (C7.1
Step 1), the renderer and assertion code (C7.1 Steps 6 and 7) and `moor.nix`
(C7.4 Step 3) were rewritten afterwards and checked piecewise rather than end to
end: the helpers against a07c2f4 (Step 2's golden lines, the failures of Steps 3
and 4) and a hand-made env directory, the code through `nix eval` with the
flake's `lib` and through the flake's nixfmt. Only what needs the real C1.4
could not run at all: C7.4 Step 1's `["PAGER"]` and C1.4's classification
command in C7.4 Step 4.

**Dependencies on C1.** C1.1 adds
`my.launchd.extraVariables = [ "STARSHIP_CACHE" ];` after line 3 of
`starship.nix`. C1.4 declares `my.launchd.shellOnlyVariables`, adds
`[ "STARSHIP_CONFIG" ]` after `programs.starship` in `starship.nix` (before
C7.2's declaration when that is present) and adds moor.nix's line after
`home.sessionVariables`: `[ "PAGER" ]`, or `[ "MOOR" "PAGER" ]` once C7.4 has
landed, which C1.4 detects by `git grep -n "MOOR = flags" modules/home/moor.nix`
printing a line. C7.4 therefore keeps `MOOR = flags;` literally. C1.4 waits for
Patrick's work-layer merge and `work` lock bump; C7 does not wait for it. C7.2
and C7.4 work whether or not C1.4 has landed, and C7.4 Step 1 decides which:
whichever of C1.4 and C7.4 lands second writes moor.nix's `[ "MOOR" "PAGER" ]`.
F changes one line of `commit-messages.nix` (31), outside the region below.

Every command below runs from the worktree root with the Bash sandbox off,
because nix needs it. Line numbers are at a07c2f4. F and C1 land first and may
shift them, so each edit also names its anchor text.

### Task C7.1: Declare Variant variables and render them

**Files:**

- Modify: `modules/home/options.nix`: add `theme.variantVariables` after the
  `theme.dracula = { … };` block (40-56), before the
  `# modules/home/darwin/zed.nix` comment (58).
- Modify: `modules/home/nushell.nix`:
  - the let block (8-82): add `variantVariables` after `extras` (12), and add
    `variants`, `variantEnvFile`, `variantEnvDir`, `oneLine` and `assertionsFor`
    between `pathThemes` (ends 51) and the `themeDirs` comment (53);
  - `themeDirs`' replacements (57-60): add one name;
  - the body (83-158): add `assertions` as its first attribute.
- Modify: `modules/home/nushell/theme-dirs.nuon`: add a line after line 22
  (`"@pathThemes@"`).
- Modify: `GLOSSARY.md`: add an entry after **Variant** (124-127).
- Modify: `docs/architecture.md`: add a bullet after the theme-checkouts bullet
  (69-70).

**Interfaces:**

- Consumes:
  - `config.my.theme.dracula.extras` (`modules/home/options.nix:50-55`);
  - `substituteFile` (`lib/default.nix`);
  - the extras checkout's `env_for`, unchanged.
- Produces:
  - `my.theme.variantVariables`, declared in `modules/home/options.nix`, of type
    `attrsOf (submodule { pro = nullOr str; alucard = nullOr str; })`, both
    defaulting to `null`, the option itself to `{ }`. It is plain `attrsOf`, not
    `lazyAttrsOf`, so a name defined only under a false `lib.mkIf` is absent.
  - A derivation `pkgs.linkFarm "variant-variables"` holding `pro.env` and
    `alucard.env`, each a `pkgs.writeText "<variant>.env"`. Each file has one
    line per name whose value for that Variant is non-null: `NAME='value'`,
    `lib.mapAttrsToList` order (sorted), newline-terminated, nothing escaped.
  - That derivation is the last entry of `theme-dirs.nuon`, through the
    placeholder `@variantVariables@`.
  - Three assertions per name, with the messages Step 7's code spells out; a
    name set for neither Variant is skipped. nix-darwin prefixes each message
    with `patrick profile:` and a space.
  - Five test helpers in `$TMPDIR`, not committed, which C7.2 to C7.5 reuse.

- [ ] **Step 1: Write the test helpers**

`$TMPDIR/hm-eval.sh` evaluates one attribute of the home configuration:

```bash
#!/usr/bin/env bash
# Usage: hm-eval.sh darwin|linux ATTR --json|--raw [NIX-EVAL-ARGS...]
set -euo pipefail
case $1 in
  darwin)
    root='.#darwinConfigurations.Patricks-MacBook-Pro'
    root+='.config.home-manager.users.patrick'
    ;;
  linux) root='.#homeConfigurations."patrick@linux".config' ;;
  *)
    echo "hm-eval.sh: darwin or linux, not $1" >&2
    exit 2
    ;;
esac
attr=$2
shift 2
nix eval --override-input work path:./stubs/work "$@" "$root.$attr"
```

`$TMPDIR/env-record.jq` turns `env_for`'s record into one `NAME=<JSON value>`
line per variable, sorted by name. It reduces `GIT_CONFIG_GLOBAL` to whether it
names a `<STEM>.gitconfig` store file, and writes the extras checkout's path as
`<extras>`:

```jq
# Usage: jq --raw-output --arg v STEM --arg x EXTRAS --from-file THIS
if has("GIT_CONFIG_GLOBAL") then
  .GIT_CONFIG_GLOBAL
    |= test("^/nix/store/[0-9a-z]{32}-" + $v + "\\.gitconfig$")
else . end
| map_values(
    if type == "string" and startswith($x)
    then "<extras>" + ltrimstr($x)
    else . end)
| keys[] as $k
| "\($k)=\(.[$k] | tojson)"
```

`$TMPDIR/variant-env.sh` builds the new directory, with the home module on stdin
added, and prints `env_for`'s record of `STEM.env` through `env-record.jq`. With
`--file` it first prints the file itself and a `--` line. nix's own messages
stay on stderr.

```bash
#!/usr/bin/env bash
# Usage: variant-env.sh STEM [--file] <MODULE
set -euo pipefail
stem=$1
show_file=${2:-}
here=$(dirname "$0")
extra=$(cat)
drv=$(nix eval --raw --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply "
    c: (c.extendModules {
      modules = [ { home-manager.users.patrick = $extra; } ];
    }).config.home-manager.users.patrick.home.activationPackage.drvPath")
dir_drv=$(nix-store --query --requisites "$drv" \
  | grep -- '-variant-variables\.drv$')
dir=$(nix build --no-link --print-out-paths "$dir_drv^out")
if [ "$show_file" = --file ]; then
  cat "$dir/$stem.env"
  echo --
fi
extras=$HOME/Developer/github.com/pgodschalk/dracula-pro-extras
nu --no-config-file --commands "
  use '$extras/src/nushell/dracula-pro.nu' [env_for]
  env_for ['$dir'] $stem | to json --raw" \
  | jq --raw-output --arg v "$stem" --arg x "$extras" \
    --from-file "$here/env-record.jq"
```

`$TMPDIR/variant-assert.sh` follows C1's probe pattern. It evaluates the macOS
system with the module on stdin added and prints the failed assertions' messages
as a JSON list, `[]` when none fails; an option error aborts it.

```bash
#!/usr/bin/env bash
# Usage: variant-assert.sh <MODULE
set -euo pipefail
extra=$(cat)
nix eval --json --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro' --apply "
    c:
    let
      probe = c.extendModules {
        modules = [ { home-manager.users.patrick = $extra; } ];
      };
      failed = builtins.filter (a: !a.assertion) probe.config.assertions;
    in
    map (a: a.message) failed"
```

`$TMPDIR/theme-env.sh` loads the real `theme-dirs.nuon` the themed shell reads,
through the real `env_for`, and prints the six variables through
`env-record.jq`. A missing variable makes `select` fail with
`cannot find column`.

```bash
#!/usr/bin/env bash
# Usage: theme-env.sh STEM
set -euo pipefail
stem=$1
here=$(dirname "$0")
drv=$(bash "$here/hm-eval.sh" darwin home.activationPackage.drvPath --raw)
nuon_drv=$(nix-store --query --requisites "$drv" \
  | grep -- '-theme-dirs\.nuon\.drv$')
nuon=$(nix build --no-link --print-out-paths "$nuon_drv^out")
extras=$HOME/Developer/github.com/pgodschalk/dracula-pro-extras
names='DFT_BACKGROUND GIT_CONFIG_GLOBAL LUMEN_THEME MOOR'
names+=' RIPGREP_CONFIG_PATH STARSHIP_CONFIG'
nu --no-config-file --commands "
  use '$extras/src/nushell/dracula-pro.nu' [env_for]
  env_for (open '$nuon') $stem | select $names | to json --raw" \
  | jq --raw-output --arg v "$stem" --arg x "$extras" \
    --from-file "$here/env-record.jq"
```

- [ ] **Step 2: Record the golden values the section must keep**

Run:

```sh
bash "$TMPDIR/theme-env.sh" pro
bash "$TMPDIR/theme-env.sh" alucard
```

Expected, the golden lines (`GIT_CONFIG_GLOBAL` is `false` because it still
names `…-dracula-path-themes/pro.gitconfig`):

```text
DFT_BACKGROUND="dark"
GIT_CONFIG_GLOBAL=false
LUMEN_THEME="dracula"
MOOR="--style=dracula --no-linenumbers --quit-if-one-screen --statusbar=bold"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/pro.conf"
STARSHIP_CONFIG="<extras>/src/starship/pro.toml"
DFT_BACKGROUND="light"
GIT_CONFIG_GLOBAL=false
LUMEN_THEME="catppuccin-latte"
MOOR="--style=tango --no-linenumbers --quit-if-one-screen --statusbar=bold"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/alucard.conf"
STARSHIP_CONFIG="<extras>/src/starship/alucard.toml"
```

- [ ] **Step 3: Run the render probe and see it fail**

```sh
bash "$TMPDIR/variant-env.sh" pro --file <<'EOF'
{
  my.theme.variantVariables.PROBE_QUOTES = {
    pro = "'q'";
    alucard = "a=b c";
  };
}
EOF
```

Expected: nix fails, the error saying that the option
`` `home-manager.users.patrick.my.theme.variantVariables' `` does not exist.

- [ ] **Step 4: Run the three assertion probes and see them fail**

```sh
bash "$TMPDIR/variant-assert.sh" <<'EOF'
{ my.theme.variantVariables."BAD-NAME" = { pro = "x"; alucard = "y"; }; }
EOF
bash "$TMPDIR/variant-assert.sh" <<'EOF'
{ my.theme.variantVariables.PROBE_ONE.pro = "x"; }
EOF
bash "$TMPDIR/variant-assert.sh" <<'EOF'
{ my.theme.variantVariables.PROBE_LINES = { pro = "a\nb"; alucard = "c"; }; }
EOF
```

Expected: each fails with the same option-does-not-exist error as Step 3,
followed by `Definition values:`, the probe's definition and
``Did you mean `home-manager.users.patrick.my.theme.dracula'?``.

- [ ] **Step 5: Declare the option**

In `modules/home/options.nix`, after the `theme.dracula = { … };` block and
before `# modules/home/darwin/zed.nix` (the options are in name order), with a
blank line on each side:

```nix
    # modules/home/nushell.nix, which renders them into the env files
    # the themed shell loads at each Appearance switch.
    theme.variantVariables = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            pro = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "The value under Dracula Pro, the dark Variant.";
            };
            alucard = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "The value under Alucard, the light Variant.";
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          DFT_BACKGROUND = {
            pro = "dark";
            alucard = "light";
          };
        }
      '';
      description = ''
        Variant variables by name: environment variables whose value
        differs per Variant, loaded by the themed shell at each
        Appearance switch. Both Variants set the same names, every value
        is one line, and a value pointing into a theme checkout is
        declared under `lib.mkIf (extras != null)`.
      '';
    };
```

`options.nix`'s header comment already names options shared across modules as
belonging there; it needs no edit.

- [ ] **Step 6: Render the env files and list their directory last**

In `modules/home/nushell.nix`'s let block, after
`extras = config.my.theme.dracula.extras;`, add
`variantVariables = config.my.theme.variantVariables;`. Between `pathThemes` and
the `themeDirs` comment, with a blank line on each side, add:

```nix
  variants = [
    "pro"
    "alucard"
  ];

  # Single-quoted, because the theme module's env_for strips one outer
  # pair of single quotes and nothing else, so every one-line value
  # comes back verbatim.
  variantEnvFile =
    variant:
    let
      isSet = _: values: values.${variant} != null;
      line = name: values: "${name}='${values.${variant}}'";
      lines = lib.mapAttrsToList line (lib.filterAttrs isSet variantVariables);
    in
    pkgs.writeText "${variant}.env" (lib.concatLines lines);

  variantEnvDir = pkgs.linkFarm "variant-variables" {
    "pro.env" = variantEnvFile "pro";
    "alucard.env" = variantEnvFile "alucard";
  };
```

`isSet` filters by the file's own Variant, not by either Variant being set: a
name set for one Variant only must reach its assertion, not a null
interpolation.

In `themeDirs`' `substituteFile` call, after `pathThemes = "${pathThemes}";`,
add `variantVariables = "${variantEnvDir}";`. In
`modules/home/nushell/theme-dirs.nuon`, after line 22 (`"@pathThemes@"`), add:

```text
    "@variantVariables@" # my.theme.variantVariables
```

On Linux `extras` is null, so `themeSetup` is `""` and `themeDirs`, and
therefore the renderer, is never forced. Do not reference `variantEnvDir`
anywhere else.

- [ ] **Step 7: Add the assertions**

In the let block, after `variantEnvDir`, with a blank line on each side:

```nix
  oneLine = value: !(lib.hasInfix "\n" value || lib.hasInfix "\r" value);

  assertionsFor =
    name: values:
    [
      {
        assertion = builtins.match "[A-Za-z_][A-Za-z0-9_]*" name != null;
        message =
          "my.theme.variantVariables.${name} is not a plain variable name: "
          + "letters, digits and underscores, not starting with a digit";
      }
      {
        assertion = (values.pro == null) == (values.alucard == null);
        message =
          "my.theme.variantVariables.${name} has a value for one Variant "
          + "only; set both pro and alucard, or neither";
      }
    ]
    ++ map (variant: {
      assertion = values.${variant} == null || oneLine values.${variant};
      message =
        "my.theme.variantVariables.${name}.${variant} holds a line break; "
        + "an env file takes one line per variable";
    }) variants;
```

As the first attribute of the module body, before `programs.nushell`:

```nix
  assertions = lib.flatten (lib.mapAttrsToList assertionsFor variantVariables);
```

- [ ] **Step 8: Format**

Run:

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" \
  modules/home/options.nix modules/home/nushell.nix
```

Expected: exit 0, and the code from Steps 5 to 7 stays exactly as shown.

- [ ] **Step 9: Run the render probe and see it pass**

Run Step 3's command, then the same with `alucard` in place of `pro`, then
`echo '{ }' | bash "$TMPDIR/variant-env.sh" pro --file`.

Expected stdout, in turn:

```text
PROBE_QUOTES=''q''
--
PROBE_QUOTES="'q'"
```

```text
PROBE_QUOTES='a=b c'
--
PROBE_QUOTES="a=b c"
```

```text
--
```

- [ ] **Step 10: Run the assertion probes and see them pass**

Step 4's three probes, each compared with its one expected message:

```sh
p='patrick profile: my.theme.variantVariables.'
bash "$TMPDIR/variant-assert.sh" <<'EOF' | jq --arg p "$p" '. == [$p
  + "BAD-NAME is not a plain variable name: letters, digits and"
  + " underscores, not starting with a digit"]'
{ my.theme.variantVariables."BAD-NAME" = { pro = "x"; alucard = "y"; }; }
EOF
bash "$TMPDIR/variant-assert.sh" <<'EOF' | jq --arg p "$p" '. == [$p
  + "PROBE_ONE has a value for one Variant only; set both pro and"
  + " alucard, or neither"]'
{ my.theme.variantVariables.PROBE_ONE.pro = "x"; }
EOF
bash "$TMPDIR/variant-assert.sh" <<'EOF' | jq --arg p "$p" '. == [$p
  + "PROBE_LINES.pro holds a line break; an env file takes one line"
  + " per variable"]'
{ my.theme.variantVariables.PROBE_LINES = { pro = "a\nb"; alucard = "c"; }; }
EOF
```

Expected: `true` three times. On `false`, run that probe without the `jq` to see
the messages.

Then run `echo '{ }' | bash "$TMPDIR/variant-assert.sh"`. Expected: `[]`.

- [ ] **Step 11: Check both configurations and the golden values**

Run:

```sh
bash "$TMPDIR/hm-eval.sh" darwin my.theme.variantVariables --json
bash "$TMPDIR/hm-eval.sh" linux my.theme.variantVariables --json
```

Expected: `{}` twice. Then run Step 2's commands. Expected: the golden lines,
unchanged.

- [ ] **Step 12: Add the glossary entry and the convention**

`GLOSSARY.md`, after the **Variant** entry and its `_Avoid_` line, before
**Theme checkout**, with a blank line on each side:

```markdown
**Variant variable**:\
An environment variable whose value differs per Variant, set by the themed shell
at each Appearance switch.\
_Avoid_: path theme
```

`docs/architecture.md`, a new bullet after "Theme checkouts
(`my.theme.dracula.*`) are nullable…":

```markdown
- A variable whose value differs per Variant is declared by its tool's module in
  `my.theme.variantVariables.<NAME> = { pro; alucard; }`, an option of
  `options.nix`; `nushell.nix` renders the env files the themed shell loads at
  each Appearance switch, and a value pointing into a theme checkout is behind
  `lib.mkIf (extras != null)` too.
```

Run:

```sh
"$(.github/scripts/nix-tool.sh prettier)" --write --parser=markdown \
  --prose-wrap=always --print-width=80 GLOSSARY.md docs/architecture.md
```

Expected: both files exactly as above (prettier leaves these lines alone).

- [ ] **Step 13: Run the suite**

Run: `mise run test && mise run lint`

Expected: both evaluations print a drv path, and every lint task passes.

- [ ] **Step 14: Commit**

```sh
git add modules/home/options.nix modules/home/nushell.nix \
  modules/home/nushell/theme-dirs.nuon GLOSSARY.md docs/architecture.md
git -c commit.gpgsign=false commit \
  -m "feat(nushell): declare Variant variables" \
  -m "Six environment variables differ per Variant, and all six live in one
shell-filled template under nushell/, far from the modules that install
their tools. my.theme.variantVariables, in options.nix because five
modules set it, lets each module declare its own pair. nushell.nix
renders pro.env and alucard.env in pure Nix into a directory listed last
among the theme directories, so its values win, and fails evaluation on
a name set for one Variant only, a value with a line break, or a name
env_for cannot load."
```

### Task C7.2: Move STARSHIP_CONFIG, RIPGREP_CONFIG_PATH and LUMEN_THEME

**Files:**

- Modify: `modules/home/starship.nix` (1-18): the header (1), a new let block, a
  declaration after the `programs.starship = { … };` block (5-17) and after
  C1.4's `my.launchd.shellOnlyVariables = [ "STARSHIP_CONFIG" ];` when C1.4 has
  landed, and the comment at 13-14. C1.1's
  `my.launchd.extraVariables = [ "STARSHIP_CACHE" ];` (after line 3) and C1.4's
  line both stay.
- Modify: `modules/home/ripgrep.nix` (1-7): the header, a new let block, delete
  the comment at 5-6, and add a declaration.
- Modify: `modules/home/commit-messages.nix`: a declaration after the
  `home.packages = [ … ];` list in `config` (288-291).

**Interfaces:**

- Consumes: `my.theme.variantVariables` (C7.1) and
  `config.my.theme.dracula.extras`.
- Produces: `my.theme.variantVariables.STARSHIP_CONFIG` and
  `.RIPGREP_CONFIG_PATH`, both only when extras is non-null, and `.LUMEN_THEME`,
  always.

- [ ] **Step 1: Run the expectation and see it fail**

```sh
extras=$HOME/Developer/github.com/pgodschalk/dracula-pro-extras
bash "$TMPDIR/hm-eval.sh" darwin my.theme.variantVariables --json \
  | sed "s|$extras|<extras>|g" | jq .
```

Expected after this task:

```json
{
  "LUMEN_THEME": {
    "alucard": "catppuccin-latte",
    "pro": "dracula"
  },
  "RIPGREP_CONFIG_PATH": {
    "alucard": "<extras>/src/ripgrep/alucard.conf",
    "pro": "<extras>/src/ripgrep/pro.conf"
  },
  "STARSHIP_CONFIG": {
    "alucard": "<extras>/src/starship/alucard.toml",
    "pro": "<extras>/src/starship/pro.toml"
  }
}
```

It prints `{}` now.

- [ ] **Step 2: starship.nix**

The header becomes `{ config, lib, ... }:` with
`let extras = config.my.theme.dracula.extras; in`. After the `programs.starship`
block (and after C1.4's shell-only line, if present), add:

```nix
my.theme.variantVariables.STARSHIP_CONFIG = lib.mkIf (extras != null) {
  pro = "${extras}/src/starship/pro.toml";
  alucard = "${extras}/src/starship/alucard.toml";
};
```

In the comment inside `programs.starship`, change line 13's
`# themes live in dracula-pro-extras and modules/home/nushell.nix` to
`# themes live in dracula-pro-extras and the Variant variable below`. Leave the
rest of that comment as it is.

- [ ] **Step 3: ripgrep.nix**

The header becomes `{ config, lib, pkgs, ... }` (nixfmt spreads it over lines),
with the same `extras` let block. Delete the comment "RIPGREP_CONFIG_PATH is set
per appearance variant in modules/home/nushell.nix." and add, after
`home.packages`:

```nix
my.theme.variantVariables.RIPGREP_CONFIG_PATH = lib.mkIf (extras != null) {
  pro = "${extras}/src/ripgrep/pro.conf";
  alucard = "${extras}/src/ripgrep/alucard.conf";
};
```

- [ ] **Step 4: commit-messages.nix**

Inside `config`, after the `home.packages = [ pkgs.lumen commitlintBun ];` list,
add the following. The comment moves from `variant.env`:

```nix
# lumen takes one of its built-in theme names and no theme file, so
# this is upstream's plain dracula and, on the light side, the
# nearest of its light built-ins.
my.theme.variantVariables.LUMEN_THEME = {
  pro = "dracula";
  alucard = "catppuccin-latte";
};
```

- [ ] **Step 5: Format and run the expectation**

Run:

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" modules/home/starship.nix \
  modules/home/ripgrep.nix modules/home/commit-messages.nix
```

Then Step 1's commands, which must print Step 1's JSON, and
`bash "$TMPDIR/hm-eval.sh" linux my.theme.variantVariables --json`, which must
print `{"LUMEN_THEME":{"alucard":"catppuccin-latte","pro":"dracula"}}`. That
shows the two checkout paths stay unforced with extras null.

- [ ] **Step 6: Check the rendered files**

Run:

```sh
echo '{ }' | bash "$TMPDIR/variant-env.sh" pro
echo '{ }' | bash "$TMPDIR/variant-env.sh" alucard
```

Expected:

```text
LUMEN_THEME="dracula"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/pro.conf"
STARSHIP_CONFIG="<extras>/src/starship/pro.toml"
LUMEN_THEME="catppuccin-latte"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/alucard.conf"
STARSHIP_CONFIG="<extras>/src/starship/alucard.toml"
```

Then run C7.1 Step 2's commands. Expected: the golden lines, unchanged.

- [ ] **Step 7: Run the suite**

Run: `mise run test && mise run lint`. Expected: both pass.

- [ ] **Step 8: Commit**

```sh
git add modules/home/starship.nix modules/home/ripgrep.nix \
  modules/home/commit-messages.nix
git -c commit.gpgsign=false commit \
  -m "refactor: declare three Variant variables in place" \
  -m "STARSHIP_CONFIG, RIPGREP_CONFIG_PATH and LUMEN_THEME move from the
path-themes template to the modules that install starship, ripgrep and
lumen, values unchanged; the two theme paths are declared only where
the extras checkout exists. The template's copies are shadowed until
it goes."
```

### Task C7.3: Declare git's GIT_CONFIG_GLOBAL shim and DFT_BACKGROUND

**Files:**

- Modify: `modules/home/git.nix`: the let block (7-55; add a binding after
  `signingPublicKey`, 54) and the body (add a declaration after the
  `home.packages` list, 57-60).

**Interfaces:**

- Consumes:
  - `my.theme.variantVariables` (C7.1);
  - `config.home.homeDirectory`;
  - `lib.generators.toGitINI`.
- Produces:
  - `my.theme.variantVariables.GIT_CONFIG_GLOBAL.<variant>`, only with extras
    set: the store path `/nix/store/<hash>-<variant>.gitconfig`;
  - `my.theme.variantVariables.DFT_BACKGROUND`, always.

- [ ] **Step 1: Run the expectations and see them fail**

Run:

```sh
bash "$TMPDIR/hm-eval.sh" darwin \
  my.theme.variantVariables.GIT_CONFIG_GLOBAL.pro --raw \
  --apply builtins.readFile
```

Expected: nix fails, saying the flake does not provide the attribute; the last
candidate it names ends in
`…patrick.my.theme.variantVariables.GIT_CONFIG_GLOBAL.pro`.

Also run `bash "$TMPDIR/theme-env.sh" pro`. It still prints
`GIT_CONFIG_GLOBAL=false`; the target is `true`.

- [ ] **Step 2: Add the shim**

In the let block, after `signingPublicKey`:

```nix
# GIT_CONFIG_GLOBAL replaces the global config rather than adding to
# it, so each shim includes the real one first: pointing the variable
# straight at a theme would discard the identity and the rest.
gitconfigShim =
  variant:
  pkgs.writeText "${variant}.gitconfig" (
    lib.generators.toGitINI {
      include.path = [
        "${config.home.homeDirectory}/.gitconfig"
        "${extras}/src/git/${variant}.gitconfig"
      ];
    }
  );
```

- [ ] **Step 3: Declare the pairs**

After the `home.packages = with pkgs; [ delta difftastic ];` list:

```nix
my.theme.variantVariables = {
  GIT_CONFIG_GLOBAL = lib.mkIf (extras != null) {
    pro = "${gitconfigShim "pro"}";
    alucard = "${gitconfigShim "alucard"}";
  };

  # difftastic has no theme, only a hint choosing between its built-in
  # bright and dim colours.
  DFT_BACKGROUND = {
    pro = "dark";
    alucard = "light";
  };
};
```

- [ ] **Step 4: Format and check the shim text**

Run `"$(.github/scripts/nix-tool.sh nixfmt)" modules/home/git.nix`, then:

```sh
extras=$HOME/Developer/github.com/pgodschalk/dracula-pro-extras
for v in pro alucard; do
  bash "$TMPDIR/hm-eval.sh" darwin \
    "my.theme.variantVariables.GIT_CONFIG_GLOBAL.$v" --raw \
    --apply builtins.readFile 2>/dev/null \
    | sed "s|$extras|<extras>|" | cat -t
done
```

The `readFile` builds each shim, and `cat -t` shows each tab as `^I`. Expected:

```text
[include]
^Ipath = "/Users/patrick/.gitconfig"
^Ipath = "<extras>/src/git/pro.gitconfig"
[include]
^Ipath = "/Users/patrick/.gitconfig"
^Ipath = "<extras>/src/git/alucard.gitconfig"
```

- [ ] **Step 5: Check git reads the shim**

```sh
for v in pro alucard; do
  shim=$(bash "$TMPDIR/hm-eval.sh" darwin \
    "my.theme.variantVariables.GIT_CONFIG_GLOBAL.$v" --raw 2>/dev/null)
  (cd "$TMPDIR" && GIT_CONFIG_GLOBAL="$shim" GIT_CONFIG_NOSYSTEM=1 \
    git config --get color.branch.local \
    && GIT_CONFIG_GLOBAL="$shim" GIT_CONFIG_NOSYSTEM=1 \
    git config --get user.email)
done
```

Expected: `#F8F8F2`, `patrick@kernelpanics.nl`, `#1F1F1F`,
`patrick@kernelpanics.nl`.

- [ ] **Step 6: Check DFT_BACKGROUND on both configurations**

Run:

```sh
bash "$TMPDIR/hm-eval.sh" darwin \
  my.theme.variantVariables.DFT_BACKGROUND --json
bash "$TMPDIR/hm-eval.sh" linux \
  my.theme.variantVariables.DFT_BACKGROUND --json
```

Expected, both: `{"alucard":"light","pro":"dark"}`.

Then run:

```sh
bash "$TMPDIR/hm-eval.sh" linux my.theme.variantVariables --json \
  --apply builtins.attrNames
```

Expected: `["DFT_BACKGROUND","LUMEN_THEME"]`.

- [ ] **Step 7: Check the rendered files and the shell's view**

Run: `echo '{ }' | bash "$TMPDIR/variant-env.sh" pro`

Expected:

```text
DFT_BACKGROUND="dark"
GIT_CONFIG_GLOBAL=true
LUMEN_THEME="dracula"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/pro.conf"
STARSHIP_CONFIG="<extras>/src/starship/pro.toml"
```

Then run C7.1 Step 2's commands. Expected: the golden lines with
`GIT_CONFIG_GLOBAL=true` in both Variants, everything else unchanged. From here
on the golden lines carry `true`.

- [ ] **Step 8: Run the suite**

Run: `mise run test && mise run lint`. Expected: both pass.

- [ ] **Step 9: Commit**

```sh
git add modules/home/git.nix
git -c commit.gpgsign=false commit \
  -m "refactor(git): own its Variant variables" \
  -m "git.nix declares GIT_CONFIG_GLOBAL and DFT_BACKGROUND beside the git and
difftastic it configures. toGitINI renders the shim from the two include
paths in order, rather than a template filled by shell: one [include]
section holding both paths, quoted, which git reads exactly as the two
sections it replaces."
```

### Task C7.4: Move MOOR's non-theme flags to moor.nix's session value

**Files:**

- Modify: `modules/home/moor.nix` (1-17, plus C1.4's
  `my.launchd.shellOnlyVariables = [ "PAGER" ];` after the
  `home.sessionVariables` block when C1.4 has landed): a new let block,
  `home.sessionVariables` (7-9), the shell-only line, delete the stale comment
  at 11-12 (it names `path-themes/variant.env`), add a declaration, and keep
  14-16. The header stays `{ pkgs, ... }:`.

**Interfaces:**

- Consumes:
  - `my.theme.variantVariables` (C7.1) and `home.sessionVariables`;
  - `my.launchd.shellOnlyVariables` (C1.4), when it exists. MOOR and PAGER are
    shell-only. MOOR is not home-valued, so C1.4's assertion does not catch a
    missing entry; only C1.4 Step 9's classification command does.
- Produces:
  - `home.sessionVariables.MOOR = flags;`, the one binding
    `flags = "--no-linenumbers --quit-if-one-screen --statusbar=bold";`, on both
    configurations; C1.4 detects C7.4 by that `MOOR = flags` text;
  - `my.theme.variantVariables.MOOR`, always: each Variant's `--style=` (style
    `dracula` for pro, `tango` for alucard), a space, then `flags`;
  - with C1.4 landed, `my.launchd.shellOnlyVariables = [ "MOOR" "PAGER" ];` in
    `moor.nix`, on the line after `home.sessionVariables`.

- [ ] **Step 1: Check whether C1.4 has landed**

C1.4 waits for Patrick and this task does not, so the shell-only option may not
exist yet. Run:

```sh
bash "$TMPDIR/hm-eval.sh" darwin my.launchd.shellOnlyVariables --json \
  --apply 'l: builtins.filter (n: n == "MOOR" || n == "PAGER") l'
```

- `["PAGER"]`: C1.4 has landed. This task extends moor.nix's line to
  `[ "MOOR" "PAGER" ]` (Step 3) and checks it (Step 4).
- nix fails, saying the flake does not provide the attribute; the last candidate
  it names ends in `…patrick.my.launchd.shellOnlyVariables`. Then C1.4 has not
  landed. Leave the shell-only list out of Step 3 and skip Step 4's last two
  checks; do not declare the option here. C1.4 later finds `MOOR = flags` in
  moor.nix, writes `[ "MOOR" "PAGER" ]` itself (its Step 6) and expects 67 names
  in its Step 9.

- [ ] **Step 2: Run the expectation and see it fail**

Run: `bash "$TMPDIR/hm-eval.sh" darwin home.sessionVariables.MOOR --raw`

Expected: nix fails, saying the flake does not provide the attribute; the last
candidate it names ends in `…patrick.home.sessionVariables.MOOR`.

- [ ] **Step 3: Write moor.nix**

The whole file, as nixfmt leaves it. The shell-only list is there only when Step
1 printed `["PAGER"]`; it replaces C1.4's `[ "PAGER" ]` line.

```nix
{ pkgs, ... }:
let
  # moor reads one variable, MOOR, and the themed shell replaces it
  # whole at each Appearance switch, so each Variant's value repeats
  # these flags after its style.
  flags = "--no-linenumbers --quit-if-one-screen --statusbar=bold";
  withStyle = style: "--style=${style} ${flags}";
in
{
  # `moor`, not `moar`: upstream renamed both in 2.0, and the nixpkgs
  # alias warns on every evaluation.
  home.packages = [ pkgs.moor ];

  home.sessionVariables = {
    MOOR = flags;
    PAGER = "moor";
  };
  my.launchd.shellOnlyVariables = [
    "MOOR"
    "PAGER"
  ];

  # moor takes a Chroma style name from its built-in registry and no
  # palette file, so this is Chroma's plain dracula and, on the light
  # side, the nearest of its light styles.
  my.theme.variantVariables.MOOR = {
    pro = withStyle "dracula";
    alucard = withStyle "tango";
  };

  # moor supports neither LESS_TERMCAP_* nor LESSOPEN, so the `less`
  # theme reaches only a directly invoked less, and a LESSOPEN filter
  # such as batpipe would be inert.
}
```

- [ ] **Step 4: Format and run the expectations**

Run `"$(.github/scripts/nix-tool.sh nixfmt)" modules/home/moor.nix` (expected:
no change), then:

- `bash "$TMPDIR/hm-eval.sh" darwin home.sessionVariables.MOOR --raw` and the
  same with `linux`. Expected, both:
  `--no-linenumbers --quit-if-one-screen --statusbar=bold`.
- The Variant values on Linux, pro first:

  ```sh
  bash "$TMPDIR/hm-eval.sh" linux my.theme.variantVariables.MOOR --json \
    | jq --raw-output '.pro, .alucard'
  ```

  Expected:

  ```text
  --style=dracula --no-linenumbers --quit-if-one-screen --statusbar=bold
  --style=tango --no-linenumbers --quit-if-one-screen --statusbar=bold
  ```

- The names on Linux:

  ```sh
  bash "$TMPDIR/hm-eval.sh" linux my.theme.variantVariables --json \
    --apply builtins.attrNames
  ```

  Expected: `["DFT_BACKGROUND","LUMEN_THEME","MOOR"]`, which is the full set on
  Linux after this section.

- With C1.4 landed only: Step 1's command. Expected: `["MOOR","PAGER"]`.
- With C1.4 landed only: C1.4 Step 9's classification command, which lists every
  macOS session variable in neither option:

  ```bash
  nix eval --json --override-input work path:./stubs/work \
    '.#darwinConfigurations.Patricks-MacBook-Pro.config' --apply '
  cfg:
  let
    home = cfg.home-manager.users.patrick;
    classified =
      builtins.attrNames cfg.launchd.user.envVariables
      ++ home.my.launchd.shellOnlyVariables
      ++ [ "TERMINFO_DIRS" ];
    set = builtins.attrNames home.home.sessionVariables;
  in
  builtins.filter (n: !(builtins.elem n classified)) set'
  ```

  Expected: `[]`, now over 67 names (40 GUI variables, 27 shell-only).

- [ ] **Step 5: Check moor accepts each Variant's value**

```sh
for v in pro alucard; do
  MOOR=$(bash "$TMPDIR/hm-eval.sh" darwin \
    "my.theme.variantVariables.MOOR.$v" --raw 2>/dev/null) \
    "$(.github/scripts/nix-tool.sh moor)" --version
done
```

Expected: `v2.19.5` twice. An unknown style or flag in the value would print
`ERROR: invalid value …` instead.

- [ ] **Step 6: Check the rendered files and the shell's view**

Run: `echo '{ }' | bash "$TMPDIR/variant-env.sh" alucard`

Expected:

```text
DFT_BACKGROUND="light"
GIT_CONFIG_GLOBAL=true
LUMEN_THEME="catppuccin-latte"
MOOR="--style=tango --no-linenumbers --quit-if-one-screen --statusbar=bold"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/alucard.conf"
STARSHIP_CONFIG="<extras>/src/starship/alucard.toml"
```

Then run C7.1 Step 2's commands. Expected: the golden lines (with `true`)
unchanged.

- [ ] **Step 7: Run the suite**

Run: `mise run test && mise run lint`. Expected: both pass.

- [ ] **Step 8: Commit**

Without C1.4, drop the body's last sentence ("MOOR stays shell-only beside
PAGER.").

```sh
git add modules/home/moor.nix
git -c commit.gpgsign=false commit \
  -m "feat(moor): apply its flags outside the theme" \
  -m "moor's line-number, one-screen and status-bar flags have nothing to do
with the theme, yet only the themed shell set them, so moor started from
zsh or on Linux ran without them. They become MOOR's session value. moor
reads that one variable and the themed shell replaces it whole, so each
Variant's value is its --style= followed by the same flags. MOOR stays
shell-only beside PAGER."
```

### Task C7.5: Delete the path-themes builder

**Files:**

- Delete:
  - `modules/home/nushell/path-themes.sh` (1-30);
  - `modules/home/nushell/path-themes/variant.env` (1-17);
  - `modules/home/nushell/path-themes/variant.gitconfig` (1-7). The
    `path-themes/` directory goes with it.
- Modify: `modules/home/nushell.nix`: in the let block, the comment that starts
  "Per-variant variables generated here" and the bindings `gitconfigTemplate`,
  `envTemplate` and `pathThemes` (14-51 at a07c2f4), and the `pathThemes`
  replacement in `themeDirs` (59 at a07c2f4).
- Modify: `modules/home/nushell/theme-dirs.nuon`: line 22, `"@pathThemes@"`.

**Interfaces:**

- Consumes: C7.1 to C7.4. All six variables are declared by their owners.
- Produces: `theme-dirs.nuon`'s placeholders become exactly `@extras@` and
  `@variantVariables@`. No derivation named `dracula-path-themes` remains.

- [ ] **Step 1: Run the expectation and see it fail**

```sh
drv=$(bash "$TMPDIR/hm-eval.sh" darwin \
  home.activationPackage.drvPath --raw 2>/dev/null)
nix-store --query --requisites "$drv" \
  | grep -c -- '-dracula-path-themes\.drv$'
```

Expected after this task: `0`. It prints `1` now.

- [ ] **Step 2: Delete the template and its builder**

Run:

```sh
git rm modules/home/nushell/path-themes.sh \
  modules/home/nushell/path-themes/variant.env \
  modules/home/nushell/path-themes/variant.gitconfig
```

Then delete, from `nushell.nix`, the comment and three bindings listed under
Files, and `pathThemes = "${pathThemes}";` from `themeDirs`. Delete the
`"@pathThemes@"` line from `theme-dirs.nuon`. Leave the `themeDirs` comment,
which starts "A data file the setup scripts open", as it is. The let block then
runs `extras`, `variantVariables`, `variants`, `variantEnvFile`, ….

- [ ] **Step 3: Format and run the expectation**

Run `"$(.github/scripts/nix-tool.sh nixfmt)" modules/home/nushell.nix`, then
Step 1's commands. Expected: `0`.

Then run:

```sh
git grep -n -E \
  'pathThemes|path-themes|variant\.env|variant\.gitconfig' -- modules
```

Expected: no output.

- [ ] **Step 4: Check the shell's view against the golden values**

Run C7.1 Step 2's commands. Expected:

```text
DFT_BACKGROUND="dark"
GIT_CONFIG_GLOBAL=true
LUMEN_THEME="dracula"
MOOR="--style=dracula --no-linenumbers --quit-if-one-screen --statusbar=bold"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/pro.conf"
STARSHIP_CONFIG="<extras>/src/starship/pro.toml"
DFT_BACKGROUND="light"
GIT_CONFIG_GLOBAL=true
LUMEN_THEME="catppuccin-latte"
MOOR="--style=tango --no-linenumbers --quit-if-one-screen --statusbar=bold"
RIPGREP_CONFIG_PATH="<extras>/src/ripgrep/alucard.conf"
STARSHIP_CONFIG="<extras>/src/starship/alucard.toml"
```

This is the full `theme-dirs.nuon` list, now without the old template.

- [ ] **Step 5: Run the suite**

Run: `mise run test && mise run lint`. Expected: both pass. The Linux eval
confirms that nothing left in `nushell.nix` forces `${extras}`; `lint:shell` no
longer sees `path-themes.sh`.

- [ ] **Step 6: Commit**

`git rm` in Step 2 already staged the deletions.

```sh
git add modules/home/nushell.nix modules/home/nushell/theme-dirs.nuon
git -c commit.gpgsign=false commit \
  -m "refactor(nushell): drop the path-themes builder" \
  -m "Every Variant variable is declared by its tool's module now, so
path-themes.sh, the env template and the gitconfig template it filled
per Variant go, with the derivation that ran them. The values the shell
loads are unchanged but for the gitconfig shim's store path."
```

After his switch, Patrick checks the one path no eval runs, the Appearance hook:
in a new Nushell window, flip the Appearance and back, then `$env.MOOR`,
`$env.GIT_CONFIG_GLOBAL` (a `…-<variant>.gitconfig` store path) and
`git config user.email` must match the Variant shown.

#### Notes for section C7

- The five helpers live in `$TMPDIR` and are never committed. A task started in
  a fresh session, or after `$TMPDIR` was cleared, first writes them again from
  C7.1 Step 1.
- C7 adds no flake check, `mise` task or CI job: its probes are those scratch
  helpers, and `mise run test` covers the committed state.
- `codebook.toml` gets no words: every word codebook flags in the moved comments
  (`Chroma's`, `difftastic`, `upstream's`) is already flagged at a07c2f4, in
  `variant.env` or `git.nix`. For Patrick: if the rule is read per file, add
  `Chroma's`, which `moor.nix` now carries.

---

## Wheels, formatters, documentation (C6, C8, D)

These tasks run after F, C1.1 to C1.3, C23, C5, C4 and C7. C1.4 waits for
Patrick's work-layer change and may land before or after them; nothing here
depends on it.

Rules for every step below:

- Run every command in this section with the Bash sandbox off, from the worktree
  root, so `nix` works and `$TMPDIR` is the same directory in every call. Shell
  variables do not carry over between calls, so each block defines what it uses.
- `git add` a new file before any flake command reads it.
- Patrick's profile puts uutils first on `PATH`: use `/usr/bin/diff -r` (uutils
  `diff` has no `-r`) and `tail -n 1` (uutils `tail` rejects `-1`).
- Quote every flake reference (`'.#...'`), because zsh's extended glob reads an
  unquoted `#`.
- Where a check says "unchanged", it compares against a capture saved to
  `$TMPDIR` earlier in the same task. No store hash in this section is meant as
  a fixed expected value.
- `nix store prefetch-file --expected-hash` accepts a path already in the store
  without downloading anything, whatever the URL. Every URL check here therefore
  prefetches without `--expected-hash` and compares the hash it prints.
- A path `nix store prefetch-file` adds has no GC root, and Determinate Nix can
  collect it between two calls. A step that prefetches and then dry-runs is
  therefore one script, run as one command.
- Nix snippets are shown within 80 columns. Where a step says so, run nixfmt on
  the file and let its layout stand: it may join a line broken here to fit.
- **The real work layer.** C6.2 and C8.1 change options the work layer sees
  (`home.packages`, the new `my.formatters`), so each also evaluates the real
  configuration, with no `--override-input`, printing only the path or the
  error:

  ```sh
  nix eval --raw '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'
  ```

  Expected: one `.drv` path under `/nix/store`. On an error, stop and report it
  to Patrick: what to fix may live in his work repository.

- Line numbers are as of a07c2f4. Earlier tasks edit some of these files, so
  find every edit by the quoted text:
  - F8 and C23.2: `pkgs/lib/release-binary.nix` (the `binaries` comment, `meta`,
    the `passthru ? { }` argument and the `passthru` merge). C6.1 touches none
    of these places.
  - F9: `pkgs/lib/release-binary/test-archive.nix`, `flake.nix`, `mise.toml`
    (`check:release-binary-archive`), `.github/workflows/ci.yml` (job
    `release-binary-archive`), the checks sentence of `docs/architecture.md` and
    GLOSSARY.md's **Flake check**.
  - F13, C1.1 and C7.1: other GLOSSARY.md entries. The **Release binary** entry
    is untouched before C6.2.
  - C23.1, C23.4, C1 and C5: other parts of `docs/architecture.md`. C23.4
    rewrites the `.lsp.json` sentence of the `pkgs/` bullet. The `pkgs/lib/`
    sentence and the "There is no overlay" sentence are untouched before C6.2
    and D1.
  - C4: `modules/home/claude-code.nix`. The `claudeMdLint` binding and its
    `runtimeInputs` keep their text.
  - Any section may add words to `codebook.toml`. `"djlsp",` stays a stable
    anchor.
- A line starting **After the switch** or **In CI** closes a task whose effect
  no evaluation here shows. It says what Patrick checks, and when.

---

### Task C6.1: The wheel archive kind, proven on both servers

**Files:**

- Modify: `pkgs/lib/release-binary.nix`. At a07c2f4 that is four places:
  - lines 44-59, the `archive` chain from `if lib.hasInfix ".tar." firstUrl` to
    `else "file";`
  - line 68, `lib.optional (archive == "zip") unzip`
  - lines 78-79, the comment above `sourceRoot = ".";`
  - lines 96-103, the `lib.optionalAttrs (archive == ...)` unpack overrides
- Create: `pkgs/lib/release-binary/unpack-wheel.sh`
- Modify: `pkgs/lib/release-binary/test-archive.nix` (F9's `cases` attrset): add
  `".whl" = "wheel";`
- Create: `pkgs/pytest-language-server.nix`
- Create: `pkgs/django-language-server.nix`
- Modify: `codebook.toml`: insert `"djls",` directly above `"djlsp",` (line 47
  at a07c2f4)

**Interfaces:**

- Consumes:
  - F8's `meta.mainProgram` default (the first entry of `binaries`). The package
    files leave `mainProgram` out.
  - F9's `checks.<system>.release-binary-archive`: `cases` in
    `pkgs/lib/release-binary/test-archive.nix` maps a URL suffix to its kind and
    has no order. A failure reads
    `release-binary: <suffix> gave <got>, expected <want>`. F9 runs it as
    `mise run check:release-binary-archive` and in CI's `release-binary-archive`
    job.
  - C23.2's `passthru ? { }`, merged over `{ inherit archive; }`, so `.archive`
    stays readable.
- Produces:
  - `release-binary` archive kind `"wheel"`, chosen when the first asset's URL
    ends in `.whl`. It takes exactly one asset per system. `unzip` is added to
    `nativeBuildInputs`. `unpack-wheel.sh` unzips into `wheel/` and copies each
    name in `binaries` from `wheel/*.data/scripts/<name>` to the build root,
    where the unchanged `install.sh` installs it.
  - The `sourceRoot` comment reads "Every archive but a wheel holds its binaries
    at the root, with no leading directory."
  - `pkgs/pytest-language-server.nix` and `pkgs/django-language-server.nix`.
    Each is `{ lib, callPackage }:` and calls
    `callPackage ./lib/release-binary.nix { } { ... }`. Their outputs:
    - `name`: `pytest-language-server-0.26.0` and `django-language-server-6.1.1`
    - `archive = "wheel"`
    - `meta.mainProgram`: `pytest-language-server` and `djls`
    - `meta.platforms = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ]`

- [ ] **Step 1: Capture the old builder's outputs as the baseline**

`--out-link` roots each output, so garbage collection cannot take the baseline
before Step 9 reads it.

```sh
for name in pytest-language-server django-language-server; do
  out=$(nix build --impure --print-out-paths \
    --out-link "$TMPDIR/wheel-old-$name" --expr "
    let
      f = builtins.getFlake (toString ./.);
      p = f.inputs.nixpkgs.legacyPackages.\${builtins.currentSystem};
      m = import ./modules/home/python-lsps-wheels.nix {
        inherit (p) lib;
        pkgs = p;
      };
    in
    p.lib.findFirst (d: d.pname == \"$name\") null m.home.packages")
  printf '%s\t%s\n' "$name" "$out"
done >"$TMPDIR/wheel-baseline.tsv"
cat "$TMPDIR/wheel-baseline.tsv"
```

Expected: two lines,
`pytest-language-server<TAB>/nix/store/...-pytest-language-server-0.26.0` and
`django-language-server<TAB>/nix/store/...-django-language-server-6.1.1`.

- [ ] **Step 2: Add the `.whl` case to F9's check and see it fail**

In `pkgs/lib/release-binary/test-archive.nix`, add `".whl" = "wheel";` to
`cases`, after `".gz" = "gzip";`. `cases` is an attrset, so the position does
not matter.

Run:

```sh
mise run check:release-binary-archive
nix eval --override-input work path:./stubs/work --raw \
  '.#checks.x86_64-linux.release-binary-archive.drvPath'
```

Expected: both exit non-zero, and each error ends with
`error: release-binary: .whl gave file, expected wheel`. The check asserts
during evaluation, so the second command fails exactly as CI's Linux job would.

- [ ] **Step 3: Add the wheel kind to the builder**

In `pkgs/lib/release-binary.nix`:

1. In the `archive` chain, add this between the `.gz` branch and the final
   `else "file"`:

   ```nix
   else if lib.hasSuffix ".whl" firstUrl then
     "wheel"
   ```

2. Change `lib.optional (archive == "zip") unzip` to
   `lib.optional (archive == "zip" || archive == "wheel") unzip`.

3. The comment above `sourceRoot = ".";` becomes:

   ```nix
       # Every archive but a wheel holds its binaries at the root, with no
       # leading directory.
   ```

4. Directly above the `// lib.optionalAttrs (archive == "file") {` override,
   add:

   ```nix
     # A wheel is one asset; its binaries are copied out of its
     # `*.data/scripts/` to the root.
     // lib.optionalAttrs (archive == "wheel") {
       unpackPhase = builtins.readFile ./release-binary/unpack-wheel.sh;
     }
   ```

Create `pkgs/lib/release-binary/unpack-wheel.sh`:

```sh
# shellcheck shell=bash

# `$srcs` and `$binaries` are set by Nix; a wheel is one asset, a zip
# holding each binary under `<name>-<version>.data/scripts/`.
# shellcheck disable=SC2154,SC2086
runHook preUnpack
unzip -q "$srcs" -d wheel
for binary in $binaries; do
  cp wheel/*.data/scripts/"$binary" .
done
runHook postUnpack
```

Then run:

```sh
git add pkgs/lib/release-binary/unpack-wheel.sh
"$(.github/scripts/nix-tool.sh nixfmt)" --check pkgs/lib/release-binary.nix \
  pkgs/lib/release-binary/test-archive.nix
awk 'length > 72 && /^ *#/ { print FILENAME ":" FNR }' \
  pkgs/lib/release-binary.nix pkgs/lib/release-binary/unpack-wheel.sh
```

Expected: nixfmt exits 0, and `awk` prints nothing.

- [ ] **Step 4: Run the check on both systems and see it pass**

Run the two Step 2 commands again. Expected: the mise task exits 0, and the eval
prints a `/nix/store/...-release-binary-archive.drv` path.

- [ ] **Step 5: Write the package probe and see it fail**

Save `$TMPDIR/wheel-pkgs.sh`:

```sh
#!/usr/bin/env bash
set -euo pipefail
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
    pkg = n: p.callPackage (./pkgs + "/${n}.nix") { };
  in
  map (n: let d = pkg n; in
    [ d.name d.archive d.meta.mainProgram d.meta.platforms ])
    [ "pytest-language-server" "django-language-server" ]' | jq .
```

Run `bash "$TMPDIR/wheel-pkgs.sh"`. Expected:
`error: path '<worktree>/pkgs/pytest-language-server.nix' does not exist`.

- [ ] **Step 6: Create the two package files**

Create `pkgs/pytest-language-server.nix`. It carries no `mainProgram`, because
F8's default supplies it. Each `<... URL>` placeholder stands for a string too
long to show here; the rules for it follow the block.

```nix
# The pytest language server. Not in nixpkgs, and PyPI ships it as a
# Rust binary inside a wheel with no Python in it, so the wheel is
# unpacked as a release binary rather than installed as a package.
{ lib, callPackage }:

let
  # @VERSION https://pypi.org/project/pytest-language-server/#history
  version = "0.26.0";
in
callPackage ./lib/release-binary.nix { } {
  pname = "pytest-language-server";
  inherit version;

  # PyPI's name-based path, which redirects to the file itself, so a
  # bump changes only `version` and the hashes. x86_64-darwin is left
  # out because nixpkgs no longer supports it, and the musl wheels
  # because NixOS is glibc.
  assets = {
    aarch64-darwin = {
      url = "<aarch64-darwin URL>";
      hash = "sha256-4HSmD3NjR55aAiMle1F4Oe08jzv4+j+PTrZCekYq6fY=";
    };
    aarch64-linux = {
      url = "<aarch64-linux URL>";
      hash = "sha256-Poni5HFnZsR4eAGnlEFHr55NGoRnm9DZg0BnXSitiF8=";
    };
    x86_64-linux = {
      url = "<x86_64-linux URL>";
      hash = "sha256-GgOOTdvaFeFApYm9/12UrZXbvkdBH6VB1h7KVy4e7a0=";
    };
  };

  meta = {
    description = "Language server for pytest";
    homepage = "https://github.com/bellini666/pytest-language-server";
    license = lib.licenses.mit;
  };
}
```

Each placeholder becomes one string on one line, its four parts joined with
nothing between them:

1. `https://files.pythonhosted.org/packages/py3/p/pytest-language-server/`
2. `pytest_language_server-${version}-py3-none-`, with `${version}` kept as
   written: it is the file's only interpolation
3. the system's platform tag:
   - aarch64-darwin: `macosx_11_0_arm64`
   - aarch64-linux: `manylinux2014_aarch64.manylinux_2_17_aarch64`
   - x86_64-linux: `manylinux2014_x86_64.manylinux_2_17_x86_64`
4. `.whl`

Create `pkgs/django-language-server.nix` in the same shape:

```nix
# djls, the Django language server. Not in nixpkgs, and PyPI ships it
# as a Rust binary inside a wheel with no Python in it, so the wheel
# is unpacked as a release binary rather than installed as a package.
{ lib, callPackage }:

let
  # @VERSION https://pypi.org/project/django-language-server/#history
  version = "6.1.1";
in
callPackage ./lib/release-binary.nix { } {
  pname = "django-language-server";
  inherit version;

  # The binary is `djls`, not the package name: the wheel ships
  # `…data/scripts/djls` and the Zed extension looks for exactly
  # that, so any other name leaves this copy unused.
  binaries = [ "djls" ];

  # PyPI's name-based path, which redirects to the file itself, so a
  # bump changes only `version` and the hashes. x86_64-darwin is left
  # out because nixpkgs no longer supports it, and the musl wheels
  # because NixOS is glibc.
  assets = {
    aarch64-darwin = {
      url = "<aarch64-darwin URL>";
      hash = "sha256-zPEnKT+Z+5r024YbzASuDyrMcZr7pcWevXXW57ngQhI=";
    };
    aarch64-linux = {
      url = "<aarch64-linux URL>";
      hash = "sha256-buUHEYFJ1Jl7UIfUlLAeB1+LNNdYvAwgIVrbCiUbfQc=";
    };
    x86_64-linux = {
      url = "<x86_64-linux URL>";
      hash = "sha256-D8MKnXTY3qsCIj75UkAFbCMZbPGVA0X+lHZkRU8QbEs=";
    };
  };

  meta = {
    description = "Language server for Django projects and templates";
    homepage = "https://github.com/joshuadavidthomas/django-language-server";
    license = lib.licenses.asl20;
  };
}
```

The binaries comment is carried over from
`modules/home/python-lsps-wheels.nix:40-42` unchanged. Its placeholders are
joined the same way, from:

1. `https://files.pythonhosted.org/packages/py3/d/django-language-server/`
2. `django_language_server-${version}-py3-none-`
3. the system's platform tag:
   - aarch64-darwin: `macosx_11_0_arm64`
   - aarch64-linux: `manylinux_2_17_aarch64.manylinux2014_aarch64`
   - x86_64-linux: `manylinux_2_17_x86_64.manylinux2014_x86_64`
4. `.whl`

The manylinux tags of the two packages come in opposite orders. Copy them
exactly. nixfmt leaves long strings alone, so its check below still means
something; a mis-joined URL shows up in Step 8 as `MISMATCH`, because Step 8
prefetches every URL these files evaluate to.

Then run:

```sh
git add pkgs/pytest-language-server.nix pkgs/django-language-server.nix
"$(.github/scripts/nix-tool.sh nixfmt)" --check \
  pkgs/pytest-language-server.nix pkgs/django-language-server.nix
```

Expected: exit 0.

- [ ] **Step 7: Run the package probe and see it pass**

Run `bash "$TMPDIR/wheel-pkgs.sh"`. Expected:

```text
[
  [
    "pytest-language-server-0.26.0",
    "wheel",
    "pytest-language-server",
    [
      "aarch64-darwin",
      "aarch64-linux",
      "x86_64-linux"
    ]
  ],
  [
    "django-language-server-6.1.1",
    "wheel",
    "djls",
    [
      "aarch64-darwin",
      "aarch64-linux",
      "x86_64-linux"
    ]
  ]
]
```

- [ ] **Step 8: Check every name-based URL against its hash, and what a Linux
      build still needs**

The fixed-output paths are already in the store, because the file names and
hashes have not changed, so no build here fetches the new URLs. The script reads
each URL and hash out of the two package files and downloads the URL without
`--expected-hash` (see the rules above), which makes it the only check that the
URLs resolve. With the Linux wheels then in the store, the dry-run shows that a
Linux build of either package needs nothing but its own derivation and the
binary cache.

Save `$TMPDIR/wheel-urls.sh` and run it as one command,
`bash "$TMPDIR/wheel-urls.sh"`:

```sh
#!/usr/bin/env bash
set -euo pipefail
nix eval --impure --raw --expr '
  let
    f = builtins.getFlake (toString ./.);
    lp = f.inputs.nixpkgs.legacyPackages;
    inherit (lp.aarch64-darwin) lib;
    src = s: n:
      builtins.head (lp.${s}.callPackage (./pkgs + "/${n}.nix") { }).srcs;
    line = s: n: "${(src s n).url} ${(src s n).outputHash}\n";
  in
  lib.concatMapStrings
    (s: lib.concatMapStrings (line s)
      [ "pytest-language-server" "django-language-server" ])
    [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ]' \
  | while read -r url hash; do
    got=$(nix store prefetch-file --json "$url" 2>/dev/null \
      | jq -r .hash) || got=none
    if [ "$got" = "$hash" ]; then
      echo "ok ${url##*/}"
    else
      echo "MISMATCH $url"
    fi
  done
for s in aarch64-linux x86_64-linux; do
  for n in pytest-language-server django-language-server; do
    nix build --dry-run --impure --expr "
      let f = builtins.getFlake (toString ./.); in
      f.inputs.nixpkgs.legacyPackages.$s.callPackage ./pkgs/$n.nix { }" \
      2>&1 | sed -n '/will be built/,/will be fetched/p'
  done
done
```

Expected: six `ok <wheel file name>` lines, then this block four times (pytest,
django, pytest, django; django's derivation is
`django-language-server-6.1.1.drv`), each followed by its
`these <n> paths will be fetched (...)` line:

```text
this derivation will be built:
  /nix/store/<hash>-pytest-language-server-0.26.0.drv
```

A `.whl.drv` in a block means its prefetched wheel was collected before the
dry-run: run the script again.

- [ ] **Step 9: Build both packages and compare them with the baseline**

```sh
for name in pytest-language-server django-language-server; do
  new=$(nix build --impure --no-link --print-out-paths --expr "
    let
      f = builtins.getFlake (toString ./.);
      p = f.inputs.nixpkgs.legacyPackages.\${builtins.currentSystem};
    in
    p.callPackage ./pkgs/$name.nix { }")
  old=$(awk -F '\t' -v n="$name" '$1 == n { print $2 }' \
    "$TMPDIR/wheel-baseline.tsv")
  /usr/bin/diff -r "$old" "$new" && echo "$name identical"
  "$new"/bin/* --version
done
rm -f "$TMPDIR"/wheel-old-*
```

Expected, in order:

```text
pytest-language-server identical
pytest-language-server 0.26.0
django-language-server identical
djls 6.1.1
```

- [ ] **Step 10: Add the new comment jargon to the word list**

Run:

```sh
/etc/profiles/per-user/patrick/bin/codebook-lsp -r . lint -u \
  pkgs/pytest-language-server.nix pkgs/django-language-server.nix \
  pkgs/lib/release-binary/unpack-wheel.sh
```

Expected: `djls` at `django-language-server.nix:1:3`, plus `pname`, which is an
identifier and is ignored. Insert `"djls",` in `codebook.toml` directly above
`"djlsp",`. Re-run the lint. Expected: only `pname`.

- [ ] **Step 11: Run the suites**

Run `mise run test` and `mise run lint`. Expected: both exit 0. The old module
still supplies the servers at this point, and the new files have no consumer
yet.

- [ ] **Step 12: Commit**

```sh
git add codebook.toml pkgs/lib/release-binary.nix \
  pkgs/lib/release-binary/unpack-wheel.sh \
  pkgs/lib/release-binary/test-archive.nix \
  pkgs/pytest-language-server.nix pkgs/django-language-server.nix
git -c commit.gpgsign=false commit \
  -m "refactor(pkgs): unpack wheels as release binaries" \
  -m "The Rust language servers PyPI ships as wheels had a builder of their
own that repeated release-binary's fetch, signing, patching and
install. A \`wheel\` archive kind, read off a \`.whl\` URL, lets
release-binary unpack them, and PyPI's name-based URLs leave a bump
only the version and the hashes to change. Both packages build
byte-identical to the old builder's output."
```

**After the switch**: nothing changes on the Mac, because both outputs are
byte-identical (Step 9). The Linux unpack and autoPatchelf run for the first
time on a Linux host; CI only evaluates the Linux packages.

---

### Task C6.2: Install the servers from pkgs/ and drop the wheel builder

**Files:**

- Modify: `modules/home/python-lsps.nix` (whole file, lines 1-14)
- Modify: `home/patrick/common.nix`: delete the line
  `../../modules/home/python-lsps-wheels.nix` (line 68 at a07c2f4)
- Modify: `modules/home/darwin/python-lsps.nix`, lines 3-6 (the comment naming
  `python-lsps-wheels.nix`)
- Delete: `modules/home/python-lsps-wheels.nix`
- Delete: `pkgs/lib/python-lsp-wheel.nix`,
  `pkgs/lib/python-lsp-wheel/install.sh`, `pkgs/lib/python-lsp-wheel/unpack.sh`
- Modify: `docs/architecture.md`: only the `pkgs/lib/` sentence of the `pkgs/`
  bullet, from "`pkgs/lib/` holds the builders packages share" to "...never
  fills them from `pkgs`." (lines 45-50 at a07c2f4)
- Modify: `GLOSSARY.md`: the **Release binary** definition (line 80 at a07c2f4)

**Interfaces:**

- Consumes: C6.1's `pkgs/pytest-language-server.nix` and
  `pkgs/django-language-server.nix`. C23.4's sentence in the `pkgs/` bullet,
  which this task leaves as it is.
- Produces:
  - `modules/home/python-lsps.nix` adds both packages to `home.packages`,
    filtered by `lib.meta.availableOn pkgs.stdenv.hostPlatform`.
  - `pkgs/lib/` holds exactly two builders, `release-binary.nix` and
    `bun-package.nix`.
  - Neither `python-lsp-wheel.nix` nor `python-lsps-wheels.nix` exists
    afterwards.
  - The `pkgs/lib/` sentence of `docs/architecture.md` reads: "`pkgs/lib/` holds
    the builders packages share, `release-binary.nix` for upstream release
    binaries and the Rust language servers PyPI ships as wheels, and
    `bun-package.nix` for npm tarballs bun runs; a caller reaches one through
    `callPackage` and passes its own arguments in a second call, so
    `callPackage` never fills them from `pkgs`."
  - GLOSSARY.md **Release binary**: "A prebuilt binary an upstream publishes, on
    its release page or in a registry such as PyPI, packaged rather than built."

- [ ] **Step 1: Write the consumer probe and see it fail**

Save `$TMPDIR/wheel-consumer.sh`:

```sh
#!/usr/bin/env bash
set -euo pipefail
darwin='darwinConfigurations.Patricks-MacBook-Pro'
apply='ps: map (p: [ p.name (p.archive or null) ])
  (builtins.filter (p: builtins.elem (p.pname or "")
    [ "pytest-language-server" "django-language-server" ]) ps)'
for c in "$darwin.config.home-manager.users.patrick" \
  'homeConfigurations."patrick@linux".config'; do
  nix eval --override-input work path:./stubs/work --json \
    ".#$c.home.packages" --apply "$apply" | jq -c '.[]'
done
```

Run `bash "$TMPDIR/wheel-consumer.sh"`. Expected, the same two lines for each
configuration, because the old builder sets no `archive`:

```text
["pytest-language-server-0.26.0",null]
["django-language-server-6.1.1",null]
["pytest-language-server-0.26.0",null]
["django-language-server-6.1.1",null]
```

- [ ] **Step 2: Rewrite the consumer**

Replace `modules/home/python-lsps.nix` with the following. The `djlint` comment
is kept as written. The pointer comment at lines 3-4 is removed.

```nix
{ lib, pkgs, ... }:
{
  home.packages = [
    (pkgs.callPackage ../../pkgs/djlsp.nix { })

    # No language server has diagnostics for a Django template --
    # neither djlsp nor djls -- so an unclosed `{% for %}` is caught by
    # this instead. It is a CLI, so it cannot reach either editor's
    # gutter and belongs in a pre-commit hook.
    pkgs.djlint
  ]
  # A system with no wheel gets no server rather than a broken one.
  ++ lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) [
    (pkgs.callPackage ../../pkgs/pytest-language-server.nix { })
    (pkgs.callPackage ../../pkgs/django-language-server.nix { })
  ];
}
```

Run
`"$(.github/scripts/nix-tool.sh nixfmt)" --check modules/home/python-lsps.nix`.
Expected: exit 0.

- [ ] **Step 3: Delete the old module and builder**

Delete the line `../../modules/home/python-lsps-wheels.nix` from
`home/patrick/common.nix`. Then:

```sh
git rm modules/home/python-lsps-wheels.nix pkgs/lib/python-lsp-wheel.nix \
  pkgs/lib/python-lsp-wheel/install.sh pkgs/lib/python-lsp-wheel/unpack.sh
```

- [ ] **Step 4: Repoint the comment in the darwin module**

In `modules/home/darwin/python-lsps.nix`, lines 3-6 become:

```nix
  # path-server is published for aarch64-apple-darwin alone, so unlike
  # the wheel-based servers in modules/home/python-lsps.nix it cannot
  # be selected per platform. It completes filesystem paths in any
  # buffer, despite arriving through the Python pass.
```

- [ ] **Step 5: Update the builder sentence and the glossary**

In `docs/architecture.md`, replace only the sentence from "`pkgs/lib/` holds the
builders packages share" to "...so `callPackage` never fills them from `pkgs`."
with this one:

```markdown
`pkgs/lib/` holds the builders packages share, `release-binary.nix` for upstream
release binaries and the Rust language servers PyPI ships as wheels, and
`bun-package.nix` for npm tarballs bun runs; a caller reaches one through
`callPackage` and passes its own arguments in a second call, so `callPackage`
never fills them from `pkgs`.
```

It stays inside the bullet, so indent each of its lines by two spaces, as the
bullet's other lines are. The sentences before it, C23.4's `.lsp.json` sentence
included, stay as they are. If the agent hook flags the new lines, that is
expected: the prettier run below reflows them.

In `GLOSSARY.md`, replace the **Release binary** definition,
`A prebuilt binary from an upstream release page, packaged rather than built.`,
with these two lines, exactly as wrapped here. The agent hook rejects an
unwrapped line.

```markdown
A prebuilt binary an upstream publishes, on its release page or in a registry
such as PyPI, packaged rather than built.
```

Then run:

```sh
prettier=$(.github/scripts/nix-tool.sh prettier)
"$prettier" --write --parser=markdown --prose-wrap=always --print-width=80 \
  docs/architecture.md GLOSSARY.md
"$prettier" --check --parser=markdown --prose-wrap=always --print-width=80 \
  docs/architecture.md GLOSSARY.md
```

Expected: `All matched files use Prettier code style!`. With C23.4's sentence in
place, the bullet's tail reflows to:

```text
  `config` Helix's `languages.toml` gives eight of the servers (ADR-0014).
  `pkgs/lib/` holds the builders packages share, `release-binary.nix` for
  upstream release binaries and the Rust language servers PyPI ships as wheels,
  and `bun-package.nix` for npm tarballs bun runs; a caller reaches one through
  `callPackage` and passes its own arguments in a second call, so `callPackage`
  never fills them from `pkgs`.
```

- [ ] **Step 6: Run the consumer probe and see it pass**

Run `bash "$TMPDIR/wheel-consumer.sh"`. Expected, the same two lines for each
configuration:

```text
["pytest-language-server-0.26.0","wheel"]
["django-language-server-6.1.1","wheel"]
["pytest-language-server-0.26.0","wheel"]
["django-language-server-6.1.1","wheel"]
```

- [ ] **Step 7: Check that unsupported systems are filtered out**

```sh
nix eval --impure --json --expr '
  let
    f = builtins.getFlake (toString ./.);
    p = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
    on = s: n: p.lib.meta.availableOn (p.lib.systems.elaborate s)
      (p.callPackage (./pkgs + "/${n}.nix") { });
  in
  map (s: map (on s) [ "pytest-language-server" "django-language-server" ])
    [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ]'
```

Expected: `[[true,true],[false,false],[true,true],[true,true]]`

- [ ] **Step 8: Check that nothing still refers to the old files**

Run:

```sh
git grep -n -e python-lsps-wheels -e python-lsp-wheel -e mkWheelLsp \
  -- ':!docs/superpowers'
```

Expected: no output, exit 1.

- [ ] **Step 9: Run the suites and the real work layer**

Run `mise run test` and `mise run lint`. Expected: both exit 0. Then run the
real-work-layer eval from the rules above. Expected: a `.drv` path.

- [ ] **Step 10: Commit**

```sh
git add -u modules/home/python-lsps.nix modules/home/darwin/python-lsps.nix \
  home/patrick/common.nix docs/architecture.md GLOSSARY.md
git -c commit.gpgsign=false commit \
  -m "refactor(python-lsps): drop the wheel builder" \
  -m "pytest-language-server and djls now come from their own pkgs/ files
through release-binary, so python-lsps.nix installs them beside djlsp,
filtered by lib.meta.availableOn as before, and the wheel builder and
the module that held their pins go."
```

---

### Task C8.1: `my.formatters`, the editors' wrappers by name

**Files:**

- Modify: `modules/home/formatters.nix` (whole file, lines 1-68)
- Modify: `modules/home/claude-code.nix`, line 74 at a07c2f4: the
  `(pkgs.callPackage ../../pkgs/prettier-with-plugins.nix { })` entry in
  `claudeMdLint`'s `runtimeInputs`. Earlier tasks move lines in this file, so
  find it by that text.

**Interfaces:**

- Produces: `my.formatters`. It is declared and set in
  `modules/home/formatters.nix` (portable) as
  `lib.types.attrsOf lib.types.package` with `readOnly = true`. Each key is a
  wrapper's binary name, and its value is a derivation with that wrapper at
  `bin/<key>`. The keys are:
  - `dockerfmt-1nl`, `helmfmt-stdin`, `jqfmt-1nl`, `pgfmt-1nl`
  - `prettier-astro`, `prettier-awk`, `prettier-gherkin`, `prettier-ini`,
    `prettier-jinja`, `prettier-json5`, `prettier-md`. All seven are the same
    `pkgs/prettier-with-plugins.nix` derivation.
- Paths, each followed by `.my.formatters.<name>`:
  - On macOS: `darwinConfigurations.Patricks-MacBook-Pro` then
    `.config.home-manager.users.patrick`
  - Elsewhere: `homeConfigurations."patrick@linux".config`
- `home.packages` gets the plain tools and
  `lib.unique (lib.attrValues config.my.formatters)`, so prettier-with-plugins
  is installed once.
- `claudeMdLint` takes `config.my.formatters.prettier-md`.
  `modules/home/formatters.nix` is the only `callPackage` of
  `pkgs/prettier-with-plugins.nix` in `modules/`.

- [ ] **Step 1: Capture what must not change**

```sh
darwin='darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
for c in "$hm" 'homeConfigurations."patrick@linux".config'; do
  nix eval --override-input work path:./stubs/work --json \
    ".#$c.home.packages" \
    --apply 'ps: builtins.sort builtins.lessThan (map (p: p.name) ps)'
done >"$TMPDIR/formatters-names.before"
nix eval --override-input work path:./stubs/work --raw \
  ".#$hm.home.packages" --apply '
    ps: (builtins.head (builtins.filter
      (p: (p.pname or "") == "prettier-with-plugins") ps)).outPath
  ' >"$TMPDIR/prettier.before"
```

Expected: `formatters-names.before` holds two JSON lines. `prettier.before`
holds one `/nix/store/...-prettier-with-plugins-<version>` path.

- [ ] **Step 2: Evaluate the option and see it fail**

```sh
darwin='darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
nix eval --override-input work path:./stubs/work --json \
  ".#$hm.my.formatters" --apply 'builtins.mapAttrs (n: d: d.name)' \
  | jq .
```

Expected: an `error: flake '.../filefish' does not provide attribute ...`
message whose last quoted attribute path ends in
`.users.patrick.my.formatters'`.

- [ ] **Step 3: Declare `my.formatters` in `formatters.nix`**

Replace `modules/home/formatters.nix` with the following. Every comment is
carried over: the AWK/INI/Jinja comment moves onto the `prettierWithPlugins`
binding, the jqfmt flags paragraph moves onto `jqfmt-1nl` (rewrapped for its
deeper indent), and `# jqfmt deletes every comment in a filter.` stays above
`pkgs.jqfmt`. The option's keys follow `java.nix`'s `my.java.jdk`: `type`,
`readOnly`, `default`, `description`.

```nix
{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  helmfmt = pkgs.callPackage ../../pkgs/helmfmt.nix { };
  pgfmt = pkgs.callPackage ../../pkgs/pgfmt.nix { };

  # pgfmt emits two trailing newlines, jqfmt and dockerfmt none, and the
  # file then flickers between one and two blank lines against the
  # editors' "ensure final newline".
  oneNewline =
    name: cmd:
    pkgs.writeShellScriptBin name (
      substituteFile ./formatters/one-newline.sh { inherit cmd; }
    );

  # helmfmt takes file paths, not stdin, while both editors hand a
  # formatter the buffer on stdin.
  helmfmtStdin = pkgs.writeShellScriptBin "helmfmt-stdin" (
    substituteFile ./formatters/helmfmt-stdin.sh {
      coreutils = "${pkgs.coreutils}";
      helmfmt = lib.getExe helmfmt;
    }
  );

  # AWK, INI and Jinja, each through a Prettier plugin. See
  # pkgs/prettier-with-plugins.nix: the parser names are not the
  # language names, and the plugins must live in a node_modules tree
  # beside prettier.
  prettierWithPlugins =
    pkgs.callPackage ../../pkgs/prettier-with-plugins.nix { };
in
{
  options.my.formatters = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    readOnly = true;
    default = {
      dockerfmt-1nl =
        oneNewline "dockerfmt-1nl" "${lib.getExe pkgs.dockerfmt}";
      helmfmt-stdin = helmfmtStdin;
      # The three flags are what make it a formatter: with none at
      # all it emits a single line. `-op` takes jqfmt's own operator
      # names rather than the symbols, which its error message lists.
      # It leaves a trailing space on every line it breaks, which
      # Zed's remove_trailing_whitespace_on_save takes off.
      jqfmt-1nl =
        oneNewline "jqfmt-1nl" "${lib.getExe pkgs.jqfmt} -ar -ob -op pipe";
      pgfmt-1nl = oneNewline "pgfmt-1nl" "${lib.getExe pgfmt}";
    }
    // lib.genAttrs [
      "prettier-astro"
      "prettier-awk"
      "prettier-gherkin"
      "prettier-ini"
      "prettier-jinja"
      "prettier-json5"
      "prettier-md"
    ] (_: prettierWithPlugins);
    description = "The Formatter wrappers the editors run, by binary name.";
  };

  # Formatters that are a plain CLI rather than a language server.
  config.home.packages = [
    # General YAML formatters destroy charts -- oxfmt and
    # yaml-language-server both rewrite `{{ x }}` into `{ { x } }` and
    # exit 0. helmfmt aligns Go-template control blocks and leaves raw
    # YAML structure alone.
    helmfmt

    pkgs.dockerfmt

    pgfmt

    # `xmllint --format`, which reads stdin when given `-`.
    pkgs.libxml2

    # jqfmt deletes every comment in a filter.
    pkgs.jqfmt

    # Kanban and treemap diagrams are missing from the formatter's type
    # table and lose the indentation their structure depends on.
    (pkgs.callPackage ../../pkgs/mermaid-formatter.nix { })

    pkgs.nufmt
  ]
  ++ lib.unique (lib.attrValues config.my.formatters);
}
```

`lib.unique` compares derivations by `outPath`, which installs
prettier-with-plugins once. Then run:

```sh
"$(.github/scripts/nix-tool.sh nixfmt)" modules/home/formatters.nix
awk 'length > 72 && /^ *#/ { print FILENAME ":" FNR }' \
  modules/home/formatters.nix
```

Expected: nixfmt joins the four bindings broken here to fit (`oneNewline`'s
body, `prettierWithPlugins`, `dockerfmt-1nl`, `jqfmt-1nl`) onto one line each;
let that stand. `awk` prints nothing.

- [ ] **Step 4: Point the Markdown agent hook at the same derivation**

In `modules/home/claude-code.nix`, replace
`(pkgs.callPackage ../../pkgs/prettier-with-plugins.nix { })` in
`claudeMdLint`'s `runtimeInputs` with `config.my.formatters.prettier-md`. Then
run:

```sh
git grep -n 'callPackage ../../pkgs/prettier-with-plugins.nix' -- modules
```

Expected: exactly one line, in `modules/home/formatters.nix` (the
`prettierWithPlugins` binding).

- [ ] **Step 5: Evaluate the option on both configurations and see it pass**

Run the Step 2 command, then the same with the Linux path:

```sh
linux='homeConfigurations."patrick@linux".config'
nix eval --override-input work path:./stubs/work --json \
  ".#$linux.my.formatters" --apply 'builtins.mapAttrs (n: d: d.name)' \
  | jq .
```

Expected from each, with the prettier version at a07c2f4 (it follows
flake.lock):

```text
{
  "dockerfmt-1nl": "dockerfmt-1nl",
  "helmfmt-stdin": "helmfmt-stdin",
  "jqfmt-1nl": "jqfmt-1nl",
  "pgfmt-1nl": "pgfmt-1nl",
  "prettier-astro": "prettier-with-plugins-3.9.10",
  "prettier-awk": "prettier-with-plugins-3.9.10",
  "prettier-gherkin": "prettier-with-plugins-3.9.10",
  "prettier-ini": "prettier-with-plugins-3.9.10",
  "prettier-jinja": "prettier-with-plugins-3.9.10",
  "prettier-json5": "prettier-with-plugins-3.9.10",
  "prettier-md": "prettier-with-plugins-3.9.10"
}
```

- [ ] **Step 6: Check that the installed packages and the prettier derivation
      did not change**

```sh
darwin='darwinConfigurations.Patricks-MacBook-Pro'
hm="$darwin.config.home-manager.users.patrick"
for c in "$hm" 'homeConfigurations."patrick@linux".config'; do
  nix eval --override-input work path:./stubs/work --json \
    ".#$c.home.packages" \
    --apply 'ps: builtins.sort builtins.lessThan (map (p: p.name) ps)'
done >"$TMPDIR/formatters-names.after"
cmp "$TMPDIR/formatters-names.before" "$TMPDIR/formatters-names.after"
now=$(nix eval --override-input work path:./stubs/work --raw \
  ".#$hm.my.formatters.prettier-md.outPath")
[ "$now" = "$(cat "$TMPDIR/prettier.before")" ] && echo same
```

Expected: `cmp` prints nothing, then `same`. The `cmp` is also what catches a
duplicate: prettier-with-plugins appears once per line, as before. The home-path
and system drvPaths do change, because `home.packages` is reordered (the
wrappers now follow the plain tools); do not expect an identical system drvPath
from this commit.

- [ ] **Step 7: Run the suites and the real work layer**

Run `mise run test` and `mise run lint`. Expected: both exit 0. Then run the
real-work-layer eval from the rules above. Expected: a `.drv` path.

- [ ] **Step 8: Commit**

```sh
git add modules/home/formatters.nix modules/home/claude-code.nix
git -c commit.gpgsign=false commit \
  -m "feat(formatters): declare my.formatters" \
  -m "The editors run the formatter wrappers formatters.nix builds, while CI
and the Markdown agent hook each called prettier on their own. A
read-only my.formatters, wrapper name to derivation, is the one place
to take the editor's own derivation from, and the agent hook now does."
```

---

### Task C8.2: CI checks Markdown with `prettier-md`

**Files:**

- Modify: `.github/scripts/nix-tool.sh` (whole file, lines 1-31)
- Modify: `.github/scripts/markdown-format.sh` (whole file, lines 1-10)
- `.github/workflows/ci.yml` stays as it is. Its "Format check Markdown" step
  (lines 56-57 at a07c2f4) runs the script.

**Interfaces:**

- Consumes: C8.1's `my.formatters`.
- Produces: the CLI below.
  - `nix-tool.sh ATTR [BINARY]` is unchanged.
  - `nix-tool.sh --formatter NAME`:
    - It builds `.#<user>.my.formatters.<NAME>`. `<user>` is
      `darwinConfigurations.Patricks-MacBook-Pro` followed by
      `.config.home-manager.users.patrick` when `uname -s` is `Darwin`, and
      `homeConfigurations."patrick@linux".config` otherwise.
    - On success it prints `<out>/bin/<NAME>` and exits 0.
    - When the build has no `bin/<NAME>`, it prints
      `nix-tool.sh: my.formatters.<NAME> has no bin/<NAME>` to stderr and
      exits 1.
  - `markdown-format.sh` runs `prettier-md --check` over `git ls-files '*.md'`,
    so CI follows whatever flags the wrapper carries.

- [ ] **Step 1: See the new form fail**

Run `.github/scripts/nix-tool.sh --formatter prettier-md; echo "exit=$?"`.
Expected:

- stderr ends with `nix-tool.sh: --formatter has no bin/prettier-md`
- the last stdout line is `exit=1`

- [ ] **Step 2: Add `--formatter` to `nix-tool.sh`**

Replace `.github/scripts/nix-tool.sh` with the following. The existing comments
stay; the second usage line and the `--formatter` paragraph are new, and the
`attr`/`binary` assignments move into the `if`. It passes shfmt with the
repository's flags and shellcheck as written.

```sh
#!/usr/bin/env bash

# Usage: nix-tool.sh ATTR [BINARY]
#        nix-tool.sh --formatter NAME
#
# Prints the path of BINARY (ATTR by default) from the flake's own
# nixpkgs, the one the editor's copy comes from. A nixpkgs reference
# rebuilt out of flake.lock can resolve a different version, and CI
# would then disagree with the editor.
#
# --formatter prints the path of the wrapper NAME from `my.formatters`,
# the derivation the editor itself runs.
#
# The macOS configuration on a Mac and the Linux home configuration
# elsewhere, so the binary runs on the machine asking for it.
set -euo pipefail

case "$(uname -s)" in
  Darwin)
    config='darwinConfigurations.Patricks-MacBook-Pro'
    user="$config.config.home-manager.users.patrick"
    ;;
  *)
    config='homeConfigurations."patrick@linux"'
    user="$config.config"
    ;;
esac

if [ "$1" = --formatter ]; then
  attr=my.formatters.$2
  installable=".#$user.$attr"
  binary=$2
else
  attr=$1
  installable=".#$config.pkgs.$attr"
  binary=${2:-$1}
fi

while read -r out; do
  if [ -x "$out/bin/$binary" ]; then
    printf '%s\n' "$out/bin/$binary"
    exit 0
  fi
done < <(nix build --no-link --print-out-paths \
  --override-input work path:./stubs/work "$installable")

echo "nix-tool.sh: $attr has no bin/$binary" >&2
exit 1
```

- [ ] **Step 3: Resolve every formatter**

```sh
for n in dockerfmt-1nl helmfmt-stdin jqfmt-1nl pgfmt-1nl prettier-astro \
  prettier-awk prettier-gherkin prettier-ini prettier-jinja prettier-json5 \
  prettier-md; do .github/scripts/nix-tool.sh --formatter "$n"; done
```

Expected: eleven lines, each `/nix/store/<hash>-<drv>/bin/<n>`. The first four
have `<drv>` equal to `<n>`. The last seven share one
`<hash>-prettier-with-plugins-<version>`.

Then run `.github/scripts/nix-tool.sh --formatter nope; echo "exit=$?"`.
Expected: stderr ends with `nix-tool.sh: my.formatters.nope has no bin/nope`,
and the last line is `exit=1`.

Then run `.github/scripts/nix-tool.sh libxml2.bin xmllint` and
`.github/scripts/nix-tool.sh nixfmt`. Expected:
`...-libxml2-<v>-bin/bin/xmllint` and `...-nixfmt-<v>/bin/nixfmt`, as before.

- [ ] **Step 4: Check from the Mac that the Linux path evaluates**

```sh
linux='homeConfigurations."patrick@linux".config'
nix eval --override-input work path:./stubs/work --raw \
  ".#$linux.my.formatters.prettier-md.drvPath"
```

Expected: `/nix/store/<hash>-prettier-with-plugins-<version>.drv`.

- [ ] **Step 5: Prove what CI's first Linux build of prettier-md needs**

CI's Markdown check now builds prettier-with-plugins for x86_64-linux, which no
machine has built before, including the linux-x64-gnu Astro binding F5
re-pinned. There is no Linux builder here, but every npm tarball the Linux
derivation fetches can be downloaded and its hash compared (without
`--expected-hash`, see the rules above), and a dry-run then shows what is left
to build.

Save `$TMPDIR/linux-prettier.sh` and run it as one command,
`bash "$TMPDIR/linux-prettier.sh"`:

```sh
#!/usr/bin/env bash
set -euo pipefail
linux='homeConfigurations."patrick@linux".config'
drv=$(nix eval --override-input work path:./stubs/work --raw \
  ".#$linux.my.formatters.prettier-md.drvPath")
nix derivation show -r "$drv" | jq -r '
  .derivations as $d
  | [$d[] | select(.name == "prettier-plugin-tarballs")
    | .inputs.drvs | keys[]][]
  | $d[.] | select(.outputs.out.hash)
  | "\(.structuredAttrs.urls[0]) \(.outputs.out.hash)"' \
  | while read -r url hash; do
    got=$(nix store prefetch-file --json "$url" 2>/dev/null \
      | jq -r .hash) || got=none
    if [ "$got" = "$hash" ]; then
      echo "ok ${url##*/}"
    else
      echo "MISMATCH $url"
    fi
  done
nix build --dry-run "$drv^out" 2>&1 \
  | sed -n '/will be built/,/will be fetched/p'
```

Expected: eighteen `ok <tarball>` lines,
`compiler-binding-linux-x64-gnu-0.5.3.tgz` among them, then this block, followed
by its `these <n> paths will be fetched (...)` line:

```text
these 2 derivations will be built:
  /nix/store/<hash>-prettier-plugin-tarballs.drv
  /nix/store/<hash>-prettier-with-plugins-<version>.drv
```

Any `.tgz.drv` in the list means its prefetched tarball was collected before the
dry-run: run the script again. What stays unproven is
`pkgs/prettier-with-plugins/install.sh` running on x86_64-linux.

- [ ] **Step 6: Run the wrapper in `markdown-format.sh`**

Replace the file with the following. The comment that restated the wrapper's
flags goes:

```sh
#!/usr/bin/env bash

set -euo pipefail

prettier_md=$(.github/scripts/nix-tool.sh --formatter prettier-md)
git ls-files '*.md' | xargs -r "$prettier_md" --check
```

- [ ] **Step 7: Run it on the tree**

Run `.github/scripts/markdown-format.sh`. Expected: `Checking formatting...` and
`All matched files use Prettier code style!`, exit 0.

- [ ] **Step 8: Check that it fails on a long line**

This proves the wrapper's `--prose-wrap=always --print-width=80` are in force.

```sh
long='This paragraph is one line that runs well past the eighty columns'
printf '\n%s prettier-md wraps prose at, on purpose.\n' "$long" >>README.md
.github/scripts/markdown-format.sh; echo "exit=$?"
git checkout -- README.md
```

Expected: `[warn] README.md`, then prettier's
`[warn] Code style issues found in the above file.` line, then `exit=123`. The
123 comes from `xargs`. Afterwards `git status --short README.md` prints
nothing.

- [ ] **Step 9: Run the suites**

Run `mise run test` and `mise run lint`. Expected: both exit 0. `lint:markdown`
now goes through the new form.

- [ ] **Step 10: Commit**

```sh
git add .github/scripts/nix-tool.sh .github/scripts/markdown-format.sh
git -c commit.gpgsign=false commit \
  -m "ci: check Markdown with the editor's prettier-md" \
  -m "markdown-format.sh restated prettier-md's flags against bare prettier,
so a change to the wrapper left CI holding Markdown to the old rules.
nix-tool.sh --formatter resolves a wrapper from my.formatters under
either configuration, and the Markdown check runs the wrapper itself."
```

**In CI**: after Patrick pushes, the `check` job's "Format check Markdown" step
is the first real build of the Linux prettier-with-plugins and the first run of
the `--formatter` Linux branch. Check that it passes before reading a red
Markdown check as a formatting problem.

---

### Task D1: ADR-0015, no package scope for pkgs/

**Files:**

- Create: `docs/adr/0015-no-package-scope-for-pkgs.md`
- Modify: `docs/architecture.md`, line 42 at a07c2f4: the sentence
  `There is no overlay: each consumer calls ...` in the `pkgs/` bullet. C23.4
  and C6.2 rewrote later sentences of the same bullet.

**Interfaces:**

- Consumes: C6.2's state, in which `pkgs/lib/` holds two builders. C8.2's
  `nix-tool.sh --formatter prettier-md`.
- Produces: ADR-0015, linked from `docs/architecture.md`.

- [ ] **Step 1: Check the facts the ADR states**

Run each command and compare with its expected output:

1. `ls pkgs/lib/*.nix`. Expected: `pkgs/lib/bun-package.nix` and
   `pkgs/lib/release-binary.nix`, so "both builders" is true.
2. `git show --stat --format= 5a3c7ee | tail -n 1`. Expected, after git's
   leading space: `14 files changed, 18 insertions(+), 15 deletions(-)`, the two
   builders and their twelve callers.
3. `git show --name-only --format= 5a3c7ee | grep -vc '^pkgs/'`. Expected: `0`.
4. `git grep -nE 'callPackage (\.\./)+pkgs/claude-code\.nix' -- modules`.
   Expected: two lines, in `modules/home/claude-code.nix` and
   `modules/home/darwin/zed.nix`. If an earlier task moved one, update the ADR's
   example to match.
5. Run:

   ```sh
   nix eval --impure --raw --expr '
     let
       f = builtins.getFlake (toString ./.);
       p = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
     in
     (p.callPackage ./pkgs/claude-code.nix { }).drvPath'
   ```

   Expected: it fails with
   `error: Refusing to evaluate package 'claude-code-<version>'`, and the same
   line ends `because it has an unfree license (‘unfree’)`.

- [ ] **Step 2: Write the ADR**

Create `docs/adr/0015-no-package-scope-for-pkgs.md` with exactly this text
(already formatted with prettier-md at 80 columns):

```markdown
# Packages in pkgs/ are called by path, with no package scope

Every consumer reaches a package in `pkgs/` through
`pkgs.callPackage ../../pkgs/<name>.nix { }`, and there is neither an overlay
nor a package scope. A scope built with `lib.makeScope` would give modules one
attribute set to take packages from, but only as one more hand-kept list naming
every package. Nor can it reach modules as a special argument, the way
`substituteFile` does: special arguments are fixed in `flake.nix` before the
host's `pkgs` exists, and that `pkgs` is what carries
`config.allowUnfreePredicate` from `my.allowUnfree`. A scope built at the flake
level from nixpkgs alone refuses to evaluate `pkgs/claude-code.nix`, since
nixpkgs' claude-code is unfree. Calling by path already keeps a change to
`pkgs/` inside `pkgs/`: 5a3c7ee moved both builders and their twelve callers to
a two-stage call, fourteen files, and touched no module.

The cost is that a package two modules use is called twice, from two relative
paths, as `pkgs/claude-code.nix` is from `modules/home/claude-code.nix` and
`modules/home/darwin/zed.nix`; both calls yield the same derivation.
```

Then run `git add docs/adr/0015-no-package-scope-for-pkgs.md`.

- [ ] **Step 3: Link it from the architecture**

In `docs/architecture.md`, change `There is no overlay: each consumer` to
`There is no overlay and no package scope (ADR-0015): each consumer`. If the
agent hook flags the now over-long line, that is expected: the prettier run
below reflows it. Then run:

```sh
prettier_md=$(.github/scripts/nix-tool.sh --formatter prettier-md)
"$prettier_md" --write docs/architecture.md
```

With C23.4's and C6.2's sentences in place, the whole bullet reflows to:

```text
- `pkgs/` holds derivations nixpkgs lacks. There is no overlay and no package
  scope (ADR-0015): each consumer calls
  `pkgs.callPackage ../../pkgs/<name>.nix { }`. `pkgs/claude-marketplace/` is
  the local marketplace; `modules/home/claude-code.nix` renders the LSP plugin's
  `.lsp.json` from `claude-code/nix-lsp.json`'s commands and the `config`
  Helix's `languages.toml` gives eight of the servers (ADR-0014). `pkgs/lib/`
  holds the builders packages share, `release-binary.nix` for upstream release
  binaries and the Rust language servers PyPI ships as wheels, and
  `bun-package.nix` for npm tarballs bun runs; a caller reaches one through
  `callPackage` and passes its own arguments in a second call, so `callPackage`
  never fills them from `pkgs`.
```

- [ ] **Step 4: Check formatting, lint and spelling**

Run `.github/scripts/markdown-format.sh` and `.github/scripts/markdown-lint.sh`.
Expected: `All matched files use Prettier code style!` and
`Summary: 0 issues in 0 files`. Then run:

```sh
/etc/profiles/per-user/patrick/bin/codebook-lsp -r . lint \
  docs/adr/0015-no-package-scope-for-pkgs.md
```

Expected: `Found 0 spelling error(s)`.

- [ ] **Step 5: Run the suites**

Run `mise run test` and `mise run lint`. Expected: both exit 0.

- [ ] **Step 6: Commit**

```sh
git add docs/adr/0015-no-package-scope-for-pkgs.md docs/architecture.md
git -c commit.gpgsign=false commit \
  -m "docs: decide against a package scope" \
  -m "A lib.makeScope for pkgs/ came up in the architecture review. It would
be one more hand-kept list, and as a special argument it cannot see
the host's unfree predicate, while calling by path already keeps a
change to pkgs/ inside pkgs/. Recorded so it is not proposed again."
```

---

### Task D2: ADR-0016, Appearance followers stay one central list

**Files:**

- Create: `docs/adr/0016-appearance-followers-stay-one-central-list.md`

**Interfaces:**

- Produces: ADR-0016. It names the follower list by its binding, `links`, and
  not by its file, so the ADR stays true when issue 31's move to a portable
  `modules/home/appearance.nix` lands.

- [ ] **Step 1: Check the facts the ADR states**

Issue reads go through `gh` inside Nushell, as `docs/agents/issue-tracker.md`
says. When `gh` cannot get its token (the `nu -l` login asks 1Password, which
fails with `Run 'op signin'` in a session that cannot sign in), the `github` MCP
`issue_read` gives the same facts: `get` reports `"state":"closed"` and
`"closed_at":"2026-11-10T14:04:59Z"`, and `get_comments` returns the bodies the
phrase check reads.

Run each command and compare with its expected output:

1. Run:

   ```sh
   cmd='gh issue view 31 --repo pgodschalk/nix-config'
   nu -l -c "$cmd --json state,closedAt --jq '.state + \" \" + .closedAt'"
   ```

   Expected: `CLOSED 2026-11-10T14:04:59Z`.

2. The "Resolution (grilling, 2026-11-10)" comment must hold each phrase below.
   The comment bolds some of them
   (`**A machine without them gets nothing**: no theme hook ...`), so the
   phrases avoid the markup. Run:

   ```sh
   cmd='gh issue view 31 --repo pgodschalk/nix-config'
   nu -l -c "$cmd --json comments --jq '.comments[].body'" \
     >"$TMPDIR/issue31.txt"
   for p in \
     'One Appearance state per machine' \
     'On remotes, `my.theme.dracula.{pro,extras}` point at store paths' \
     'A machine without them gets nothing' \
     'no theme hook and default palettes' \
     'The switch moves into a portable `modules/home/appearance.nix`'; do
     if grep -qF -- "$p" "$TMPDIR/issue31.txt"; then
       echo "ok $p"
     else
       echo "MISSING $p"
     fi
   done
   ```

   Expected: five `ok` lines.

3. `git grep -n '^  links = \[' -- modules`. Expected: one line,
   `modules/home/darwin/appearance.nix:15:  links = [`, or the portable path if
   issue 31's move has landed.
4. `git grep -n -e config-dark.toml -e config-light.toml -- modules`. Expected:
   four lines, two in `modules/home/helix.nix` and two in the module that holds
   `links`.

- [ ] **Step 2: Write the ADR**

Create `docs/adr/0016-appearance-followers-stay-one-central-list.md` with
exactly this text. The issue number is a link so that prettier never wraps `#31`
to the start of a line, where markdownlint reads it as a heading (MD018).

```markdown
# Appearance followers stay one central list

The followers, the tools that can follow neither the Appearance nor an
environment variable, are listed in one place: `links` in the module that holds
the switch, beside Claude Code's theme key, which the same switch rewrites. A
Registry was the alternative, each tool's module declaring its own follower,
with a machine that runs no switch linking the dark Variant statically. Issue
[#31](https://github.com/pgodschalk/nix-config/issues/31), closed on 2026-11-10,
rules that fallback out: the switch becomes portable and follows one Appearance
state that every machine keeps, remotes get the theme checkouts as store paths,
and a machine without them gets default palettes rather than a fixed Variant. No
machine is left for a static link to serve. Without the fallback, a Registry
only spreads a handful of entries over as many modules, while the list shows in
one place which tools still need a link moved under them.

The cost is that a follower's files are named twice: Helix's dark and light
configurations are written by `modules/home/helix.nix` and named again in
`links`.
```

Then run `git add docs/adr/0016-appearance-followers-stay-one-central-list.md`.

- [ ] **Step 3: Check formatting, lint and spelling**

Run `.github/scripts/markdown-format.sh` and `.github/scripts/markdown-lint.sh`.
Expected: `All matched files use Prettier code style!` and
`Summary: 0 issues in 0 files`. Then run:

```sh
/etc/profiles/per-user/patrick/bin/codebook-lsp -r . lint \
  docs/adr/0016-appearance-followers-stay-one-central-list.md
```

Expected: `Found 0 spelling error(s)`.

- [ ] **Step 4: Run the suites**

Run `mise run test` and `mise run lint`. Expected: both exit 0.

- [ ] **Step 5: Commit**

```sh
git add docs/adr/0016-appearance-followers-stay-one-central-list.md
git -c commit.gpgsign=false commit \
  -m "docs: decide one list of Appearance followers" \
  -m "The architecture review weighed a per-tool Registry of followers with
a static dark fallback. Issue #31 already settled a portable switch on
one Appearance state per machine, which leaves the fallback nothing to
serve, so the followers stay one list beside the switch."
```

#### Notes for section C6+C8+D

- Beyond the Spec, for Patrick to confirm: C6.2 widens GLOSSARY.md's **Release
  binary** to registries such as PyPI, because "from an upstream release page"
  stops being true once the wheels are release binaries. C8.1 also points the
  Markdown agent hook (`claudeMdLint`) at `my.formatters.prettier-md`, so the
  hook, the editors and CI share one derivation.
- `my.formatters` holds only the eleven wrappers, the Spec's "wrapper name to
  derivation"; the plain tools stay in `home.packages`. It is `readOnly`, so the
  work layer cannot add a wrapper; that would take a mergeable option.
- The `wheel` kind assumes one asset per system: `unpack-wheel.sh` unzips
  `$srcs` as one path. Only the builder's comment says so; nothing checks it.
- The real-work-layer eval runs in C6.2 and C8.1, the tasks that change options
  the work layer sees. C6.1 changes only `pkgs/`, C8.2 only CI scripts, and D1
  and D2 only documents, so they skip it.
- C8.2 leaves `CLAUDE.md`, `mise.toml` and `ci.yml` alone: each still describes
  `markdown-format.sh` truly, and F13's CONTRIBUTING.md wording ("Most checks
  run the same tool the editor runs") stays true too.
- The ADR numbers assume C23 took 0014. If another ADR lands first, take the
  next free numbers and change D1's `(ADR-0015)` link to match. ADR-0016 is
  linked from nowhere.
- Issue 31's resolution says "No ADR" for its own decisions. ADR-0016 is written
  anyway, because the Spec's Documentation-only list asks for it, and it records
  only the rejected per-tool Registry.
