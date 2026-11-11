# Map

`docs/architecture.md` is the layout and its conventions; this adds where to
look and what to run.

- `flake.nix`: outputs; `hosts/Patricks-MacBook-Pro/default.nix` is the system
- `apps.nix`: App Store ids, casks and package lists; most edits land here
- `modules/darwin/`: nix-darwin, imported one by one from the host file
- `modules/home/`: portable home-manager, listed in `home/patrick/common.nix`
- `modules/home/darwin/`: macOS home-manager, listed in
  `home/patrick/darwin.nix`
- `modules/home/<name>/`: the scripts, jq, TOML and Nushell of
  `modules/home/<name>.nix`
- `pkgs/<name>.nix`, `pkgs/<name>/`: derivations nixpkgs lacks, called with
  `pkgs.callPackage`
- `stubs/work/`: empty stand-in for the private `work` input
- `.github/scripts/`: one script per CI check; `mise run lint:<language>` wraps
  them
- `docs/adr/`: decisions; `CONTEXT.md`: the glossary

## Change together

- a new module and its import list (`common.nix`, `darwin.nix` or the host)
- an unfree package and `my.allowUnfree` in the host file
- jargon in a comment and `codebook.toml`

## Checks

- The scripts read `git ls-files`; jj adds new files to the index on its next
  command, plain git needs `git add`.
- Run `mise run eval:darwin` before `mise run eval:linux`; `mise run test` does
  both in order.

## Formatting

`.orca/format.sh FILE < FILE` prints FILE formatted with CI's flags, for one
file of any language the checks cover.
