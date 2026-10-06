{ config, pkgs, ... }:
{
  home.sessionVariables = {
    # Both default to a hidden directory in the home directory. rustup
    # is not installed here, but mise's Rust backend drives it and
    # honours the same two variables.
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
  };

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
  ];
}
