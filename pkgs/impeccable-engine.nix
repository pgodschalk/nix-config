# The engine behind the impeccable skill.
{ lib, callPackage }:

let
  # Bump with impeccableSrc in modules/home/claude-skills.nix, which
  # asserts the two agree.
  # @VERSION https://github.com/pbakaus/impeccable/releases
  version = "0.1.18";
  base = "https://github.com/pbakaus/impeccable/releases/download/engine-v${version}";
in
callPackage ./lib/release-binary.nix { } {
  pname = "impeccable-engine";
  inherit version;

  assets = {
    aarch64-darwin = {
      url = "${base}/impeccable-darwin-arm64";
      hash = "sha256-VD7i9yA2rRhdyZkaw7qGt02R+Yjz1Jd3agiLi2XIqeE=";
    };
    aarch64-linux = {
      url = "${base}/impeccable-linux-arm64";
      hash = "sha256-MXyxjWSw93FWgd1uV0rWSyrbWmyvjnobO1eWX4BUBL4=";
    };
    x86_64-linux = {
      url = "${base}/impeccable-linux-x64";
      hash = "sha256-c27XhedK4jRNMDYSf2FN3eWrUgpSfYvIKokWEu9x9kg=";
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
