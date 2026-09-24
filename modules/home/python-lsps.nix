{ pkgs, ... }:
{
  # The aarch64-darwin wheels are in
  # modules/home/darwin/python-lsps.nix.
  home.packages = [
    (pkgs.callPackage ../../pkgs/djlsp.nix { })

    # No language server has diagnostics for a Django template --
    # neither djlsp nor djls -- so an unclosed `{% for %}` is caught by
    # this instead. It is a CLI, so it cannot reach either editor's
    # gutter and belongs in a pre-commit hook.
    pkgs.djlint
  ];
}
