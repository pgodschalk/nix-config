# Go-to-definition, hover and completion from a JS or TS component to
# the class it names in a `*.module.css`. Not in nixpkgs.
#
# buildNpmPackage from the tagged source rather than the npm tarball,
# because this one is not a bundle: there is a real dependency tree to
# pin, and upstream commits a package-lock.json.
#
# The binary name matters: the Zed extension resolves
# `worktree.which("cssmodules-language-server")` before falling back to
# `npm_install_package`.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "cssmodules-language-server";
  # @VERSION
  # https://github.com/antonk52/cssmodules-language-server/releases
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "antonk52";
    repo = "cssmodules-language-server";
    rev = "v${finalAttrs.version}";
    hash = "sha256-9RZNXdmBP4OK7k/0LuuvqxYGG2fESYTCFNCkAWZQapk=";
  };

  npmDepsHash = "sha256-1CnCgut0Knf97+YHVJGUZqnRId/BwHw+jH1YPIrDPCA=";

  # No test suite is wired into the default build.
  dontNpmBuild = false;

  meta = {
    description = "Language server for CSS Modules, linking JS/TS to *.module.css";
    homepage = "https://github.com/antonk52/cssmodules-language-server";
    license = lib.licenses.mit;
    mainProgram = "cssmodules-language-server";
    platforms = lib.platforms.all;
  };
})
