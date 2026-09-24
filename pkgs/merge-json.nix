# Merges a declared JSON file into one an app rewrites itself, for the
# activation entries of apps whose settings cannot be a link.
{
  lib,
  coreutils,
  jq,
  writeShellApplication,
  writeText,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:
writeShellApplication {
  name = "merge-json";
  runtimeInputs = [
    coreutils
    jq
  ];
  text = substituteFile ./merge-json/merge-json.sh {
    filter = "${./merge-json/merge.jq}";
    empty = "${writeText "empty.json" "{}"}";
  };
}
