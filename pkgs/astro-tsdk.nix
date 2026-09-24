# astro-language-server refuses to start without a TypeScript SDK: an
# initialize with no initializationOptions comes back `-32603: The
# `typescript.tsdk` init option is required`. Zed's Astro extension
# locates one itself; Helix and Claude Code are given this one.
#
# Resolved at build time because the only real location is under
# pnpm's content-addressed layout and would rot on the next bump, back
# to the same silent -32603. The bundled copy rather than
# pkgs.typescript, which is a major version ahead of it.
{
  lib,
  astro-language-server,
  runCommand,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:
runCommand "astro-tsdk" { } (
  substituteFile ./astro-tsdk/install.sh {
    astroLanguageServer = "${astro-language-server}";
  }
)
