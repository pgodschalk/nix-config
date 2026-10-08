{ lib, pkgs, ... }:
let
  mkWheelLsp = pkgs.callPackage ../../pkgs/python-lsp-wheel.nix { };

  # Keyed by `hostPlatform.system`, and a system with no entry silently
  # gets no server rather than a broken one. x86_64-darwin is absent because Rosetta is
  # a dead end, and the musllinux wheels are ignored in favour of
  # manylinux since NixOS is glibc.
  #
  # PyPI puts each file under a content-addressed directory, so a
  # version bump means re-reading every URL from
  # https://pypi.org/pypi/<name>/json as well as the hash.
  wheelFor =
    name: license: wheels:
    lib.optional (wheels ? ${pkgs.stdenv.hostPlatform.system}) (
      mkWheelLsp (
        wheels.${pkgs.stdenv.hostPlatform.system}
        // {
          pname = name;
          inherit license;
        }
      )
    );
in
{
  home.packages =
    wheelFor "pytest-language-server" lib.licenses.mit {
      # @VERSION https://pypi.org/project/pytest-language-server/#history
      aarch64-darwin = {
        version = "0.24.0";
        binary = "pytest-language-server";
        url = "https://files.pythonhosted.org/packages/05/80/e69c517aaf02d688e68a42bfa4f1286e3f8c954f7eaba679063f9f389cc9/pytest_language_server-0.24.0-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-MAilLLhwPlZYW6tulUE0o3uW8zKZUeFLtpldnhkT6vc=";
        description = "Language server for pytest";
        homepage = "https://github.com/bellini666/pytest-language-server";
      };
      aarch64-linux = {
        version = "0.24.0";
        binary = "pytest-language-server";
        url = "https://files.pythonhosted.org/packages/ff/87/c4e576827bdefaeda6b22db677b80bcfa18eb0c3a40a201e28425e2f69a9/pytest_language_server-0.24.0-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
        hash = "sha256-pJdeDiAciT1ahHq6211qwt/AesHRXeWINRFZhL7Q+Ss=";
        description = "Language server for pytest";
        homepage = "https://github.com/bellini666/pytest-language-server";
      };
      x86_64-linux = {
        version = "0.24.0";
        binary = "pytest-language-server";
        url = "https://files.pythonhosted.org/packages/fe/67/c7555cee2d9e1d715b38d2b6bed8213b172419101509259ffb18094d7308/pytest_language_server-0.24.0-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
        hash = "sha256-ixVXY+uPi+YBGJMFHgDSU5KisocvFSdnjDCRZhbh/u8=";
        description = "Language server for pytest";
        homepage = "https://github.com/bellini666/pytest-language-server";
      };
    }

    # Installed globally, which is the honest shape: each is one binary
    # inspecting Python from the outside, so there is nothing a project
    # could declare, and in a project using neither framework the server
    # finds nothing to say.
    ++ wheelFor "fastapi-lsp" lib.licenses.mit {
      # @VERSION https://pypi.org/project/fastapi-lsp/#history
      aarch64-darwin = {
        version = "0.1.9";
        url = "https://files.pythonhosted.org/packages/44/7d/2d27e451cf5d62f64c8545db710920bd71b4e7f3d81218400d9c9b71dd48/fastapi_lsp-0.1.9-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-r1kUWTSaAtlwF8aA0Euc8/LGjzK2Bp0WLQdi85MeOHI=";
        description = "Language server for FastAPI routes and dependencies";
        homepage = "https://github.com/alex-oleshkevich/fastapi-lsp";
      };
      aarch64-linux = {
        version = "0.1.9";
        url = "https://files.pythonhosted.org/packages/53/f4/fdd11a2840ca91bd5bd78fe8872b7b918e9773582f4304b590f61b046275/fastapi_lsp-0.1.9-py3-none-manylinux_2_28_aarch64.whl";
        hash = "sha256-M8PTE4Lh0P+F1CrIeciYH5630agutPMaMuyzjMg5Gfc=";
        description = "Language server for FastAPI routes and dependencies";
        homepage = "https://github.com/alex-oleshkevich/fastapi-lsp";
      };
      x86_64-linux = {
        version = "0.1.9";
        url = "https://files.pythonhosted.org/packages/60/c8/71ec50428bc7c98d97a7dd589d1ff6c4a071622d99e33c37b3d09fb59e86/fastapi_lsp-0.1.9-py3-none-manylinux_2_28_x86_64.whl";
        hash = "sha256-4tnn/02ss0+T10AplNDi5Sy8QAFVe6G6AFl8a6/5GsM=";
        description = "Language server for FastAPI routes and dependencies";
        homepage = "https://github.com/alex-oleshkevich/fastapi-lsp";
      };
    }

    ++ wheelFor "sqlalchemy-lsp" lib.licenses.mit {
      # @VERSION https://pypi.org/project/sqlalchemy-lsp/#history
      aarch64-darwin = {
        version = "0.2.4";
        url = "https://files.pythonhosted.org/packages/2b/73/51acf96b31e50664360ec87a08f7801a5005582e336ed958443a7c04d0e5/sqlalchemy_lsp-0.2.4-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-H2jB8DfwYN1fsT/yLpm9Ab4PZvdiLPnj+VsTCC49IjM=";
        description = "Language server for SQLAlchemy models and queries";
        homepage = "https://github.com/alex-oleshkevich/sqlalchemy-lsp";
      };
      aarch64-linux = {
        version = "0.2.4";
        url = "https://files.pythonhosted.org/packages/57/fd/7e62d21adbf84f4c317d9d37fec38359458f1871eaa2ef439386da0efe36/sqlalchemy_lsp-0.2.4-py3-none-manylinux_2_28_aarch64.whl";
        hash = "sha256-JqsHHDuTpBK+ytO8hXGetibG+kYSnpjAFfEoBfv44P8=";
        description = "Language server for SQLAlchemy models and queries";
        homepage = "https://github.com/alex-oleshkevich/sqlalchemy-lsp";
      };
      x86_64-linux = {
        version = "0.2.4";
        url = "https://files.pythonhosted.org/packages/88/7d/5e825c4d7666f6984155772f0a73ce87e2ffcd8e6372d34a2e777c4e12f7/sqlalchemy_lsp-0.2.4-py3-none-manylinux_2_28_x86_64.whl";
        hash = "sha256-l0mrf5XWl+RwCNZKfcLNwTycK+38/EIoKHxgmMdeXxc=";
        description = "Language server for SQLAlchemy models and queries";
        homepage = "https://github.com/alex-oleshkevich/sqlalchemy-lsp";
      };
    }

    # The binary is `djls`, not the package name: the wheel ships
    # `…data/scripts/djls` and the Zed extension looks for exactly that,
    # so any other name leaves this copy unused.
    ++ wheelFor "django-language-server" lib.licenses.asl20 {
      # @VERSION https://pypi.org/project/django-language-server/#history
      aarch64-darwin = {
        version = "6.1.1";
        binary = "djls";
        url = "https://files.pythonhosted.org/packages/e1/15/22473ba69ce8e30dc3debe2ad69ba7470b4df0d0de3008f3d77deb192630/django_language_server-6.1.1-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-zPEnKT+Z+5r024YbzASuDyrMcZr7pcWevXXW57ngQhI=";
        description = "Language server for Django projects and templates";
        homepage = "https://github.com/joshuadavidthomas/django-language-server";
      };
      aarch64-linux = {
        version = "6.1.1";
        binary = "djls";
        url = "https://files.pythonhosted.org/packages/2f/80/90853cfa2f2a63c19506afd3d673af420c9d718ef66b7332de779a383882/django_language_server-6.1.1-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
        hash = "sha256-buUHEYFJ1Jl7UIfUlLAeB1+LNNdYvAwgIVrbCiUbfQc=";
        description = "Language server for Django projects and templates";
        homepage = "https://github.com/joshuadavidthomas/django-language-server";
      };
      x86_64-linux = {
        version = "6.1.1";
        binary = "djls";
        url = "https://files.pythonhosted.org/packages/78/13/a48c84e7d71fe02641f85453b91686b0a11e65e15bdd3d3e0cac7324d982/django_language_server-6.1.1-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
        hash = "sha256-D8MKnXTY3qsCIj75UkAFbCMZbPGVA0X+lHZkRU8QbEs=";
        description = "Language server for Django projects and templates";
        homepage = "https://github.com/joshuadavidthomas/django-language-server";
      };
    };
}
