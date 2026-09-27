# The markdownlint rule set as a language server, which Zed's extension
# fetches at run time and Helix has no equivalent for.
#
# buildNpmPackage with a lockfile rather than the pinned tarballs the
# rest of pkgs/ uses, because the closure is 61 packages. The lockfile
# is generated here rather than upstream's, which publishes none: a lock
# generated against the exact version being built cannot go stale and
# make `npm ci` re-resolve inside the sandbox.
#
# To bump: change the version in markdownlint-lsp/package.json, run
#   npm install --package-lock-only --ignore-scripts
# in that directory, then set npmDepsHash to what the build reports.
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:
buildNpmPackage {
  pname = "markdownlint-lsp";
  # @VERSION https://www.npmjs.com/package/markdownlint-lsp
  # Bumping this means bumping ./markdownlint-lsp/package.json and its
  # lockfile too -- JSON takes no comment, so the reminder lives here.
  version = "0.10.0";

  # The pin wrapper rather than upstream's source: package.json names
  # the one dependency and package-lock.json pins its closure.
  src = ./markdownlint-lsp;

  nativeBuildInputs = [ makeWrapper ];

  npmDepsHash = "sha256-xfQ7X7MqEVQLNiFuJlzxoDDHRsU68nZlN3LxgiPzxRs=";

  # A pure dependency fetch; without this npm looks for a `build` script
  # and fails.
  dontNpmBuild = true;

  installPhase = substituteFile ./markdownlint-lsp/install.sh { node = lib.getExe nodejs; };

  meta = {
    description = "Language server for the markdownlint rule set";
    homepage = "https://www.npmjs.com/package/markdownlint-lsp";
    license = lib.licenses.mit;
    mainProgram = "markdownlint-lsp";
    platforms = lib.platforms.all;
  };
}
