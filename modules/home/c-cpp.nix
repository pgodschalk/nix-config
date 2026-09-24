{ lib, pkgs, ... }:
{
  home.packages =
    # clangd comes from Xcode on macOS: /usr/bin/clangd is the Command
    # Line Tools shim and is the same build as the /usr/bin/clang that
    # compiles here, where nixpkgs' clangd is upstream's and disagrees
    # about Apple SDK headers.
    lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      pkgs.clang-tools
    ]
    ++ [
      # lldb-dap, which Helix's C and C++ entries name. Xcode's copy
      # lives under `xcrun` only, so it is not on PATH.
      pkgs.lldb

      # neocmakelsp rather than cmake-language-server, the other server
      # Helix names: Zed's extension offers only this one.
      pkgs.neocmakelsp
    ];
}
