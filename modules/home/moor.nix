{ pkgs, ... }:
let
  # moor reads one variable, MOOR, and the themed shell replaces it
  # whole at each Appearance switch, so each Variant's value repeats
  # these flags after its style.
  flags = "--no-linenumbers --quit-if-one-screen --statusbar=bold";
  withStyle = style: "--style=${style} ${flags}";
in
{
  # `moor`, not `moar`: upstream renamed both in 2.0, and the nixpkgs
  # alias warns on every evaluation.
  home.packages = [ pkgs.moor ];

  home.sessionVariables = {
    MOOR = flags;
    PAGER = "moor";
  };

  my.launchd.shellOnlyVariables = [
    "MOOR"
    "PAGER"
  ];

  # moor takes a Chroma style name from its built-in registry and no
  # palette file, so this is Chroma's plain dracula and, on the light
  # side, the nearest of its light styles.
  my.theme.variantVariables.MOOR = {
    pro = withStyle "dracula";
    alucard = withStyle "tango";
  };

  # moor supports neither LESS_TERMCAP_* nor LESSOPEN, so the `less`
  # theme reaches only a directly invoked less, and a LESSOPEN filter
  # such as batpipe would be inert.
}
