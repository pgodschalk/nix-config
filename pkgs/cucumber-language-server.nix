# Step completion, go-to-definition and undefined-step diagnostics for
# Gherkin `.feature` files. Not in nixpkgs.
#
# The Zed extension's npm fallback hardcodes a `bin/*.cjs` path that
# 2.0.0 no longer ships, so `lsp.cucumber.binary` points here instead.
#
# To bump: change the version in cucumber-language-server/package.json,
# run
#   npm install --package-lock-only --ignore-scripts
# in that directory, then set npmDepsHash to what the build reports.
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
  substituteFile ? (import ../lib lib).substituteFile,
}:
buildNpmPackage {
  pname = "cucumber-language-server";
  # @VERSION https://www.npmjs.com/package/@cucumber/language-server
  # Bumping this means bumping ./cucumber-language-server/package.json
  # and its lockfile too -- JSON takes no comment.
  version = "2.0.0";

  src = ./cucumber-language-server;

  nativeBuildInputs = [ makeWrapper ];

  npmDepsHash = "sha256-NOoehKk19w2xEKOCavNtCgaNaj0pS5nZQwKnEC1NcoU=";

  dontNpmBuild = true;

  installPhase = substituteFile ./cucumber-language-server/install.sh {
    node = lib.getExe nodejs;
  };

  meta = {
    description = "Cucumber language server for Gherkin feature files";
    homepage = "https://github.com/cucumber/language-server";
    license = lib.licenses.mit;
    mainProgram = "cucumber-language-server";
    platforms = lib.platforms.all;
  };
}
