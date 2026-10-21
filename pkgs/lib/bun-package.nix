# Builds an npm package that bun runs: fetches the registry tarball,
# copies the named paths to `$out/lib/<pname>` and wraps bun around the
# entry file as `$out/bin/<binary>`. The tarball is a bundle with no
# dependencies to resolve.
#
# The wrapper passes `--no-install`, since bun otherwise fetches a
# module that is missing at run time from npm. A bundle may `require` a
# module it never needs, inside a try/catch that falls through without
# it.
{
  lib,
  stdenvNoCC,
  fetchurl,
  bun,
  makeWrapper,
}:

# Package arguments come in a second call so `callPackage` cannot fill
# a defaulted one from `pkgs`.
{
  pname, # also the npm package name
  version,
  hash, # of the registry tarball
  entry, # path inside the tarball that bun runs
  binary ? pname,
  copy ? [
    "dist"
    "package.json"
  ], # paths copied to $out/lib/<pname>
  postInstall ? null, # a file, read into the postInstall hook
  meta,
}:

stdenvNoCC.mkDerivation {
  inherit
    pname
    version
    entry
    binary
    ;

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    inherit hash;
  };

  nativeBuildInputs = [ makeWrapper ];

  bun = lib.getExe bun;
  copy = lib.concatStringsSep " " copy;

  dontBuild = true;

  installPhase = builtins.readFile ./bun-package/install.sh;

  postInstall = lib.optionalString (postInstall != null) (builtins.readFile postInstall);

  meta = {
    mainProgram = binary;
    platforms = lib.platforms.all;
  }
  // meta;
}
