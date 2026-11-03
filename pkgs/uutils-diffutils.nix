# nixpkgs' uutils-diffutils with the GNU patch its macOS tests look for.
# On macOS they run `gpatch` rather than `patch`, the Homebrew name,
# which GNU patch in nixpkgs does not provide, so without this link the
# check phase fails.
{
  lib,
  stdenv,
  gnupatch,
  linkFarm,
  uutils-diffutils,
}:

if stdenv.hostPlatform.isDarwin then
  uutils-diffutils.overrideAttrs (previous: {
    nativeCheckInputs = (previous.nativeCheckInputs or [ ]) ++ [
      (linkFarm "gpatch" [
        {
          name = "bin/gpatch";
          path = lib.getExe gnupatch;
        }
      ])
    ];
  })
else
  uutils-diffutils
