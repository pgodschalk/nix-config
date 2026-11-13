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
