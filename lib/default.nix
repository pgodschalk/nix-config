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
  # Both of `replaceVars`' safeguards hold: a replacement that matches
  # no placeholder fails, and so does a placeholder in the file that no
  # replacement names. A name given as null keeps its placeholder, for
  # a file filled in two passes.
  substituteFile =
    path: replacements:
    let
      file = builtins.readFile path;
      names = builtins.attrNames replacements;
      unused = builtins.filter (name: !lib.hasInfix "@${name}@" file) names;
      placeholders = lib.concatLists (
        builtins.filter builtins.isList (builtins.split "@([A-Za-z_][0-9A-Za-z_'-]*)@" file)
      );
      unfilled = lib.unique (builtins.filter (name: !(replacements ? ${name})) placeholders);
      filled = builtins.filter (name: replacements.${name} != null) names;
    in
    assert lib.assertMsg (unused == [ ]) (
      "substituteFile: ${toString path} has no placeholder for "
      + lib.concatMapStringsSep ", " (name: "@${name}@") unused
    );
    assert lib.assertMsg (unfilled == [ ]) (
      "substituteFile: ${toString path} leaves "
      + lib.concatMapStringsSep ", " (name: "@${name}@") unfilled
      + " unfilled; pass null to keep one"
    );
    builtins.replaceStrings (map (name: "@${name}@") filled) (map (
      name: replacements.${name}
    ) filled) file;
}
