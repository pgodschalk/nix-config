# A formatter built for Helm templates, not in nixpkgs. It exists
# because the general YAML formatters destroy charts: oxfmt and
# yaml-language-server both rewrite `{{ x }}` into `{ { x } }` and exit
# 0. helmfmt aligns Go-template control blocks and leaves raw YAML
# structure alone.
#
# Its default of leaving `tpl`, `template`, `include` and `toYaml`
# unindented is kept, because moving those can break YAML indentation.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "helmfmt";
  # @VERSION https://github.com/digitalstudium/helmfmt/releases
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "digitalstudium";
    repo = "helmfmt";
    rev = "v${finalAttrs.version}";
    hash = "sha256-DABL+Kygs9cF124QK76YfsBlNyLEk6nYfOjyWpP8NT0=";
  };
  vendorHash = "sha256-r/dmfRzZpEdOEObhkMzA2SFlmDD89h6ZBmFoMdMOwSg=";

  # A real `vendorHash` rather than `null`, because upstream's committed
  # `vendor/modules.txt` is out of sync with go.mod and the vendored
  # build fails on it. `proxyVendor` so the module cache carries sprig,
  # which only the generator below imports and a `-mod=vendor` build
  # cannot see.
  proxyVendor = true;

  # Running the generator is part of building from source rather than a
  # patch.
  preBuild = builtins.readFile ./helmfmt/pre-build.sh;

  meta = {
    description = "Formatter for Helm chart templates that leaves YAML structure alone";
    homepage = "https://github.com/digitalstudium/helmfmt";
    license = lib.licenses.gpl3Only;
    mainProgram = "helmfmt";
    platforms = lib.platforms.all;
  };
})
