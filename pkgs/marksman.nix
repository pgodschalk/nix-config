# nixpkgs' marksman, buildable inside the sandbox. It inherits a
# `__sandboxProfile` from dotnet, which a daemon with `sandbox = true`
# refuses outright, so without this it installs only when the binary
# cache happens to hold it. The build and its tests need nothing from
# that profile but the system ICU data, which the host's
# `allowed-impure-host-deps` has to keep listing.
#
# `overrideDerivation` rather than `overrideAttrs`, because stdenv
# computes the profile from the build inputs, so an `overrideAttrs`
# value is added to it rather than replacing it.
{
  lib,
  stdenv,
  marksman,
}:

if stdenv.hostPlatform.isDarwin then
  lib.overrideDerivation marksman (previous: {
    __sandboxProfile = "";
    __impureHostDeps = (previous.__impureHostDeps or [ ]) ++ [ "/usr/share/icu" ];
  })
else
  marksman
