{ lib, pkgs, ... }:
let
in
{
  # The extension resolves `lsp.metal-analyzer.binary.path`, then
  # `which("metal-analyzer")`, then a GitHub download, so installing it
  # here pins the version.
  home.packages = [
    (pkgs.callPackage ../../../pkgs/metal-analyzer.nix { })
  ];

  # Both editors format Metal with the `clang-format-xcode` wrapper C
  # and C++ use, rather than with metal-analyzer: the server resolves
  # style from a `metalfmt.toml` then a `.clang-format`, and with
  # neither leaves the file unchanged, so a Metal file in a project
  # without config would silently not be formatted.

  # Neither editor knows Metal on its own. Zed gets a language from its
  # extension; Helix is given one here, which costs almost nothing
  # because Metal is C++: `grammar = "cpp"` reuses the parser Helix
  # ships, and `; inherits cpp` is its documented query inheritance.
  xdg.configFile =
    lib.genAttrs
      (map (q: "helix/runtime/queries/metal/${q}.scm") [
        "highlights"
        "injections"
        "textobjects"
        "indents"
      ])
      (_: {
        text = "; inherits cpp\n";
      });
}
