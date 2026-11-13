# The server behind Zed's "CSS Variables (LSP)" extension, not in
# nixpkgs. It completes a custom property defined in another file, which
# vscode-css-language-server cannot: that sees only the buffer in front
# of it, and the point of a token file is that it is a different one.
#
# The repository is `lmn451/css-lsp-rust`, which is the name of neither
# the extension nor the binary.
{ lib, callPackage }:

let
  # @VERSION https://github.com/lmn451/css-lsp-rust/releases
  version = "0.3.8";
in
callPackage ./lib/release-binary.nix { } {
  pname = "css-variable-lsp";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "https://github.com/lmn451/css-lsp-rust/releases/download/v${version}/css-variable-lsp-macos-aarch64.tar.gz";
      hash = "sha256-D/o8RoWq+3qI/sAI/6Wvj4r8H08i6kzAkniDUS5famc=";
    };
    aarch64-linux = {
      url = "https://github.com/lmn451/css-lsp-rust/releases/download/v${version}/css-variable-lsp-linux-aarch64.tar.gz";
      hash = "sha256-vH2goLJYhieA8h0o9tMnO+CRC3iVSoJS3TKNr6yZje8=";
    };
    x86_64-linux = {
      url = "https://github.com/lmn451/css-lsp-rust/releases/download/v${version}/css-variable-lsp-linux-x86_64.tar.gz";
      hash = "sha256-GH6Y/tpNt4+vXX7bWMaVn0gF3sfLbu61YOzSR/6iZFE=";
    };
  };

  meta = {
    description = "Language server for project-wide CSS custom property intelligence";
    homepage = "https://github.com/lmn451/css-lsp-rust";
    license = lib.licenses.gpl3Only;
  };
}
