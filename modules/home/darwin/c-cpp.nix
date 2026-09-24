{ pkgs, ... }:
let
  clangFormat = pkgs.writeShellScriptBin "clang-format-xcode" (
    builtins.readFile ./c-cpp/clang-format-xcode.sh
  );
in
{
  # clang-format from Xcode, so the formatter matches the compiler.
  home.packages = [ clangFormat ];
}
