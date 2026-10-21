# The engine behind the impeccable skill, pinned so the launcher never
# reaches its download branch and never creates ~/.impeccable. It must
# equal the skill's scripts/VERSION, which
# modules/home/claude-skills.nix asserts.
{ lib, callPackage }:

let
  # @VERSION https://github.com/pbakaus/impeccable/releases
  version = "0.1.16";
  base = "https://github.com/pbakaus/impeccable/releases/download/engine-v${version}";
in
callPackage ./lib/release-binary.nix {
  pname = "impeccable-engine";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "${base}/impeccable-darwin-arm64";
      hash = "sha256-XADDEwuWHzqhBm8E7Q4fWOh4CK0VPvoA8cRBhIAAhPI=";
    };
    aarch64-linux = {
      url = "${base}/impeccable-linux-arm64";
      hash = "sha256-qaGL+m1wZCcBRG7TsSo+Xm7v5KS0xW7/4wtEnMsynEs=";
    };
    x86_64-linux = {
      url = "${base}/impeccable-linux-x64";
      hash = "sha256-qJCltLfZ157FSqdGErXpJOX1tCJgCiX96Ly9oRsDF4c=";
    };
  };

  binaries = [ "impeccable" ];

  meta = {
    description = "Engine behind the impeccable design skill";
    homepage = "https://github.com/pbakaus/impeccable";
    license = lib.licenses.asl20;
    mainProgram = "impeccable";
  };
}
