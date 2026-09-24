# Prettier plus the community plugins this configuration needs. None are
# in nixpkgs, and each is a plain npm tarball, so they are fetched
# individually and dropped beside a prettier wrapper.
#
# The parser name is not the language name, which is the trap here:
# `--parser=awk` fails with "Couldn't resolve parser" where the plugin
# registers `awk-parse`. Each comes from the plugin's own `parsers`
# export.
#
#   prettier-plugin-awk             parser `awk-parse`
#   prettier-plugin-ini             parser `ini`
#   prettier-plugin-jinja-template  parser `jinja-template`
#   prettier-plugin-gherkin         parser `gherkin`
#   prettier-plugin-astro           parser `astro`
#
# One wrapper per language, each reading stdin and writing stdout, which
# is the contract both editors' external formatters use.
{
  lib,
  stdenvNoCC,
  fetchurl,
  prettier,
  makeWrapper,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../lib lib).substituteFile,
}:

let
  plugins = {
    prettier-plugin-awk = fetchurl {
      # @VERSION https://www.npmjs.com/package/prettier-plugin-awk
      url = "https://registry.npmjs.org/prettier-plugin-awk/-/prettier-plugin-awk-0.4.0.tgz";
      hash = "sha256-UgWz8umekLMs01MTEWbbv0GehYnZWZWLixvczi9NiG4=";
    };
    prettier-plugin-ini = fetchurl {
      # @VERSION https://www.npmjs.com/package/prettier-plugin-ini
      url = "https://registry.npmjs.org/prettier-plugin-ini/-/prettier-plugin-ini-1.3.0.tgz";
      hash = "sha256-eASYmAJWxvFDh1qwD9qNXibBHBn7f5c0FUWBnVOPpVE=";
    };
    prettier-plugin-jinja-template = fetchurl {
      # @VERSION
      # https://www.npmjs.com/package/prettier-plugin-jinja-template
      url = "https://registry.npmjs.org/prettier-plugin-jinja-template/-/prettier-plugin-jinja-template-2.2.0.tgz";
      hash = "sha256-ZruB+YkX2Su3qVCObcM9n85cB837dMF4s8Ov1UzrZVI=";
    };
    # For Helix, which has no bundled Prettier while
    # astro-language-server advertises formatting and ships none. Only
    # the aarch64-darwin compiler binding is fetched below; a NixOS
    # host needs the matching
    # @astrojs/compiler-binding-linux-*-gnu.
    prettier-plugin-astro = fetchurl {
      # @VERSION https://www.npmjs.com/package/prettier-plugin-astro
      url = "https://registry.npmjs.org/prettier-plugin-astro/-/prettier-plugin-astro-1.0.1.tgz";
      hash = "sha256-V0bLhIhknRZOk6YNsa6aeWVyNGE9QhssIIPygZ1B8V4=";
    };
    "@astrojs/compiler-rs" = fetchurl {
      # @VERSION https://www.npmjs.com/package/@astrojs/compiler-rs
      url = "https://registry.npmjs.org/@astrojs/compiler-rs/-/compiler-rs-0.5.0.tgz";
      hash = "sha256-+Zzc+dx/dIKZb6dqh5yo9zhe8kcCsAUzPfw78+qYvUE=";
    };
    "@astrojs/compiler-binding" = fetchurl {
      # @VERSION https://www.npmjs.com/package/@astrojs/compiler-binding
      url = "https://registry.npmjs.org/@astrojs/compiler-binding/-/compiler-binding-0.5.0.tgz";
      hash = "sha256-2OcjjlS/53fXZi57Yyxz7GU5ZlFfui7szM5Hq5opAbc=";
    };

    "@astrojs/compiler-binding-darwin-arm64" = fetchurl {
      # @VERSION
      # https://www.npmjs.com/package/@astrojs/compiler-binding-darwin-arm64
      url = "https://registry.npmjs.org/@astrojs/compiler-binding-darwin-arm64/-/compiler-binding-darwin-arm64-0.5.0.tgz";
      hash = "sha256-QyhN0B3X2ilwnIM+F4MARYulzF46CB+6DtknsPAP65o=";
    };
    "@prettier/parse-srcset" = fetchurl {
      # @VERSION https://www.npmjs.com/package/@prettier/parse-srcset
      url = "https://registry.npmjs.org/@prettier/parse-srcset/-/parse-srcset-3.1.0.tgz";
      hash = "sha256-CAV+T5nwHYtJKhDC/zVyaDFA6l5umghtKGI19F60HtY=";
    };
    sass-formatter = fetchurl {
      # @VERSION https://www.npmjs.com/package/sass-formatter
      url = "https://registry.npmjs.org/sass-formatter/-/sass-formatter-0.8.0.tgz";
      hash = "sha256-EsO9QOjzzx3L4GipBoUlCdUCgG3PTKsNX6yzWW76Sp0=";
    };
    suf-log = fetchurl {
      # @VERSION https://www.npmjs.com/package/suf-log
      url = "https://registry.npmjs.org/suf-log/-/suf-log-2.5.3.tgz";
      hash = "sha256-wA1PA6lIDRhHdMMjiIXwv0oyXX3UmvfL17v+Y507bns=";
    };
    "s.color" = fetchurl {
      # @VERSION https://www.npmjs.com/package/s.color
      url = "https://registry.npmjs.org/s.color/-/s.color-0.0.15.tgz";
      hash = "sha256-+c7/TNb4nbk8pZt6ivn7ZbFMtwymhvGJjJh7nMWsNQU=";
    };

    prettier-plugin-gherkin = fetchurl {
      # @VERSION https://www.npmjs.com/package/prettier-plugin-gherkin
      url = "https://registry.npmjs.org/prettier-plugin-gherkin/-/prettier-plugin-gherkin-4.0.0.tgz";
      hash = "sha256-DYGJRlQ6rYoyr/HzF0THf46NgyTE2qVUE+t+6bI8CN8=";
    };

    # The AWK plugin parses with tree-sitter, so both of these are
    # needed; ini and jinja have no dependencies.
    web-tree-sitter = fetchurl {
      # @VERSION https://www.npmjs.com/package/web-tree-sitter
      url = "https://registry.npmjs.org/web-tree-sitter/-/web-tree-sitter-0.27.0.tgz";
      hash = "sha256-Jm6DnZ1/ichLps4In/3slZmwpmjAEDCPhXuq0FcKDVA=";
    };
    tree-sitter-awk = fetchurl {
      # @VERSION https://www.npmjs.com/package/tree-sitter-awk
      url = "https://registry.npmjs.org/tree-sitter-awk/-/tree-sitter-awk-0.7.2.tgz";
      hash = "sha256-2PO0/d1kVsx+5H0VOgX8O7YG9ac4Wvi4RBN8nJQRYEA=";
    };

    # Held back, and they cannot move until prettier-plugin-gherkin does
    # it depends on `@cucumber/gherkin ^39.1.0` and
    # `@cucumber/messages ^32.3.1`, and the registry's majors are
    # outside both ranges. A newer pair builds and then fails at run
    # time with "does not provide an export named 'Background'", so a
    # successful build does not settle a bump here.
    #
    # The two leaves below are messages' own dependencies, exact pins in
    # its package.json.
    "@cucumber/gherkin" = fetchurl {
      # @VERSION https://www.npmjs.com/package/@cucumber/gherkin
      url = "https://registry.npmjs.org/@cucumber/gherkin/-/gherkin-39.1.0.tgz";
      hash = "sha256-ok/ywzY7yWZkwXrBdL4tOsvbWpJbwt1nJnI5/Wxi8xk=";
    };
    "@cucumber/messages" = fetchurl {
      # @VERSION https://www.npmjs.com/package/@cucumber/messages
      url = "https://registry.npmjs.org/@cucumber/messages/-/messages-32.3.1.tgz";
      hash = "sha256-8r51hcVnlNKGodtv8fWJ4A3nWdu7hEItm6Lq/1Q0jD0=";
    };
    reflect-metadata = fetchurl {
      # @VERSION https://www.npmjs.com/package/reflect-metadata
      url = "https://registry.npmjs.org/reflect-metadata/-/reflect-metadata-0.2.2.tgz";
      hash = "sha256-ytUup3ABIjZIgpv6PE5nfTCTmSixLtNWYUi/K34d8Y8=";
    };
    class-transformer = fetchurl {
      # @VERSION https://www.npmjs.com/package/class-transformer
      url = "https://registry.npmjs.org/class-transformer/-/class-transformer-0.5.1.tgz";
      hash = "sha256-Se+th508yBGkbmuvcrBFSk8nHA2mt4mdAkvfz5SWH34=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "prettier-with-plugins";
  version = prettier.version;

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  # The plugin unpacking is substituted in as one generated block rather
  # than branch by branch, so the rest of the script stays parseable
  # shell and the checker can read it.
  installPhase = substituteFile ./prettier-with-plugins/install.sh {
    prettier = lib.getExe prettier;
    prettierModule = "${prettier}/lib/node_modules/prettier";
    shell = stdenvNoCC.shell;
    unpackPlugins = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: src: ''
        mkdir -p "$out/lib/node_modules/${name}"
        tar xzf ${src} -C "$out/lib/node_modules/${name}" --strip-components=1
      '') plugins
    );
  };

  meta = {
    description = "Prettier with the AWK, INI, Jinja, Gherkin and Astro plugins, plus Markdown and JSON5 wrappers";
    homepage = "https://prettier.io";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
