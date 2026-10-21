# A language server for Apple's Metal Shading Language, not in nixpkgs.
# Its diagnostics are the compiler's own words: it shells out to
# `xcrun metal` from the Metal toolchain modules/darwin/xcode.nix
# downloads rather than reimplementing a front end.
#
# It hardcodes ~/.metal-analyzer for its log and index cache, and
# panics at start-up if it cannot create the log there.
#
# Only aarch64-darwin is packaged. Rosetta is ruled out, and there is no
# Linux build because there is no Metal toolchain to drive.
{ lib, callPackage }:

let
  # @VERSION https://github.com/computer-graphics-tools/metal-analyzer/releases
  version = "0.1.26";
in
callPackage ./lib/release-binary.nix { } {
  pname = "metal-analyzer";
  inherit version;

  assets.aarch64-darwin = {
    url = "https://github.com/computer-graphics-tools/metal-analyzer/releases/download/${version}/metal-analyzer-aarch64-apple-darwin.tar.gz";
    # Matches upstream's signed SHA256SUMS for this asset.
    hash = "sha256-x7w5efbxBGK+s5h4OQg7aGJSJ7/YyhbO2E0XP1ZGyyc=";
  };

  meta = {
    description = "Language server for Apple's Metal Shading Language";
    homepage = "https://github.com/computer-graphics-tools/metal-analyzer";
    license = lib.licenses.mit;
    mainProgram = "metal-analyzer";
  };
}
