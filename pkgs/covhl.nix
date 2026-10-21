# The language server behind Zed's "Test Coverage Highlight"
# extension, reading lcov, JaCoCo, Cobertura and Clover reports. Not in
# nixpkgs.
#
# Packaging it fixes a bug rather than pinning a version: the published
# darwin binary has a broken code signature, so macOS SIGKILLs it and
# it exits 137 with no output, which from Zed looks like a server that
# starts and instantly dies. `autoSignDarwinBinariesHook` re-signs it
# ad hoc.
{ lib, callPackage }:

let
  # @VERSION https://github.com/hyyan/zed-test-coverage-highlight/releases
  version = "0.1.3";
in
callPackage ./lib/release-binary.nix { } {
  pname = "covhl";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "https://github.com/hyyan/zed-test-coverage-highlight/releases/download/v${version}/covhl-aarch64-apple-darwin.gz";
      hash = "sha256-kvXcj9Q/4tp73pmErS+lgtum1r8XnuefhWnHZlRxWQU=";
    };
    aarch64-linux = {
      url = "https://github.com/hyyan/zed-test-coverage-highlight/releases/download/v${version}/covhl-aarch64-unknown-linux-gnu.gz";
      hash = "sha256-fLKwR5YCEtJh9WggIrH2BAUMzInOBYK60o5joJEyh0s=";
    };
    x86_64-linux = {
      url = "https://github.com/hyyan/zed-test-coverage-highlight/releases/download/v${version}/covhl-x86_64-unknown-linux-gnu.gz";
      hash = "sha256-TqI3Y8HBU9/d3PS0GxAApbYlI//PtCynmQxMSKuOd9Y=";
    };
  };

  meta = {
    description = "Language server that surfaces test coverage from lcov, JaCoCo, Cobertura and Clover reports";
    homepage = "https://github.com/hyyan/zed-test-coverage-highlight";
    license = lib.licenses.mit;
    mainProgram = "covhl";
  };
}
