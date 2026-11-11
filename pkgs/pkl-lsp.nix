# Language server for Pkl. nixpkgs' 0.8.0 writes ~/.pkl and ignores
# XDG_CACHE_HOME, and builds from source through a Gradle dependency
# cache; the released jar keeps its own cache and data under XDG from
# 0.9.0. The `pkl` CLI it calls does not; modules/home/pkl.nix wraps
# it.
{
  lib,
  stdenvNoCC,
  fetchurl,
  jdk25_headless,
  makeWrapper,
  substituteFile ? (import ../lib lib).substituteFile,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pkl-lsp";
  # @VERSION https://github.com/apple/pkl-lsp/releases
  version = "0.9.0";

  src = fetchurl {
    url = "https://github.com/apple/pkl-lsp/releases/download/${finalAttrs.version}/pkl-lsp-${finalAttrs.version}.jar";
    hash = "sha256-QddNkHUg0KUFGuoSixRePDlpXPg6OE5G2Yx07uLTlZI=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = substituteFile ./pkl-lsp/install.sh { java = lib.getExe' jdk25_headless "java"; };

  meta = {
    description = "Language server for Pkl";
    homepage = "https://github.com/apple/pkl-lsp";
    license = lib.licenses.asl20;
    mainProgram = "pkl-lsp";
    # The platforms the jar bundles tree-sitter natives for.
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
})
