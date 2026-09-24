# The server behind Zed's "CSS Variables (LSP)" extension, not in
# nixpkgs. It completes a custom property defined in another file, which
# vscode-css-language-server cannot: that sees only the buffer in front
# of it, and the point of a token file is that it is a different one.
#
# The repository is `lmn451/css-lsp-rust`, which is the name of neither
# the extension nor the binary.
{
  lib,
  stdenvNoCC,
  fetchurl,
  darwin,
  autoPatchelfHook,
  stdenv,
}:

let
  # @VERSION https://github.com/lmn451/css-lsp-rust/releases
  version = "0.3.7";

  targets = {
    aarch64-darwin = {
      asset = "macos-aarch64";
      hash = "sha256-Y1q8zjAgmTy9c04ow6q/PxlCEtlKxBooCvRRmAWykbg=";
    };
    aarch64-linux = {
      asset = "linux-aarch64";
      hash = "sha256-RO/1w7uekG+xdv+x869dngIuV4Vd5XnPnU9uyGie18c=";
    };
    x86_64-linux = {
      asset = "linux-x86_64";
      hash = "sha256-0dTbCQS5bVREI4WNOmnSSI4+gDpimYAwdO07/5zpf6o=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "css-variable-lsp: no upstream release asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "css-variable-lsp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/lmn451/css-lsp-rust/releases/download/v${version}/css-variable-lsp-${target.asset}.tar.gz";
    inherit (target) hash;
  };

  nativeBuildInputs =
    lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook
    ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;

  # Upstream's Linux builds are glibc binaries with the FHS loader, so
  # on Linux they are patched to find it and their libraries in the
  # store.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # The tarball holds the bare binary plus licence files, no leading
  # directory.
  sourceRoot = ".";

  dontBuild = true;

  installPhase = builtins.readFile ./css-variable-lsp/install.sh;

  meta = {
    description = "Language server for project-wide CSS custom property intelligence";
    homepage = "https://github.com/lmn451/css-lsp-rust";
    license = lib.licenses.gpl3Only;
    mainProgram = "css-variable-lsp";
    platforms = lib.attrNames targets;
  };
}
