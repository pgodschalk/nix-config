# `isDarwin` is a special argument from the host rather than
# `pkgs.stdenv.isDarwin`: a module argument taken from `pkgs` resolves
# through `config._module.args`, and `imports` is evaluated before
# `config` exists, so using `pkgs` here is an infinite recursion.
{ isDarwin, ... }:
{
  imports = [
    ./common.nix
  ]
  ++ (if isDarwin then [ ./darwin.nix ] else [ ./linux.nix ]);
}
