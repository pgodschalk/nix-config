# The two Eclipse settings files jdtls reads, in the store rather than
# under the data directory because jdtls resolves them as URIs and this
# machine's XDG_DATA_HOME contains a space. A store path never does.
#
# One derivation rather than a copy in each editor module, so Zed and
# Helix cannot drift apart on Java formatting.
{
  lib,
  runCommand,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:
runCommand "jdtls-settings" { } (
  substituteFile ./jdtls-settings/install.sh {
    formatter = "${./jdtls-settings/formatter.xml}";
    prefs = "${./jdtls-settings/org.eclipse.jdt.core.prefs}";
  }
)
