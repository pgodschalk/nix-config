# Navigation for agent skill files, making `/skill-name` and
# `$skill-name` real symbols. Not in nixpkgs.
#
# Built from the published npm tarball rather than from source, since
# upstream ships a single bundled `dist/main.cjs` and rebuilding it
# would mean a lockfile to pin for no benefit. Its only non-builtin
# `require` is `esprima`, which js-yaml asks for inside a try/catch and
# falls through without -- under bun only with `--no-install`, since
# bun otherwise fetches a missing module from npm at run time.
#
# The binary name matters: Zed's extension resolves
# `worktree.which("skill-language-server")` before falling back to
# `npm_install_package`.
{ lib, callPackage }:

let
  # @VERSION https://www.npmjs.com/package/skill-language-server
  version = "0.8.2";
in
callPackage ./lib/bun-package.nix {
  pname = "skill-language-server";
  inherit version;
  hash = "sha256-mBXlgyzV8z31eliSkeUfqLgP0sFRibPos72cM/aa1Nk=";
  entry = "dist/main.cjs";
  binary = "skill-language-server";

  meta = {
    description = "Language server for agent skill files, making /skill-name and $skill-name real symbols";
    homepage = "https://github.com/CyrusNuevoDia/skill-language-server";
    license = lib.licenses.mit;
  };
}
