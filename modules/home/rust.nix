{ config, pkgs, ... }:
let
  # mr-boxington, a build cache for Cargo.
  mbx = pkgs.callPackage ../../pkgs/mbx.nix { };
in
{
  home.sessionVariables = {
    # Both default to a hidden directory in the home directory. rustup
    # is not installed here, but mise's Rust backend drives it and
    # honours the same two variables.
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
  };

  my.launchd.extraVariables = [
    "CARGO_HOME"
    "RUSTUP_HOME"
  ];

  # The Cargo shim, ahead of the profile's cargo, so a plain `cargo`
  # goes through mbx. A project whose mise.toml pins Rust puts mise's
  # cargo in front of it again, and bypasses mbx unless that pin sets
  # `mr_boxington = true`.
  home.sessionPath = [ "${mbx}/libexec/mbx" ];

  home.packages = [
    # A wrapper that exports RUST_SRC_PATH, so the standard library
    # resolves with no rust-src component installed.
    pkgs.rust-analyzer

    # A floor: rust-analyzer loads a workspace through `cargo metadata`,
    # checks it with `cargo check` and formats through rustfmt, and the
    # editors spawn it without mise's PATH. A repo pinning its own
    # toolchain through mise still wins in a shell.
    pkgs.cargo
    pkgs.rustc
    pkgs.rustfmt

    mbx
  ];
}
