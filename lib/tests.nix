{ lib }:
let
  inherit (import ./. lib) substituteValue;

  # tryEval stops at weak head normal form, so the value is forced
  # whole first, or an assertion deeper down would go unseen.
  fails = value: !(builtins.tryEval (builtins.deepSeq value value)).success;
in
{
  testSubstitutesStringsAndNames = {
    expr =
      substituteValue
        {
          "@kind@".expr = "@options@";
          list = [
            "x"
            1
            true
            null
          ];
        }
        {
          kind = "nix-darwin";
          options = "(f).options";
        };
    expected = {
      nix-darwin.expr = "(f).options";
      list = [
        "x"
        1
        true
        null
      ];
    };
  };

  testSubstitutesInsideList = {
    expr = substituteValue [ "@a@" "x" ] { a = "1"; };
    expected = [
      "1"
      "x"
    ];
  };

  testNullKeepsPlaceholder = {
    expr = substituteValue { a = "@x@ @y@"; } {
      x = "1";
      y = null;
    };
    expected.a = "1 @y@";
  };

  testKeepsContext = {
    expr =
      let
        probe = builtins.toFile "probe" "";
      in
      builtins.hasContext (substituteValue { a = "@p@/bin"; } { p = probe; }).a;
    expected = true;
  };

  testUnusedReplacementFails = {
    expr = fails (
      substituteValue { a = "@x@"; } {
        x = "1";
        y = "2";
      }
    );
    expected = true;
  };

  testUnfilledPlaceholderInNameFails = {
    expr = fails (substituteValue { "@z@" = 1; } { });
    expected = true;
  };
}
