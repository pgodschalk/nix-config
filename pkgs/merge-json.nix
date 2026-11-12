# Merges a declared JSON file into one an app rewrites itself, for
# my.mergedSettings.
{
  lib,
  coreutils,
  jq,
  runCommand,
  writeShellApplication,
  writeText,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:
let
  mergeJson = writeShellApplication {
    name = "merge-json";
    runtimeInputs = [
      coreutils
      jq
    ];
    text = substituteFile ./merge-json/merge-json.sh {
      filter = "${./merge-json/merge.jq}";
      empty = "${writeText "empty.json" "{}"}";
    };
    passthru.tests.fixtures = runCommand "merge-json-tests" { nativeBuildInputs = [ jq ]; } (
      substituteFile ./merge-json/check.sh {
        test = "${./merge-json/test.sh}";
        mergeJson = lib.getExe mergeJson;
        cases = "${./merge-json/tests}";
      }
    );
  };
in
mergeJson
