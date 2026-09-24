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
      # @VERSION
      # https://pypi.org/project/pytest-language-server/#history
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
        version = "0.1.8";
        url = "https://files.pythonhosted.org/packages/73/91/6523d890040486b4e70f1ae148447652c213e6ed44876ac7d26afa6ce9f8/fastapi_lsp-0.1.8-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-zxea7SIDDCXJDZB4agreE3QamWGivJjjUoebAneqR7E=";
        description = "Language server for FastAPI routes and dependencies";
        homepage = "https://github.com/alex-oleshkevich/fastapi-lsp";
      };
      aarch64-linux = {
        version = "0.1.8";
        url = "https://files.pythonhosted.org/packages/31/68/8c8032a315f526752b3c369fb856f718090b04a5a9504c9d871a4ee3f59f/fastapi_lsp-0.1.8-py3-none-manylinux_2_28_aarch64.whl";
        hash = "sha256-HzS/wxInJ2PfVFKU+84WO6fjZuBdXI/q9NFYqGGM2gA=";
        description = "Language server for FastAPI routes and dependencies";
        homepage = "https://github.com/alex-oleshkevich/fastapi-lsp";
      };
      x86_64-linux = {
        version = "0.1.8";
        url = "https://files.pythonhosted.org/packages/66/f4/05dd00a0ecd62a140205c43826869616b017696b5c764a7fb30eb7ad6e47/fastapi_lsp-0.1.8-py3-none-manylinux_2_28_x86_64.whl";
        hash = "sha256-VEq2RAJoRIlsMs2vcgOtytU6qZyqymPMeIsG8lds+Q0=";
        description = "Language server for FastAPI routes and dependencies";
        homepage = "https://github.com/alex-oleshkevich/fastapi-lsp";
      };
    }

    ++ wheelFor "sqlalchemy-lsp" lib.licenses.mit {
      # @VERSION https://pypi.org/project/sqlalchemy-lsp/#history
      aarch64-darwin = {
        version = "0.2.1";
        url = "https://files.pythonhosted.org/packages/7f/d0/290dd31b991b0de10b76c66233163bab23505d80fb451acce35ed55563c8/sqlalchemy_lsp-0.2.1-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-PVKik2el+Qs+fGQYVmxaknY1rV5eO5VkjHnfDCUjfok=";
        description = "Language server for SQLAlchemy models and queries";
        homepage = "https://github.com/alex-oleshkevich/sqlalchemy-lsp";
      };
      aarch64-linux = {
        version = "0.2.1";
        url = "https://files.pythonhosted.org/packages/4a/59/74d3bfd7650cfb306ca18b69c09dcce6d12bea1db3d615f04a5bc8d26c8c/sqlalchemy_lsp-0.2.1-py3-none-manylinux_2_28_aarch64.whl";
        hash = "sha256-MjOfkkSb2j5+nBxbotj9Ibqnb7vy0+dWyxASsGqPmg8=";
        description = "Language server for SQLAlchemy models and queries";
        homepage = "https://github.com/alex-oleshkevich/sqlalchemy-lsp";
      };
      x86_64-linux = {
        version = "0.2.1";
        url = "https://files.pythonhosted.org/packages/35/ad/9dc12882b0582b828e732fe7684a3a6f656cb9d1dd063f9cc2e662386c18/sqlalchemy_lsp-0.2.1-py3-none-manylinux_2_28_x86_64.whl";
        hash = "sha256-+l5ClePt/ezrBjZlvKz37Q0unEFdIOIcOpBRDS26pF4=";
        description = "Language server for SQLAlchemy models and queries";
        homepage = "https://github.com/alex-oleshkevich/sqlalchemy-lsp";
      };
    }

    # The binary is `djls`, not the package name: the wheel ships
    # `…data/scripts/djls` and the Zed extension looks for exactly that,
    # so any other name leaves this copy unused.
    ++ wheelFor "django-language-server" lib.licenses.asl20 {
      # @VERSION
      # https://pypi.org/project/django-language-server/#history
      aarch64-darwin = {
        version = "6.1.0";
        binary = "djls";
        url = "https://files.pythonhosted.org/packages/6f/dd/e3363242a99f1ac92272c874c75644c2b0dadbf3bc39ccf599b1190d134d/django_language_server-6.1.0-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-v6OsMbGL00mKLT6R+fO6uevfeVakC77T9chcLGWB3Eg=";
        description = "Language server for Django projects and templates";
        homepage = "https://github.com/joshuadavidthomas/django-language-server";
      };
      aarch64-linux = {
        version = "6.1.0";
        binary = "djls";
        url = "https://files.pythonhosted.org/packages/41/b6/dc055f92528c3e1c0cb1d0f63c65257cc01efe6e6df155e065603d31d3e8/django_language_server-6.1.0-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
        hash = "sha256-L3mdz3A6nKmgpAQ9hg8ub3FcnY6QoXk90NQgMGdzWk0=";
        description = "Language server for Django projects and templates";
        homepage = "https://github.com/joshuadavidthomas/django-language-server";
      };
      x86_64-linux = {
        version = "6.1.0";
        binary = "djls";
        url = "https://files.pythonhosted.org/packages/f7/28/08d3e50125ae59b5520220657a3b3d2028bf06e64a743f55669a906a49af/django_language_server-6.1.0-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
        hash = "sha256-VsvZ8c2/v0o9n1kixHl/G6QQsdTKXuCFYnqkRlTBCBk=";
        description = "Language server for Django projects and templates";
        homepage = "https://github.com/joshuadavidthomas/django-language-server";
      };
    };
}
