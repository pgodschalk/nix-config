{ pkgs, ... }:
let
  clangFormat = pkgs.writeShellScriptBin "clang-format-xcode" (
    builtins.readFile ./c-cpp/clang-format-xcode.sh
  );
  lldbDap = pkgs.writeShellScriptBin "lldb-dap" (builtins.readFile ./c-cpp/lldb-dap-xcode.sh);
in
{
  # clang-format from Xcode, so the formatter matches the compiler, and
  # the lldb-dap Helix's C, C++ and Swift entries name.
  home.packages = [
    clangFormat
    lldbDap
  ];
}
