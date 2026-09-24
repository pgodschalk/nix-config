{ pkgs, ... }:
let
  # The binary decides what to be from argv[0]: as `tsc` it is the
  # compiler and `--lsp --stdio` hangs, as `tsgo` it is the language
  # server. The pinned nixpkgs ships only the `tsc` name, and a wrapper
  # script would not do -- it would set argv[0] to itself.
  tsgo = pkgs.callPackage ../../pkgs/tsgo.nix { };
in
{
  home.packages = [
    # The attribute is `typescript`, not `typescript-go`, which nixpkgs
    # has renamed to throw on use. TypeScript 7 is the Go port.
    pkgs.typescript

    tsgo

    # What Zed uses for TypeScript, TSX and JavaScript.
    pkgs.vtsls
  ];
}
