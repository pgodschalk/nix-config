# Asserts the archive kind release-binary.nix derives from each asset
# URL suffix, read through the `archive` attribute it exposes.
{
  lib,
  stdenvNoCC,
  callPackage,
  writeText,
}:
let
  cases = {
    ".tar.gz" = "tar";
    ".tar.xz" = "tar";
    ".tgz" = "tar";
    ".tar" = "tar";
    ".tbz" = "tar";
    ".zip" = "zip";
    ".gz" = "gzip";
    "-darwin-arm64" = "file";
  };

  kindOf =
    suffix:
    (callPackage ../release-binary.nix { } {
      pname = "probe";
      version = "0";
      assets.${stdenvNoCC.hostPlatform.system} = {
        url = "https://example.invalid/probe${suffix}";
        hash = lib.fakeHash;
      };
      meta = { };
    }).archive;

  wrong = lib.filterAttrs (suffix: kind: kindOf suffix != kind) cases;
  describe = suffix: kind: "${suffix} gave ${kindOf suffix}, expected ${kind}";
  report = lib.concatStringsSep "; " (lib.mapAttrsToList describe wrong);
in
assert lib.assertMsg (wrong == { }) "release-binary: ${report}";
writeText "release-binary-archive" (builtins.toJSON cases)
