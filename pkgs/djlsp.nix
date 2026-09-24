# django-template-lsp, the `djlsp` binary, and the only route to Django
# template diagnostics -- djls, the other Django server, has none.
#
# Packaged rather than left to Zed's extension, which fetches it with
# `uv` onto whatever Python uv picks: djlsp uses `str | None`
# annotations at import time, a syntax error before 3.10, so the server
# crashed on every start.
{
  lib,
  python3Packages,
  fetchPypi,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:
let
  # pygls must be 1.x: upstream pins `pygls<2.0.0`, and pygls 2 moved
  # `LanguageServer` out of `pygls.server`, so djlsp dies on import with
  # "cannot import name 'LanguageServer'". pygls 1.3.1 in turn pins
  # lsprotocol exactly, so the two move together.
  #
  # overrideScope rather than two independent overrides: nixpkgs' pygls
  # carries the new lsprotocol through `propagatedBuildInputs`, so
  # overriding its `dependencies` alone still fails the runtime-deps
  # check. Replacing the name inside the package set is what the pin
  # actually means.
  #
  # Both held-back packages are scoped to this application.
  pyPkgs = python3Packages.overrideScope (
    final: prev: {
      lsprotocol = prev.lsprotocol.overridePythonAttrs (old: rec {
        # @VERSION https://pypi.org/project/lsprotocol/#history
        #
        # Cannot move on its own: pygls 1.3.1 requires exactly this,
        # only pygls 2.x accepts a newer lsprotocol, and djlsp requires
        # `pygls<2.0.0`. All three move together, and the gate is djlsp
        # gaining pygls 2 support.
        version = "2023.0.1";
        src = fetchPypi {
          pname = "lsprotocol";
          inherit version;
          hash = "sha256-zFwVEw0kA8GLc0MEM55RJC0wGKBcT30PGYrW4M0hhh0=";
        };

        # nixpkgs' lsprotocol expects the current monorepo sdist, where
        # the Python package sits under `packages/python/`. This sdist
        # is flat, so the inherited sourceRoot points at a directory
        # that does not exist.
        sourceRoot = "lsprotocol-${version}";

        doCheck = false;
      });

      pygls = prev.pygls.overridePythonAttrs (old: rec {
        # @VERSION https://pypi.org/project/django-template-lsp/#history
        version = "1.3.1";
        src = fetchPypi {
          pname = "pygls";
          inherit version;
          hash = "sha256-FA7c7voNoOmzxTNUfIkqQqfS/ZIXroSMMwxT0malUBg=";
        };
        doCheck = false;
      });
    }
  );
in
pyPkgs.buildPythonApplication rec {
  pname = "django-template-lsp";
  # @VERSION https://pypi.org/project/django-template-lsp/#history
  version = "1.3.1";
  pyproject = true;

  src = fetchPypi {
    pname = "django_template_lsp";
    inherit version;
    hash = "sha256-AmHt6XSIAe2qaG5QhVBsACPzWIBqynnIKL385iHHmRQ=";
  };

  build-system = [ pyPkgs.setuptools ];

  dependencies = [
    pyPkgs.pygls
    pyPkgs.jedi
  ];

  # Starts the real binary and requires an LSP `initialize` reply with a
  # non-empty capability set, which exercises the import graph pygls 2
  # breaks.
  #
  # `doCheck` is deliberately left alone: buildPythonPackage drops a
  # `doInstallCheck` attribute and derives it as `attrs.doCheck or
  # true`, so `doCheck = false` for the absent sdist tests would turn
  # this check off as well, silently. Nothing runs pytest either way,
  # because installCheckPhase is replaced here.
  installCheckPhase = substituteFile ./djlsp/install-check.sh {
    python = pyPkgs.python.interpreter;
    script = "${./djlsp/initialize-check.py}";
  };

  meta = {
    description = "Language server for Django templates";
    homepage = "https://github.com/fourdigits/django-template-lsp";
    license = lib.licenses.mit;
    mainProgram = "djlsp";
    platforms = lib.platforms.all;
  };
}
