# The official Resend CLI, not in nixpkgs.
#
# Built from the published npm tarball rather than from source, since
# upstream ships a single bundled `dist/cli.cjs` and rebuilding it would
# mean a lockfile to pin for no benefit. Run by bun.
{ lib, callPackage }:

let
  # @VERSION https://www.npmjs.com/package/resend-cli
  version = "2.26.0";
in
callPackage ./lib/bun-package.nix {
  pname = "resend-cli";
  inherit version;
  hash = "sha256-dGnj4Up/UbOtUWJC3JsVVk4ZNDvklEaoHoMpwkhIiq4=";
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
