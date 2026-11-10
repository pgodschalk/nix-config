# nixpkgs' marksman, buildable inside the sandbox. It inherits a
# `__sandboxProfile` from dotnet, which a daemon with `sandbox = true`
# refuses outright, so without this it installs only when the binary
# cache happens to hold it. The build and its tests need nothing from
# that profile but the system ICU data, which the host's
# `allowed-impure-host-deps` has to keep listing.
#
# The runtime is the prebuilt one: the source-built `runtime_9_0`
# carries the same profile through its whole VMR bootstrap, and the
# cache does not reliably hold it for aarch64-darwin.
#
# `overrideDerivation` rather than `overrideAttrs`, because stdenv
# computes the profile from the build inputs, so an `overrideAttrs`
# value is added to it rather than replacing it.
{
  lib,
  stdenv,
  dotnetCorePackages,
  marksman,
}:

if stdenv.hostPlatform.isDarwin then
  lib.overrideDerivation
    (marksman.override {
      dotnetCorePackages = dotnetCorePackages // {
        runtime_9_0 = dotnetCorePackages.runtime_9_0-bin;
      };
    })
    (previous: {
      __sandboxProfile = "";
      __impureHostDeps = (previous.__impureHostDeps or [ ]) ++ [ "/usr/share/icu" ];
    })
else
  marksman
