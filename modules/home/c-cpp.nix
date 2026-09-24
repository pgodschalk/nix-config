{ lib, pkgs, ... }:
{
  home.packages =
    # clangd comes from Xcode on macOS: /usr/bin/clangd is the Command
    # Line Tools shim and is the same build as the /usr/bin/clang that
    # compiles here, where nixpkgs' clangd is upstream's and disagrees
    # about Apple SDK headers.
    #
    # lldb likewise: nixpkgs' has no Swift language plugin and would
    # shadow Xcode's /usr/bin/lldb, so modules/home/darwin/c-cpp.nix
    # supplies lldb-dap there instead.
    lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      pkgs.clang-tools
      pkgs.lldb
    ]
    ++ [
      # For Zed, whose extension offers only this server; Helix also
      # runs cmake-language-server, from modules/home/cmake.nix.
      pkgs.neocmakelsp
    ];
}
