# The official Resend CLI, not in nixpkgs.
#
# Built from the published npm tarball rather than from source, since
# upstream ships a single bundled `dist/cli.cjs` and rebuilding it would
# mean a lockfile to pin for no benefit. Run by bun.
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
  pname = "resend-cli";
  # @VERSION https://www.npmjs.com/package/resend-cli
  version = "2.21.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/resend-cli/-/resend-cli-${finalAttrs.version}.tgz";
    hash = "sha256-l5E2YXw025mLJufTewl3HTvseARpoCg37QKyhKA7Ns8=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = substituteFile ./resend-cli/install.sh { bun = lib.getExe bun; };

  meta = {
    description = "Official CLI for Resend";
    homepage = "https://github.com/resend/resend-cli";
    license = lib.licenses.mit;
    mainProgram = "resend";
    platforms = lib.platforms.all;
  };
})
