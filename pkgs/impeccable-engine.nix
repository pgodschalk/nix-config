# The engine behind the impeccable skill.
{ lib, callPackage }:

let
  # Bump with impeccableSrc in modules/home/claude-skills.nix, which
  # asserts the two agree.
  # @VERSION https://github.com/pbakaus/impeccable/releases
  version = "0.1.24";
  base = "https://github.com/pbakaus/impeccable/releases/download/engine-v${version}";
in
callPackage ./lib/release-binary.nix { } {
  pname = "impeccable-engine";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "${base}/impeccable-darwin-arm64";
      hash = "sha256-9cw5I6yT/p7AoBRJ6zuPA4WdrgioGVnkQVMzwEK8L4A=";
    };
    aarch64-linux = {
      url = "${base}/impeccable-linux-arm64";
      hash = "sha256-NO9WOWbLlcGzbEUO5ibHJyZnY1efxelamu8oC3SHUIA=";
    };
    x86_64-linux = {
      url = "${base}/impeccable-linux-x64";
      hash = "sha256-0xe9G+Bh/ckCxN7ef98e/R93RIgvtRGh+WL83E7tU4I=";
    };
  };

  binaries = [ "impeccable" ];

  meta = {
    description = "Engine behind the impeccable design skill";
    homepage = "https://github.com/pbakaus/impeccable";
    license = lib.licenses.asl20;
  };
}
