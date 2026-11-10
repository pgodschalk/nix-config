# nixpkgs' oxlint, buildable inside the Darwin sandbox. Its build runs
# @napi-rs/cli 3.10.8, which execs `/usr/sbin/ioreg` and
# `/usr/sbin/sysctl` while taking a lock; the sandbox denies both, and
# Node raises that as a synchronous `spawn EPERM` the CLI does not
# catch. nixpkgs redirects only the CLI's `/bin/ps`. The patch is the
# `try`/`catch` that @napi-rs/cli 3.10.12 ships: with no output the
# lock merely falls back to its degraded mode.
#
# `--forward` makes the patch fail once nixpkgs bundles a fixed CLI,
# which is the signal to delete this file and go back to `pkgs.oxlint`.
{ oxlint }:

oxlint.overrideAttrs (previous: {
  napiCliPatch = ./oxlint/napi-cli-spawn-eperm.patch;
  preBuild = (previous.preBuild or "") + builtins.readFile ./oxlint/pre-build.sh;
})
