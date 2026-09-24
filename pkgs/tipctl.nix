# TransIP's official CLI, not in nixpkgs. Distributed as a PHP phar,
# which is why this pulls in a PHP runtime for one tool: transip's Go
# package is a library rather than a CLI, and the third-party CLIs are
# unofficial.
#
# The phar is a built artefact with its dependencies vendored inside, so
# it is taken from the release as-is.
{
  lib,
  stdenvNoCC,
  fetchurl,
  php,
  makeWrapper,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tipctl";
  # @VERSION https://github.com/transip/tipctl/releases
  version = "6.34.10";

  src = fetchurl {
    url = "https://github.com/transip/tipctl/releases/download/v${finalAttrs.version}/tipctl.phar";
    hash = "sha256-PY1fkbY/qTJ/iNh5ez7E5M1EblGOhllzel3llI0JV2Q=";
  };
  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  # Load-bearing: the phar targets an older PHP, so every invocation
  # prints a deprecation notice before any real output.
  #
  # 8191 is `E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED`, written
  # numerically because makeWrapper splices --add-flags into a shell
  # script unquoted and the symbolic form's `&` is read as a background
  # operator. Genuine warnings and errors still show.
  installPhase = substituteFile ./tipctl/install.sh { php = lib.getExe php; };

  meta = {
    description = "Official command-line interface for the TransIP API";
    homepage = "https://github.com/transip/tipctl";
    license = lib.licenses.mit;
    mainProgram = "tipctl";
    platforms = lib.platforms.all;
  };
})
