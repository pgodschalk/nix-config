{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  helmfmt = pkgs.callPackage ../../pkgs/helmfmt.nix { };
  pgfmt = pkgs.callPackage ../../pkgs/pgfmt.nix { };

  # pgfmt emits two trailing newlines, jqfmt and dockerfmt none, and the
  # file then flickers between one and two blank lines against the
  # editors' "ensure final newline".
  oneNewline =
    name: cmd:
    pkgs.writeShellScriptBin name (substituteFile ./formatters/one-newline.sh { inherit cmd; });

  # helmfmt takes file paths, not stdin, while both editors hand a
  # formatter the buffer on stdin.
  helmfmtStdin = pkgs.writeShellScriptBin "helmfmt-stdin" (
    substituteFile ./formatters/helmfmt-stdin.sh {
      coreutils = "${pkgs.coreutils}";
      helmfmt = lib.getExe helmfmt;
    }
  );

  # One Prettier wrapper per language, five of them through a plugin.
  # See pkgs/prettier-with-plugins.nix: the parser names are not the
  # language names, and the plugins must live in a node_modules tree
  # beside prettier.
  prettierWithPlugins = pkgs.callPackage ../../pkgs/prettier-with-plugins.nix { };
in
{
  options.my.formatters = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    readOnly = true;
    default = {
      dockerfmt-1nl = oneNewline "dockerfmt-1nl" "${lib.getExe pkgs.dockerfmt}";
      helmfmt-stdin = helmfmtStdin;
      # The three flags are what make it a formatter: with none at
      # all it emits a single line. `-op` takes jqfmt's own operator
      # names rather than the symbols, which its error message lists.
      # It leaves a trailing space on every line it breaks, which
      # Zed's remove_trailing_whitespace_on_save takes off.
      jqfmt-1nl = oneNewline "jqfmt-1nl" "${lib.getExe pkgs.jqfmt} -ar -ob -op pipe";
      pgfmt-1nl = oneNewline "pgfmt-1nl" "${lib.getExe pgfmt}";
    }
    // lib.genAttrs [
      "prettier-astro"
      "prettier-awk"
      "prettier-gherkin"
      "prettier-ini"
      "prettier-jinja"
      "prettier-json5"
      "prettier-md"
    ] (_: prettierWithPlugins);
    description = "The Formatter wrappers the editors run, by binary name.";
  };

  # Formatters that are a plain CLI rather than a language server.
  config.home.packages = [
    # General YAML formatters destroy charts -- oxfmt and
    # yaml-language-server both rewrite `{{ x }}` into `{ { x } }` and
    # exit 0. helmfmt aligns Go-template control blocks and leaves raw
    # YAML structure alone.
    helmfmt

    pkgs.dockerfmt

    pgfmt

    # `xmllint --format`, which reads stdin when given `-`.
    pkgs.libxml2

    # jqfmt deletes every comment in a filter.
    pkgs.jqfmt

    # Kanban and treemap diagrams are missing from the formatter's type
    # table and lose the indentation their structure depends on.
    (pkgs.callPackage ../../pkgs/mermaid-formatter.nix { })

    pkgs.nufmt
  ]
  ++ lib.unique (lib.attrValues config.my.formatters);
}
