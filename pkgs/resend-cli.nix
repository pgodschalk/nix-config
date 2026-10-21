# The official Resend CLI, not in nixpkgs.
#
# Built from the published npm tarball rather than from source, since
# upstream ships a single bundled `dist/cli.cjs` and rebuilding it would
# mean a lockfile to pin for no benefit. Run by bun.
{ lib, callPackage }:

let
  # @VERSION https://www.npmjs.com/package/resend-cli
  version = "2.28.0";
in
callPackage ./lib/bun-package.nix { } {
  pname = "resend-cli";
  inherit version;
  hash = "sha256-tesIvVU60edoxzebccZGSX3+2i2zzRiv9HZsAaszpSc=";
  entry = "dist/cli.cjs";
  binary = "resend";
  copy = [
    "dist"
    "skills"
    "package.json"
  ];
  postInstall = ./resend-cli/post-install.sh;

  meta = {
    description = "Official CLI for Resend";
    homepage = "https://github.com/resend/resend-cli";
    license = lib.licenses.mit;
  };
}
