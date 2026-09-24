# nix-config

One machine, declared end to end: the system, the user environment, every app's
settings and the toolchain behind them.

## Language

### Layering

**Host**:\
One configured machine, as the flake names it.\
_Avoid_: machine, which is the hardware alone

**System module**:\
A nix-darwin module, macOS-only by nature; it lives under `modules/darwin/`.

**Home module**:\
A home-manager module. Portable when it lives in `modules/home/` and must
evaluate on Linux; macOS-only when it lives in `modules/home/darwin/`.

**Portable half**:\
Every home module that must evaluate on Linux.\
_Avoid_: half, for any pair of things other than these two

**macOS half**:\
Every module only macOS sees: the system modules and the macOS-only home
modules.

**Work layer**:\
The private employer configuration, a separate flake that adds modules to both
halves. This repository is nix-config, never its counterpart.\
_Avoid_: work repository, work flake, work input, personal layer

**Stub**:\
The empty stand-in for the work layer, so everything else evaluates without it.

### Applications

**Package**:\
Anything from nixpkgs or `pkgs/` installed into a user profile.

**Cask**:\
A Homebrew cask, unpacked into the store, for an app that is on neither the App
Store nor in nixpkgs.

**App Store app**:\
An app installed from the Mac App Store, only ever from the Purchased list.\
_Avoid_: mas app

**App**:\
A GUI application, whatever its source.\
_Avoid_: application, except in "Application Support"

### Profiles

**User profile**:\
The Nix profile that holds the user's packages.\
_Avoid_: profile, on its own, for any of the four

**Commit profile**:\
A set of commit-message rules and drafting context, selected by the directory a
repository lives in.

**Terminal profile**:\
A Terminal.app profile.

**fnox profile**:\
fnox's own unit: a named set of secrets a tool reads at run time.

### Appearance

**Appearance**:\
The macOS light or dark setting, which every tool follows.\
_Avoid_: theme, for the light or dark choice

**Theme**:\
Dracula Pro, the one theme, in two variants.

**Variant**:\
One of the theme's two faces: Dracula Pro, the dark one, and Alucard, the light
one.\
_Avoid_: Dark and Light as names, outside the file names an app forces

**Theme checkout**:\
One of the two working copies, dracula-pro and dracula-pro-extras, that themes
are linked from; absent on a host without them.\
_Avoid_: working copy

### State

**User state**:\
Anything a tool writes for the user: config, data, cache, history. It belongs
under `~/Library`.

**Dotfile**:\
A file or directory a tool insists on placing in `~`, tolerated only when the
tool hardcodes the name.

**State version**:\
The home-manager or nix-darwin release marker a configuration was written
against.\
_Avoid_: state

### Checks

**Linux eval**:\
The evaluation of the throwaway Linux home configuration, the only check that
catches a leak.

**Leak**:\
A macOS assumption that has reached the portable half.

**Check script**:\
One script under `.github/scripts/`, what CI runs and what can be run by hand.

**Flake check**:\
One of the flake's own checks: the system build and the Linux eval.

### Pins

**Pin**:\
A version, revision or hash fixed by hand in the tree, always under an
`@VERSION` line.

**Lock**:\
What a tool fixes for you: a `flake.lock`, `Gemfile.lock` or
`package-lock.json`.\
_Avoid_: pin, for what a lockfile holds

**Cask pin**:\
A cask's version, which moves only with the `brew-api` input.

### Tooling

**Editor**:\
Zed, when unqualified: the reference whose formatter and language-server
configuration the check scripts share. Helix is always named.

**Wrapper**:\
A script around one tool that fixes its flags or environment, so the editor, CI
and the shell run it identically.\
_Avoid_: shim, alias, which is a Nushell alias and a different thing

**Passthrough wrapper**:\
A wrapper that lets the tool's exit code and output reach the caller unchanged.

**Secret**:\
A value that is never on disk in this tree; it reaches a process at run time
through fnox or `op`, or, for three MCP wrappers, from the login keychain.\
_Avoid_: credential, outside a tool's own name

**Link**:\
A symlink to a file home-manager owns, the default way a setting reaches an app.
A link into a theme checkout leaves the store.

**Render**:\
Writing a real file at activation, because the app rewrites it or a secret is
spliced in.

**Merge**:\
Deep-merging declared keys into a file the app owns and keeps rewriting.

**Activation entry**:\
One home-manager activation script, which is what renders or merges.

**Hook**:\
Always qualified: a **git hook** runs on commit, an **agent hook** is Claude
Code's, a **shell hook** is Nushell's; nixpkgs setup hooks keep their names.\
_Avoid_: hook, on its own

**Language server**:\
The program that serves a language to the editor and the agents.\
_Avoid_: LSP, except for the protocol or inside a name

**Formatter**:\
A CLI the editor hands a buffer on stdin, shared with CI through the same
wrapper or configuration.

**Determinate Nix**:\
The Nix distribution in use; it owns the Nix settings and garbage collection.
Its daemon is written `determinate-nixd` in full.\
_Avoid_: Determinate Nixd, nixd, for either

**nixd**:\
The Nix language server, and nothing else.

### Agents

**Agent**:\
An AI coding tool that reads instructions and skills.

**Subagent**:\
A dispatched agent defined by a Markdown file carrying tools and a model, never
loaded as a skill.

**Agent doc**:\
One of the files under `docs/agents/` the engineering skills read.

**SSH agent**:\
Always qualified. Secretive is the one in use; 1Password's runs but is not.

**Instructions**:\
A CLAUDE.md or AGENTS.md an agent loads: **global instructions** in the Claude
Code config directory, **repository instructions** at a repository root.\
_Avoid_: memory, rules

**Skill**:\
A directory holding a `SKILL.md` an agent can invoke.

**Skill collection**:\
An upstream repository of skills linked in wholesale.

**Plugin**:\
A Claude Code plugin: a bundle of skills, subagents, MCP servers and hooks
offered by a marketplace.\
_Avoid_: plug-in

**Marketplace**:\
A catalogue of plugins. The **local marketplace** is the one this repository
ships.

**MCP server**:\
A tool server registered for every agent that reads a JSON config.
