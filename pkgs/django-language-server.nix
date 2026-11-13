# djls, the Django language server. Not in nixpkgs, and PyPI ships it
# as a Rust binary inside a wheel with no Python in it, so the wheel
# is unpacked as a release binary rather than installed as a package.
{ lib, callPackage }:

let
  # @VERSION https://pypi.org/project/django-language-server/#history
  version = "6.1.1";
in
callPackage ./lib/release-binary.nix { } {
  pname = "django-language-server";
  inherit version;

  # The binary is `djls`, not the package name: the wheel ships
  # `…data/scripts/djls` and the Zed extension looks for exactly
  # that, so any other name leaves this copy unused.
  binaries = [ "djls" ];

  # PyPI's name-based path, which redirects to the file itself, so a
  # bump changes only `version` and the hashes. x86_64-darwin is left
  # out because nixpkgs does not support it, and the musl wheels
  # because NixOS is glibc.
  assets = {
    aarch64-darwin = {
      url = "https://files.pythonhosted.org/packages/py3/d/django-language-server/django_language_server-${version}-py3-none-macosx_11_0_arm64.whl";
      hash = "sha256-zPEnKT+Z+5r024YbzASuDyrMcZr7pcWevXXW57ngQhI=";
    };
    aarch64-linux = {
      url = "https://files.pythonhosted.org/packages/py3/d/django-language-server/django_language_server-${version}-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
      hash = "sha256-buUHEYFJ1Jl7UIfUlLAeB1+LNNdYvAwgIVrbCiUbfQc=";
    };
    x86_64-linux = {
      url = "https://files.pythonhosted.org/packages/py3/d/django-language-server/django_language_server-${version}-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-D8MKnXTY3qsCIj75UkAFbCMZbPGVA0X+lHZkRU8QbEs=";
    };
  };

  meta = {
    description = "Language server for Django projects and templates";
    homepage = "https://github.com/joshuadavidthomas/django-language-server";
    license = lib.licenses.asl20;
  };
}
