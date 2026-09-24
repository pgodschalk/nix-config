# Formats Mermaid diagram source. Not in nixpkgs; built from the
# published npm tarball, which is a dependency-free bundle.
#
# It flattens `kanban` and `treemap`, which is accepted: both are absent
# from its internal type table and fall through to generic handling that
# strips leading whitespace, and in both indentation is the structure.
# The other diagram types round-trip cleanly.
{
  lib,
  stdenvNoCC,
  fetchurl,
  bun,
  makeWrapper,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mermaid-formatter";
  # @VERSION https://www.npmjs.com/package/mermaid-formatter
  version = "0.3.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/mermaid-formatter/-/mermaid-formatter-${finalAttrs.version}.tgz";
    hash = "sha256-PKv0cFTu7lr8U5raoGhF/xbjEx1cQEvZ9xhSY51jFHQ=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = substituteFile ./mermaid-formatter/install.sh { bun = lib.getExe bun; };

  meta = {
    description = "Formatter for Mermaid diagram syntax";
    homepage = "https://github.com/chenyanchen/mermaid-formatter";
    license = lib.licenses.mit;
    mainProgram = "mermaidfmt";
    platforms = lib.platforms.all;
  };
})
