{ pkgs, ... }:
{
  home.packages = [
    # Normalises the call itself, where neocmakelsp formats only
    # indentation.
    pkgs.gersemi

    pkgs.cmake-language-server

    # Load-bearing: cmake-language-server runs a configure step for its
    # diagnostics and reports none at all until cmake is on PATH.
    pkgs.cmake
  ];
}
