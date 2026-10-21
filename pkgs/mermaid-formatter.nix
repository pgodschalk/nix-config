# Formats Mermaid diagram source. Not in nixpkgs; built from the
# published npm tarball, which is a dependency-free bundle.
#
# It flattens `kanban` and `treemap`, which is accepted: both are absent
# from its internal type table and fall through to generic handling that
# strips leading whitespace, and in both indentation is the structure.
# The other diagram types round-trip cleanly.
{ lib, callPackage }:

let
  # @VERSION https://www.npmjs.com/package/mermaid-formatter
  version = "0.3.0";
in
callPackage ./lib/bun-package.nix {
  pname = "mermaid-formatter";
  inherit version;
  hash = "sha256-PKv0cFTu7lr8U5raoGhF/xbjEx1cQEvZ9xhSY51jFHQ=";
  entry = "dist/cli.js";
  binary = "mermaidfmt";
  postInstall = ./mermaid-formatter/post-install.sh;

  meta = {
    description = "Formatter for Mermaid diagram syntax";
    homepage = "https://github.com/chenyanchen/mermaid-formatter";
    license = lib.licenses.mit;
  };
}
