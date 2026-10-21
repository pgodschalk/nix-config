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
  version = "0.3.7";
in
callPackage ./lib/release-binary.nix { } {
  pname = "css-variable-lsp";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "https://github.com/lmn451/css-lsp-rust/releases/download/v${version}/css-variable-lsp-macos-aarch64.tar.gz";
      hash = "sha256-Y1q8zjAgmTy9c04ow6q/PxlCEtlKxBooCvRRmAWykbg=";
    };
    aarch64-linux = {
      url = "https://github.com/lmn451/css-lsp-rust/releases/download/v${version}/css-variable-lsp-linux-aarch64.tar.gz";
      hash = "sha256-RO/1w7uekG+xdv+x869dngIuV4Vd5XnPnU9uyGie18c=";
    };
    x86_64-linux = {
      url = "https://github.com/lmn451/css-lsp-rust/releases/download/v${version}/css-variable-lsp-linux-x86_64.tar.gz";
      hash = "sha256-0dTbCQS5bVREI4WNOmnSSI4+gDpimYAwdO07/5zpf6o=";
    };
  };

  meta = {
    description = "Language server for project-wide CSS custom property intelligence";
    homepage = "https://github.com/lmn451/css-lsp-rust";
    license = lib.licenses.gpl3Only;
    mainProgram = "css-variable-lsp";
  };
}
