{ lib, pkgs, ... }:
let
  mkWheelLsp = pkgs.callPackage ../../pkgs/python-lsp-wheel.nix { };

  # Keyed by `hostPlatform.system`, and a system with no entry silently
  # gets no server rather than a broken one. x86_64-darwin is absent
  # because Rosetta is a dead end, and the musllinux wheels are ignored
  # in favour of manylinux since NixOS is glibc.
  #
  # PyPI puts each file under a content-addressed directory, so a
  # version bump means re-reading every URL from
  # https://pypi.org/pypi/<name>/json as well as the hash.
in
{
  home.packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) [
    (mkWheelLsp {
      pname = "pytest-language-server";
      # @VERSION https://pypi.org/project/pytest-language-server/#history
      version = "0.24.0";
      wheels = {
        aarch64-darwin = {
          url = "https://files.pythonhosted.org/packages/05/80/e69c517aaf02d688e68a42bfa4f1286e3f8c954f7eaba679063f9f389cc9/pytest_language_server-0.24.0-py3-none-macosx_11_0_arm64.whl";
          hash = "sha256-MAilLLhwPlZYW6tulUE0o3uW8zKZUeFLtpldnhkT6vc=";
        };
        aarch64-linux = {
          url = "https://files.pythonhosted.org/packages/ff/87/c4e576827bdefaeda6b22db677b80bcfa18eb0c3a40a201e28425e2f69a9/pytest_language_server-0.24.0-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
          hash = "sha256-pJdeDiAciT1ahHq6211qwt/AesHRXeWINRFZhL7Q+Ss=";
        };
        x86_64-linux = {
          url = "https://files.pythonhosted.org/packages/fe/67/c7555cee2d9e1d715b38d2b6bed8213b172419101509259ffb18094d7308/pytest_language_server-0.24.0-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-ixVXY+uPi+YBGJMFHgDSU5KisocvFSdnjDCRZhbh/u8=";
        };
      };
      description = "Language server for pytest";
      homepage = "https://github.com/bellini666/pytest-language-server";
      license = lib.licenses.mit;
    })

    (mkWheelLsp {
      pname = "django-language-server";
      # The binary is `djls`, not the package name: the wheel ships
      # `…data/scripts/djls` and the Zed extension looks for exactly
      # that, so any other name leaves this copy unused.
      binary = "djls";
      # @VERSION https://pypi.org/project/django-language-server/#history
      version = "6.1.1";
      wheels = {
        aarch64-darwin = {
          url = "https://files.pythonhosted.org/packages/e1/15/22473ba69ce8e30dc3debe2ad69ba7470b4df0d0de3008f3d77deb192630/django_language_server-6.1.1-py3-none-macosx_11_0_arm64.whl";
          hash = "sha256-zPEnKT+Z+5r024YbzASuDyrMcZr7pcWevXXW57ngQhI=";
        };
        aarch64-linux = {
          url = "https://files.pythonhosted.org/packages/2f/80/90853cfa2f2a63c19506afd3d673af420c9d718ef66b7332de779a383882/django_language_server-6.1.1-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
          hash = "sha256-buUHEYFJ1Jl7UIfUlLAeB1+LNNdYvAwgIVrbCiUbfQc=";
        };
        x86_64-linux = {
          url = "https://files.pythonhosted.org/packages/78/13/a48c84e7d71fe02641f85453b91686b0a11e65e15bdd3d3e0cac7324d982/django_language_server-6.1.1-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-D8MKnXTY3qsCIj75UkAFbCMZbPGVA0X+lHZkRU8QbEs=";
        };
      };
      description = "Language server for Django projects and templates";
      homepage = "https://github.com/joshuadavidthomas/django-language-server";
      license = lib.licenses.asl20;
    })
  ];
}
