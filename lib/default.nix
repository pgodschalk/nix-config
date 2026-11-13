# Helpers shared by this flake's modules, taking nixpkgs' `lib`.
lib:
let
  # The two safeguards, over `text`, with `what` naming the source in
  # each message. Returns the names whose replacement is not null.
  checkPlaceholders =
    what: text: replacements:
    let
      names = builtins.attrNames replacements;
      unused = builtins.filter (name: !lib.hasInfix "@${name}@" text) names;
      placeholders = lib.concatLists (
        builtins.filter builtins.isList (builtins.split "@([A-Za-z_][0-9A-Za-z_'-]*)@" text)
      );
      unfilled = lib.unique (builtins.filter (name: !(replacements ? ${name})) placeholders);
      filled = builtins.filter (name: replacements.${name} != null) names;
    in
    assert lib.assertMsg (unused == [ ]) (
      "${what} has no placeholder for " + lib.concatMapStringsSep ", " (name: "@${name}@") unused
    );
    assert lib.assertMsg (unfilled == [ ]) (
      "${what} leaves "
      + lib.concatMapStringsSep ", " (name: "@${name}@") unfilled
      + " unfilled; pass null to keep one"
    );
    filled;
in
{
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
      filled = checkPlaceholders "substituteFile: ${toString path}" file replacements;
    in
    builtins.replaceStrings (map (name: "@${name}@") filled) (map (
      name: replacements.${name}
    ) filled) file;

  # substituteFile's `@name@` substitution into a parsed value, such as
  # `builtins.fromTOML` returns: every string and every attribute name,
  # with the same two safeguards. A store path keeps its string context,
  # so a file rendered from the result depends on it.
  substituteValue =
    value: replacements:
    let
      strings =
        v:
        if builtins.isAttrs v then
          lib.concatLists (lib.mapAttrsToList (name: inner: [ name ] ++ strings inner) v)
        else if builtins.isList v then
          lib.concatMap strings v
        else if builtins.isString v then
          [ v ]
        else
          [ ];
      filled = checkPlaceholders "substituteValue: the value" (lib.concatStringsSep "\n" (
        strings value
      )) replacements;
      replace = builtins.replaceStrings (map (name: "@${name}@") filled) (
        map (name: replacements.${name}) filled
      );
      substitute =
        v:
        if builtins.isAttrs v then
          lib.mapAttrs' (name: inner: lib.nameValuePair (replace name) (substitute inner)) v
        else if builtins.isList v then
          map substitute v
        else if builtins.isString v then
          replace v
        else
          v;
    in
    builtins.seq filled (substitute value);
}
