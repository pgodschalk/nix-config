# The pytest language server. Not in nixpkgs, and PyPI ships it as a
# Rust binary inside a wheel with no Python in it, so the wheel is
# unpacked as a release binary rather than installed as a package.
{ lib, callPackage }:

let
  # @VERSION https://pypi.org/project/pytest-language-server/#history
  version = "0.26.0";
in
callPackage ./lib/release-binary.nix { } {
  pname = "pytest-language-server";
  inherit version;

  # PyPI's name-based path, which redirects to the file itself, so a
  # bump changes only `version` and the hashes. x86_64-darwin is left
  # out because nixpkgs does not support it, and the musl wheels
  # because NixOS is glibc.
  assets = {
    aarch64-darwin = {
      url = "https://files.pythonhosted.org/packages/py3/p/pytest-language-server/pytest_language_server-${version}-py3-none-macosx_11_0_arm64.whl";
      hash = "sha256-4HSmD3NjR55aAiMle1F4Oe08jzv4+j+PTrZCekYq6fY=";
    };
    aarch64-linux = {
      url = "https://files.pythonhosted.org/packages/py3/p/pytest-language-server/pytest_language_server-${version}-py3-none-manylinux2014_aarch64.manylinux_2_17_aarch64.whl";
      hash = "sha256-Poni5HFnZsR4eAGnlEFHr55NGoRnm9DZg0BnXSitiF8=";
    };
    x86_64-linux = {
      url = "https://files.pythonhosted.org/packages/py3/p/pytest-language-server/pytest_language_server-${version}-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
      hash = "sha256-GgOOTdvaFeFApYm9/12UrZXbvkdBH6VB1h7KVy4e7a0=";
    };
  };

  meta = {
    description = "Language server for pytest";
    homepage = "https://github.com/bellini666/pytest-language-server";
    license = lib.licenses.mit;
  };
}
