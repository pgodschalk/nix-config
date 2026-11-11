{ lib, pkgs, ... }:
{
  home.packages = [
    (pkgs.callPackage ../../pkgs/djlsp.nix { })

    # No language server has diagnostics for a Django template --
    # neither djlsp nor djls -- so an unclosed `{% for %}` is caught by
    # this instead. It is a CLI, so it cannot reach either editor's
    # gutter and belongs in a pre-commit hook.
    pkgs.djlint

    # Off in both editors' global Python lists; a repository that lints
    # with pylint turns it on and points its pylint plugin at its own
    # venv, which is how ubiops-api gets CI's pylint in the editor.
    pkgs.python3Packages.python-lsp-server
  ]
  # A system with no wheel gets no server rather than a broken one.
  ++ lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) [
    (pkgs.callPackage ../../pkgs/pytest-language-server.nix { })
    (pkgs.callPackage ../../pkgs/django-language-server.nix { })
  ];
}
