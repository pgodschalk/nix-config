# Contributing

This repository configures one machine: my own. That shapes what is worth
contributing. Settings, package choices and keybindings are personal preference
and are unlikely to be merged, however reasonable the argument. What is welcome
is anything that is wrong on its own terms:

- a derivation under `pkgs/` that fails to build, or builds something broken;
- a module whose behaviour contradicts its own comments;
- a pinned version or revision that has gone stale;
- a macOS assumption that has leaked into the portable half of `modules/home/`;
- documentation that no longer matches the code.

Please open an issue before a larger change, so neither of us spends an evening
on something that was never going to land.

Note this project has a [code of conduct](CODE_OF_CONDUCT.md); please follow it
in all your interactions with the project.

## Development environment setup

You need Nix with flakes enabled. [Determinate Nix] is what this repository is
built and tested against, but any recent Nix works for evaluating and building.

1. Clone the repository:

   ```sh
   git clone https://github.com/pgodschalk/nix-config.git
   cd nix-config
   ```

2. Track your files. Flakes only see what git knows about, so a new file that
   has not been `git add`ed produces a confusing "path does not exist" error
   naming the file rather than the cause:

   ```sh
   git add <your new files>
   ```

3. Check that the macOS configuration still evaluates. This forces the whole
   module tree; it fetches a few sources at evaluation time but builds no
   system:

   ```sh
   nix eval --raw --override-input work path:./stubs/work \
     '.#darwinConfigurations.Patricks-MacBook-Pro.system.drvPath'
   ```

4. Check that the portable half still evaluates for Linux. This is what catches
   a macOS assumption that has escaped `modules/home/darwin/`, and it is easy to
   break without noticing:

   ```sh
   nix eval --raw --override-input work path:./stubs/work \
     '.#homeConfigurations."patrick@linux".activationPackage.drvPath'
   ```

`--override-input work path:./stubs/work` is required. The `work` input is a
private tree that exists only on my machine; `stubs/work` is an empty stand-in
so everything else still evaluates without it.

On a Mac you can go further and build the whole system without activating it:

```sh
nix build --override-input work path:./stubs/work \
  '.#darwinConfigurations.Patricks-MacBook-Pro.system'
```

You probably shouldn't run `darwin-rebuild switch`: activation writes to `/etc`,
`/Library` and the authorization database.

## Checks

CI runs linting, formatting, type checking and schema validation for every
language in the repository, and every check is a script under `.github/scripts/`
that you can run yourself, on macOS or Linux. Each takes its tool from the
flake, so Nix is the only thing to install:

```sh
.github/scripts/nix-format.sh
.github/scripts/nix-lint.sh
.github/scripts/shell-lint.sh
```

The tools are deliberately the same ones the editor runs, so a file that is
clean in Zed is clean in CI. Where they differ, that is a bug in the
configuration rather than something to work around.

## Issues and feature requests

Found a bug, a mistake in the documentation, or have an idea? You can help by
[submitting an issue][issues]. Search the archive first -- yours may already be
there.

Bug reports are most useful when they are:

- _Reproducible._ Include the exact command and its output.
- _Specific._ Include the macOS version, the Nix version, and whether the
  problem survives a clean login shell.
- _Unique._ Do not duplicate an open issue.
- _Scoped to a single bug._ One bug per report.

**Even better: submit a pull request with the fix.**

## How to submit a pull request

1. Search the [open and closed pull requests][pulls] so you do not duplicate
   work.
2. Fork the project.
3. Create your branch (`git checkout -b fix/stale-pin`).
4. Commit your changes. This repository uses [Conventional
   Commits][conventional]: the subject is at most 50 characters and the body
   wraps at 72. Nothing here installs a git hook to check that, so it is on you.
5. Push the branch (`git push origin fix/stale-pin`).
6. [Open a pull request][compare], describing what changed and how you verified
   it.

[Determinate Nix]: https://docs.determinate.systems/
[compare]: https://github.com/pgodschalk/nix-config/compare?expand=1
[conventional]: https://www.conventionalcommits.org
[issues]: https://github.com/pgodschalk/nix-config/issues
[pulls]: https://github.com/pgodschalk/nix-config/pulls
