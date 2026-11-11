# SCSS and Sass language server that follows `@use` and `@forward`
# across files, so completion, definition and rename reach variables
# and mixins in other files. Not in nixpkgs.
#
# The npm package bundles its dependencies into `dist/`. The binary
# name matters: Zed's SCSS extension resolves
# `worktree.which("some-sass-language-server")` before npm.
{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  makeWrapper,
  substituteFile ? (import ../lib lib).substituteFile,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "some-sass-language-server";
  # @VERSION https://www.npmjs.com/package/some-sass-language-server
  version = "2.3.9";

  src = fetchurl {
    url = "https://registry.npmjs.org/some-sass-language-server/-/some-sass-language-server-${finalAttrs.version}.tgz";
    hash = "sha512-9/w+pBSKrcZQKBO56k6DoMDk/1G6Q6214zTXcIM9ObsAZ5ic2qESk3BorCrd+fZNsCTH+KQlQIXCv5nCR606lw==";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = substituteFile ./some-sass-language-server/install.sh { node = lib.getExe nodejs; };

  meta = {
    description = "Language server for SCSS and Sass that follows @use across files";
    homepage = "https://github.com/wkillerud/some-sass";
    license = lib.licenses.mit;
    mainProgram = "some-sass-language-server";
    platforms = lib.platforms.all;
  };
})
