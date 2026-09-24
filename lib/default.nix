# Helpers shared by this flake's modules, taking nixpkgs' `lib`.
lib: {
  # `pkgs.replaceVars` without the derivation: the same `@name@`
  # substitution, at evaluation time.
  #
  # `builtins.readFile (pkgs.replaceVars ./f { … })` is
  # import-from-derivation, so evaluating it builds something. That is
  # invisible on macOS, where the inputs are already in the store, and
  # takes out the `homeConfigurations."patrick@linux"` check entirely
  # -- with an error naming a package rather than IFD.
  #
  # The assertion keeps `replaceVars`' one real safeguard: a placeholder
  # that matches nothing fails loudly rather than leaving `@name@` in
  # the output.
  substituteFile =
    path: replacements:
    let
      file = builtins.readFile path;
      names = builtins.attrNames replacements;
      unused = builtins.filter (name: !lib.hasInfix "@${name}@" file) names;
    in
    assert lib.assertMsg (unused == [ ]) (
      "substituteFile: ${toString path} has no placeholder for "
      + lib.concatMapStringsSep ", " (name: "@${name}@") unused
    );
    builtins.replaceStrings (map (name: "@${name}@") names) (map (
      name: replacements.${name}
    ) names) file;
}
