# Navigation for agent skill files, making `/skill-name` and
# `$skill-name` real symbols. Not in nixpkgs.
#
# Built from the published npm tarball rather than from source, since
# upstream ships a single bundled `dist/main.cjs` and rebuilding it
# would mean a lockfile to pin for no benefit. Its only non-builtin
# `require` is `esprima`, which js-yaml asks for inside a try/catch and
# falls through without.
#
# The binary name matters: Zed's extension resolves
# `worktree.which("skill-language-server")` before falling back to
# `npm_install_package`.
{
  lib,
  stdenvNoCC,
  fetchurl,
  bun,
  makeWrapper,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "skill-language-server";
  # @VERSION https://www.npmjs.com/package/skill-language-server
  version = "0.8.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/skill-language-server/-/skill-language-server-${finalAttrs.version}.tgz";
    hash = "sha256-ZGW15IR4DNG6kRjFVL9FggbBXo4l+vsU1WbCgYpC4c4=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = substituteFile ./skill-language-server/install.sh { bun = lib.getExe bun; };

  meta = {
    description = "Language server for agent skill files, making /skill-name and $skill-name real symbols";
    homepage = "https://github.com/CyrusNuevoDia/skill-language-server";
    license = lib.licenses.mit;
    mainProgram = "skill-language-server";
    platforms = lib.platforms.all;
  };
})
