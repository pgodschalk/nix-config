# TypeScript v7's native language server, as a package rather than a
# `let` binding because modules/home/typescript.nix installs it and
# modules/home/darwin/zed.nix pins it as Zed's `typescript-ls` binary.
{
  lib,
  runCommand,
  typescript,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:
runCommand "tsgo" { } (substituteFile ./tsgo/link.sh { tsc = "${typescript}/bin/tsc"; })
