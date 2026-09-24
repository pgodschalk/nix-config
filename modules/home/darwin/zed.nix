{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  draculaProZed = "${config.home.homeDirectory}/Developer/github.com/dracula-pro/dracula-pro/themes/zed";

  # Referenced by store path, unlike every language server here: a debug
  # adapter has no per-repository version to defer to. Left unset, Zed
  # downloads its own copy.
  codelldb = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";

  # oxfmt has no user-level config -- only `.oxfmtrc.json` discovered by
  # walking up from the file -- so without this every repository would
  # need its own copy. `fmt.configPath` is the one lever that reaches it
  # from outside a checkout.
  #
  # Scoped to `*.jsonc` because the default is right for JS and TS,
  # where a trailing comma keeps a diff to one line. The glob matches
  # dotfiles too.
  # A checked-in file rather than a generated one, so this repository's
  # CI can format-check with the same configuration by pointing
  # `oxfmt -c` at it. Helix reads it too.
  oxfmtConfig = ../oxc/oxfmtrc.json;

  githubMcpServer = pkgs.callPackage ../../../pkgs/github-mcp-server-keychain.nix {
    inherit substituteFile;
  };
  dockerhubMcpServer = pkgs.callPackage ../../../pkgs/dockerhub-mcp-server.nix {
    inherit substituteFile;
  };

  # Empty, so no keymap.json is written at all.
  keymap = [ ];

  # Keys follow the order of Zed's own default settings. Within
  # `languages`, `lsp` and `file_types` they are alphabetical, because
  # Zed publishes no order for them -- its `lsp` default is empty and
  # its `file_types` has three entries.
  #
  # The order is for the reader only: `builtins.toJSON` sorts attribute
  # names, so what Zed receives is sorted either way.
  baseSettings = {
    # Zed follows the macOS appearance itself, so unlike tlrc and glab
    # it needs no entry in modules/home/darwin/appearance.nix.
    theme = {
      mode = "system";
      dark = "Dracula Pro";
      light = "Dracula Pro (Alucard)";
    };

    buffer_font_family = "Liga SFMono Nerd Font";
    helix_mode = true;
    restore_on_startup = "empty_tab";
    restore_on_file_reopen = false;
    code_lens = "on";

    wrap_guides = [
      72
      80
    ];

    git_panel.commit_title_max_length = 50;
    agent.commit_message_include_project_rules = true;
    agent.default_model = {
      provider = "zed.dev";
      model = "claude-opus-5";
    };

    # Zed generates commit messages with its own model and never
    # reaches prepare-commit-msg, so the global rules are restated for
    # it. A profile's rules cannot be: those are selected by `includeIf
    # gitdir:`, which Zed does not read.
    agent.commit_message_instructions = builtins.readFile ./zed/commit-message-instructions.md;

    agent.commit_message_model = {
      provider = "zed.dev";
      model = "claude-sonnet-5";
    };
    tabs.close_position = "left";
    format_on_save = "on";
    tab_size = 2;

    telemetry = {
      diagnostics = false;
      metrics = false;
    };

    auto_update = false;
    lsp_document_colors = "background";

    # Replaces Zed's own list rather than extending it, so its defaults
    # are restated here.
    file_scan_exclusions = [
      "**/.git"
      "**/.svn"
      "**/.hg"
      "**/.jj"
      "**/.sl"
      "**/.repo"
      "**/CVS"
      "**/.DS_Store"
      "**/Thumbs.db"
      "**/.classpath"
      "**/.settings"
      "**/.ansible"
      "**/.ropeproject"
      "**/.ruff_cache"
      "**/.terraform"
      "**/.venv"
      "**/__pycache__"
      "**/node_modules"

      "**/.cache"
      "**/.ruby-lsp"
      "**/.agentastic"
      "**/.claude"
      "**/.pi"
      "**/.remember"
    ];

    edit_predictions.allow_data_collection = "no";

    # `zed --wait` so a commit started in Zed's terminal opens in Zed
    # rather than in Helix.
    terminal = {
      font_family = "SFMonoTerminal Nerd Font";
      shell.program = "/etc/profiles/per-user/patrick/bin/nu-login";
      option_as_meta = true;

      env = {
        EDITOR = "zed --wait";
        GIT_EDITOR = "zed --wait";
        VISUAL = "zed --wait";
      };
    };

    file_types.Ansible = [
      "**.ansible.yml"
      "**.ansible.yaml"
      "**/defaults/*.yml"
      "**/defaults/*.yaml"
      "**/meta/*.yml"
      "**/meta/*.yaml"
      "**/tasks/*.yml"
      "**/tasks/*.yaml"
      "**/handlers/*.yml"
      "**/handlers/*.yaml"
      "**/group_vars/*.yml"
      "**/group_vars/*.yaml"
      "**/host_vars/*.yml"
      "**/host_vars/*.yaml"
      "**/playbooks/*.yml"
      "**/playbooks/*.yaml"
      "**playbook*.yml"
      "**playbook*.yaml"
    ];

    file_types.CMake = [
      "CMakeLists.txt"
      "cmake"
      "*.cmake.in"
    ];

    file_types.Diff = [
      "diff"
      "patch"
      "rej"
    ];

    file_types.Django = [
      "**/templates/**/*.html"
      "**/templates/**/*.htm"
      "**/templates/**/*.html.j2"
      "**/templates/**/*.htm.j2"
    ];

    file_types."Git Attributes" = [
      "gitattributes"
      ".gitattributes"
      "**/git/attributes"
      "**/.git/info/attributes"
    ];

    file_types."Git Config" = [
      "config.worktree"
      ".gitconfig"
      ".gitmodules"
      ".lfsconfig"
      "*.gitconfig"
      "**/git/config"
      "**/.git/config"
      "**/.git/modules/**/config"
    ];

    file_types."Git Ignore" = [
      ".containerignore"
      ".cursorignore"
      ".dockerignore"
      ".eslintignore"
      ".fdignore"
      ".gitignore"
      ".gitignore_global"
      ".git-blame-ignore-revs"
      ".ignore"
      ".npmignore"
      ".prettierignore"
      ".rgignore"
      ".vscodeignore"
      "**/git/ignore"
      "**/.git/info/exclude"
    ];

    file_types."GitHub Actions" = [
      "**/.github/workflows/*.yml"
      "**/.github/workflows/*.yaml"
      "**/.github/actions/**/action.yml"
      "**/.github/actions/**/action.yaml"
    ];

    file_types.Helm = [
      "**/templates/**/*.tpl"
      "**/templates/**/*.yaml"
      "**/templates/**/*.yml"
      "**/helmfile.d/**/*.yaml"
      "**/helmfile.d/**/*.yml"
      "**/values*.yaml"

      "**/Chart.yaml"
    ];

    file_types."HTML-Jinja" = [
      "jinja"
      "jinja2"
    ];

    # Three file kinds that look alike and must not be treated alike:
    # non-HTML Jinja (Ansible's `.j2` over conf, yaml, ini), HTML Jinja
    # that is not Django, and Django's own templates.
    #
    # A template left as plain HTML is formatted by oxfmt, which reflows
    # it -- `{% extends %}` and `{% block %}` joined onto one line and
    # the body reindented, silently and at exit 0. With `{%- -%}`
    # whitespace control that stops being cosmetic. Its own language is
    # what keeps oxfmt off a file.
    #
    #   templates/page.dj.html  -> Django
    #   page.html.j2            -> HTML-Jinja
    #   vars.j2                 -> HTML-Jinja
    #   vars.yml.j2             -> Jinja2, from the list below
    #
    # The Ansible extension's Jinja2 language does not load: its
    # highlights query names a node type the pinned grammar lacks, so a
    # file routed there opens as Unknown. That still keeps oxfmt away,
    # and these files start highlighting the day it is fixed.
    #
    # An enumeration rather than `**/*.j2`, because a pattern claiming
    # every `.j2` also claims `page.html.j2`, and within `file_types`
    # the alphabetically later language wins -- an order Nix decides,
    # since it sorts attribute names when serialising. A bare `vars.j2`
    # is the one case this cannot reach, being indistinguishable from
    # `page.html.j2` by glob.
    #
    # An extension missing from the list is benign: that file gets
    # HTML-Jinja rather than Unknown.
    file_types.Jinja2 = [
      "**/*.conf.j2"
      "**/*.cfg.j2"
      "**/*.ini.j2"
      "**/*.yml.j2"
      "**/*.yaml.j2"
      "**/*.json.j2"
      "**/*.toml.j2"
      "**/*.sh.j2"
      "**/*.bash.j2"
      "**/*.service.j2"
      "**/*.timer.j2"
      "**/*.socket.j2"
      "**/*.txt.j2"
      "**/*.env.j2"
      "**/*.repo.j2"
      "**/*.list.j2"
      "**/*.sql.j2"
      "**/*.properties.j2"
      "**/*.xml.j2"
      "**/*.tpl.j2"
    ];

    file_types."Nomad Job" = [
      "nomad"
      "*.nomad.hcl"
    ];

    file_types."Python constraints" = [
      "constraints.txt"
      "constraints-*.txt"
      "**/constraints/*.txt"
    ];

    file_types."Python requirements" = [
      "requirements.txt"
      "requirements-*.txt"
      "**/requirements/*.txt"
    ];

    file_types."SSH Config" = [
      "ssh_config"
      "**/.ssh/config"
      "**/.ssh/*-config"
      "**/.ssh/config.d/*"
    ];

    # Zed ships no SVG language, so `.svg` is given to XML.
    file_types.XML = [
      "xml"
      "svg"
    ];

    # Zed fetches these itself; this list is the declaration of which.
    auto_install_extensions = {
      "agnix" = true;
      "ansible" = true;
      "applescript" = true;
      "astro" = true;
      "awk" = true;
      "biome" = true;
      "codebook" = true;
      "codeowners" = true;
      "comment" = true;
      "css-modules-lsp" = true;
      "css-variables" = true;
      "cucumber" = true;
      "deps-language-server" = true;
      "django" = true;
      "dockerfile" = true;
      "emmet" = true;
      "fastapi-lsp" = true;
      "fish" = true;
      "ghostty" = true;
      "git-firefly" = true;
      "github-actions" = true;
      "gitlab-ci-ls" = true;
      "gosum" = true;
      "gotmpl" = true;
      "grafana-alloy" = true;
      "helm" = true;
      "hosts" = true;
      "html" = true;
      "html-jinja" = true;
      "hujson" = true;
      "import-cost-lsp" = true;
      "ini" = true;
      "java" = true;
      "jq" = true;
      "json5" = true;
      "k8s-crd-lsp" = true;
      "log" = true;
      "markdownlint" = true;
      "marksman" = true;
      "mermaid" = true;
      "metal" = true;
      "neocmake" = true;
      "nix" = true;
      "nomad" = true;
      "nu" = true;
      "nu-lint" = true;
      "oxc" = true;
      "package-swift-lsp" = true;
      "path-server-lsp" = true;
      "pbxproj" = true;
      "perl" = true;
      "pgfmt-lsp" = true;
      "postgres-language-server" = true;
      "powershell" = true;
      "pytest-language-server" = true;
      "python-requirements" = true;
      "rainbow-csv" = true;
      "robots-txt" = true;
      "ruby" = true;
      "skill-language-server" = true;
      "sql" = true;
      "sqlalchemy-lsp" = true;
      "ssh-config" = true;
      "swift" = true;
      "terraform" = true;
      "test-coverage-highlight-lsp" = true;
      "tflint" = true;
      "tombi" = true;
      "toml" = true;
      "tsgo" = true;
      "vacuum" = true;
      "xml" = true;
    };

    languages.Ansible = {
      language_servers = [
        "ansible"
        "yaml-language-server"
      ];
      formatter.external = {
        command = "oxfmt";
        arguments = [
          "-c"
          "${oxfmtConfig}"
          "--stdin-filepath"
          "playbook.yaml"
        ];
      };
    };

    languages.AppleScript = {
      remove_trailing_whitespace_on_save = false;
      ensure_final_newline_on_save = false;
    };

    languages.AWK.formatter.external.command = "prettier-awk";

    languages.C = {
      tab_size = 4;
      formatter.external = {
        command = "clang-format-xcode";
        arguments = [ "{buffer_path}" ];
      };
    };

    languages."C++" = {
      tab_size = 4;
      formatter.external = {
        command = "clang-format-xcode";
        arguments = [ "{buffer_path}" ];
      };
    };

    languages.CMake = {
      language_servers = [
        "cmake"

        "..."
      ];
      tab_size = 4;
      wrap_guides = [ ];

      formatter.external = {
        command = "gersemi";
        arguments = [ "-" ];
      };
    };

    languages.Django = {
      formatter.external.command = "prettier-jinja";

      language_servers = [
        "django-language-server"
        "django-template-lsp"
        "..."
      ];
    };

    languages.Dockerfile.formatter.external.command = "dockerfmt-1nl";

    languages.Fish = {
      tab_size = 4;
      formatter.external = {
        command = "fish_indent";
      };
    };

    languages.Gherkin.formatter.external.command = "prettier-gherkin";

    languages."Git Commit" = {
      wrap_guides = [
        50
        72
      ];
      preferred_line_length = 72;
    };

    languages."GitHub Actions" = {
      # An external command rather than the oxfmt language server, which
      # the oxc extension binds to nineteen languages not including this
      # one -- Zed cannot start a server no extension declares, so
      # naming it leaves the buffer silently unformatted. The filename
      # is what tells oxfmt to parse YAML, since the content arrives on
      # stdin.
      formatter.external = {
        command = "oxfmt";
        arguments = [
          "-c"
          "${oxfmtConfig}"
          "--stdin-filepath"
          "workflow.yaml"
        ];
      };
      wrap_guides = [
        72
        100
      ];
    };

    languages.Go.inlay_hints.enabled = true;

    languages."Go Sum".wrap_guides = [ ];

    languages."Grafana Alloy" = {
      hard_tabs = true;
      formatter.external = {
        command = "alloy";
        arguments = [
          "fmt"
          "-"
        ];
      };
    };

    languages.Helm.formatter.external.command = "helmfmt-stdin";

    languages."HTML-Jinja".formatter.external.command = "prettier-jinja";

    languages.HuJSON.prettier = {
      allowed = true;
      parser = "jsonc";
    };

    languages.ini.formatter.external.command = "prettier-ini";
    languages.ini.wrap_guides = [ ];

    languages.Java = {
      tab_size = 4;

      formatter = [ { language_server.name = "jdtls"; } ];

      wrap_guides = [
        72
        120
      ];
    };

    languages.jq.formatter.external.command = "jqfmt-1nl";

    languages.JSON.language_servers = [
      "!vacuum"
      "!package-version-server"
      "..."
    ];

    languages.JSON5.prettier = {
      allowed = true;
      parser = "json5";
    };

    languages.LOG = {
      remove_trailing_whitespace_on_save = false;
      ensure_final_newline_on_save = false;
      wrap_guides = [ ];
      soft_wrap = "editor_width";
    };

    languages.Markdown.formatter.external.command = "prettier-md";
    languages.Markdown.language_servers = [
      "marksman"
      "skill-language-server"
      "agnix-lsp"
      "..."
    ];

    languages.Mermaid.formatter.external.command = "mermaidfmt";
    languages.Mermaid.wrap_guides = [ ];

    languages.Metal = {
      tab_size = 4;
      formatter.external = {
        command = "clang-format-xcode";
        arguments = [ "{buffer_path}" ];
      };
    };

    languages.Nix = {
      language_servers = [
        "nixd"
        "!nil"
        "..."
      ];
      wrap_guides = [
        72
        100
      ];
    };

    languages.Nu = {
      language_servers = [
        "nu"
        "nu-lint"
        "..."
      ];
      tab_size = 4;

      formatter.external = {
        command = "nufmt";
        arguments = [ "--stdin" ];
      };
    };

    languages.Perl = {
      language_servers = [
        "perlnavigator-server"
        "!perl-lsp"
        "..."
      ];
      formatter.external = {
        command = "perltidy";
        arguments = [
          "-st"
          "-se"
        ];
      };
      tab_size = 4;
    };

    # Singular `line_ending`, and `enforce_crlf` rather than
    # `prefer_crlf`: prefer_* applies only to new files and files with
    # no existing line ending, where enforce_* normalises on every
    # format and save. An EditorConfig `end_of_line` overrides it.
    languages.PowerShell.line_ending = "enforce_crlf";
    languages.PowerShell.wrap_guides = [
      72
      120
    ];

    # A `!name` disables a server and `"..."` keeps everything else
    # Zed would attach.
    languages.Python = {
      language_servers = [
        "ty"
        "ruff"
        "pytest-language-server"
        "path-server-lsp"
        "!basedpyright"
        "!fastapi-lsp"
        "!sqlalchemy-lsp"
        "!pylsp"
        "!pyright"
        "..."
      ];

      formatter = [ { language_server.name = "ruff"; } ];
      code_actions_on_format."source.organizeImports.ruff" = true;

      wrap_guides = [
        72
        79
      ];
    };

    languages."Rainbow CSV (,)" = dataFile;
    languages."Rainbow CSV (;)" = dataFile;
    languages."Rainbow CSV (|)" = dataFile;
    languages."Rainbow TSV (⭲)" = dataFile;

    languages.Ruby = {
      language_servers = [
        "ruby-lsp"
        "rubocop"
        "steep"
        "!solargraph"
        "!sorbet"
        "!herb"
        "!kanayago"
        "!fuzzy-ruby-server"
        "..."
      ];

      formatter = [ { language_server.name = "rubocop"; } ];

      wrap_guides = [
        72
        80
      ];
    };

    languages."Shell Script".formatter.external = {
      command = "shfmt";
      arguments = [
        "--filename"
        "{buffer_path}"
        "--indent"
        "2"
        "--binary-next-line"
        "--case-indent"
      ];
    };

    # Tabs because pgfmt emits them and has no option not to.
    languages.SQL = {
      formatter.external.command = "pgfmt-1nl";

      hard_tabs = true;
    };

    languages.Strings = dataFile;

    languages.Swift = {
      tab_size = 4;

      language_servers = [
        "sourcekit-lsp"
        "package-swift-lsp"
        "..."
      ];

      wrap_guides = [
        72
        100
      ];
    };

    languages.Terraform.language_servers = [
      "terraform-ls"
      "tflint"
      "..."
    ];

    # Data rather than prose, so no guides and nothing rewritten on
    # save.
    languages."Xcode Project" = dataFile;

    languages.XML.formatter.external = {
      command = "xmllint";
      arguments = [
        "--format"
        "-"
      ];
    };

    # vacuum claims the whole of YAML and JSON and errors on anything
    # that is not an API description, so it is off globally and a
    # project that keeps a generated OpenAPI document enables it in its
    # own .zed/settings.json.
    languages.YAML.language_servers = [
      "!vacuum"
      "..."
    ];

    lsp.agnix-lsp.binary.path = "${agnixLsp}/bin/agnix-lsp";

    lsp.ansible.binary = {
      path = "${config.home.profileDirectory}/bin/ansible-language-server";
      arguments = [ "--stdio" ];
    };

    lsp."astro-language-server".binary = {
      path = "${config.home.profileDirectory}/bin/astro-ls";
      arguments = [ "--stdio" ];
    };

    lsp.biome.binary = {
      path = "${config.home.profileDirectory}/bin/biome";
      arguments = [ "lsp-proxy" ];
    };

    # Biome's linter is off for the languages something better already
    # reports on. `require_config_file = false` lets it work in a
    # project with no biome.json.
    lsp.biome.settings = {
      require_config_file = false;

      inline_config = {
        linter.enabled = true;
        javascript.linter.enabled = false;
        json.linter.enabled = false;
        css.linter.enabled = false;
        graphql.linter.enabled = false;
      };
    };

    lsp.clangd.initialization_options.fallbackFlags = [ "-Wall" ];

    lsp.django-language-server.binary = {
      path = "${config.home.profileDirectory}/bin/djls";
      arguments = [ "serve" ];
    };

    lsp."django-template-lsp".binary.path = "${config.home.profileDirectory}/bin/djlsp";

    lsp.emmet-language-server.binary = {
      path = "${config.home.profileDirectory}/bin/emmet-language-server";
      arguments = [ "--stdio" ];
    };

    lsp.gitlab-ci.initialization_options = {
      cache = "${config.xdg.cacheHome}/gitlab-ci-ls/";
      log_path = "${config.xdg.cacheHome}/gitlab-ci-ls/gitlab-ci-ls.log";
    };

    # gopls publishes nothing lint-grade until staticcheck is on.
    lsp.gopls.initialization_options.codelenses.test = true;
    lsp.gopls.initialization_options.hints = {
      assignVariableTypes = true;
      compositeLiteralFields = true;
      compositeLiteralTypes = true;
      constantValues = true;
      functionTypeParameters = true;
      parameterNames = true;
      rangeVariableTypes = true;
    };
    lsp.gopls.initialization_options.staticcheck = true;

    lsp.jdtls.settings = {
      java.format.settings.url = "${jdtlsSettings}/formatter.xml";
      java.settings.url = "${jdtlsSettings}/org.eclipse.jdt.core.prefs";
    };
    # modules/home/java.nix carries the same pin; move both together.
    # @VERSION https://openjdk.org/projects/jdk/
    lsp.jdtls.settings.java_home = "${pkgs.jdk25}";

    lsp.markdownlint.binary.path = "${config.home.profileDirectory}/bin/markdownlint-lsp";

    lsp.nixd.settings =
      let
        flake = "builtins.getFlake \"${config.home.homeDirectory}/Developer/github.com/pgodschalk/nix-config\"";
        host = "(${flake}).darwinConfigurations.Patricks-MacBook-Pro";
      in
      {
        nixpkgs.expr = "import (${flake}).inputs.nixpkgs { }";
        options = {
          nix-darwin.expr = "${host}.options";
          home-manager.expr = "${host}.options.home-manager.users.type.getSubOptions [ ]";
        };
      };

    lsp.oxfmt.binary = {
      path = "${config.home.profileDirectory}/bin/oxfmt";
      arguments = [ "--lsp" ];
    };
    # The oxc extension sends initialization_options as is and its
    # `settings` as didChangeConfiguration, and oxfmt reads both
    # `settings` values as the option map itself. Nesting it under
    # `oxc_language_server`, the section oxfmt requests through
    # workspace/configuration, leaves the option silently unread.
    lsp.oxfmt.initialization_options.settings."fmt.configPath" = "${oxfmtConfig}";
    lsp.oxlint.binary = {
      path = "${config.home.profileDirectory}/bin/oxlint";
      arguments = [ "--lsp" ];
    };

    lsp.path-server-lsp.binary.path = "${pathServer}/bin/path-server";

    lsp.powershell-es.binary.path = "${config.home.profileDirectory}/bin/pwsh-lsp";

    lsp.ruff.initialization_options.settings.lineLength = 79;

    # Steep is gradual, so it stays silent until a project has
    # sig/*.rbs; this lets it start without a Steepfile at the root.
    lsp.steep.settings.require_root_steepfile = false;

    lsp."tailwindcss-language-server".settings = {
      includeLanguages.astro = "html";
      experimental.classRegex = [
        ''class="([^"]*)"''
        "class='([^']*)'"
        ''class:list="{([^}]*)}"''
        "class:list='{([^}]*)}'"
      ];
    };

    lsp.terraform-ls.initialization_options.terraform.path = "${pkgs.terraform}/bin/terraform";

    lsp."typescript-language-server".binary = {
      path = "${config.home.profileDirectory}/bin/typescript-language-server";
      arguments = [ "--stdio" ];
    };

    lsp.vacuum.binary = {
      path = "${config.home.profileDirectory}/bin/vacuum";
      arguments = [ "language-server" ];
    };

    lsp."yaml-language-server".settings.yaml.format.enable = true;
    lsp."yaml-language-server".settings.yaml.schemas = {
      "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/inventory.json" =
        [
          "./inventory/*.yaml"
          "hosts.yml"
        ];
    };

    dap.CodeLLDB.binary = codelldb;

    # A remote server with no headers gets Zed's own MCP OAuth flow,
    # so no token is declared for one.
    context_servers = {
      "1password" = {
        command = "/usr/local/bin/1password-mcp";
        args = [ ];
      };
      context7.url = "https://mcp.context7.com/mcp";
      dockerhub = {
        command = "${dockerhubMcpServer}/bin/dockerhub-mcp-server-op";
        args = [ ];
      };
      github = {
        command = "${githubMcpServer}/bin/github-mcp-server-keychain";
        args = [ "stdio" ];
      };
      playwright = {
        command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
        args = [ ];
      };
      sentry.url = "https://mcp.sentry.dev/mcp";
      snippetslab = {
        command = "/Applications/SnippetsLab.app/Contents/Helpers/lab";
        args = [ "mcp" ];
      };
      xcode = {
        command = "/usr/bin/xcrun";
        args = [ "mcpbridge" ];
      };

    };

    # `type` is required: agent_servers is an internally tagged enum,
    # and an entry without it fails to deserialise, which takes the
    # whole settings section with it silently.
    agent_servers = {
      claude-acp.type = "custom";
      claude-acp.command = "${pkgs.claude-agent-acp}/bin/claude-agent-acp";

      claude-acp.default_config_options.mode = "auto";
    };
  };

  # oxfmt formats these; Biome is left attached for its linting except
  # where it is disabled outright.
  biomeFormats = [
    "JavaScript"
    "TypeScript"
    "TSX"
    "JSON"
    "JSONC"
    "CSS"
    "HTML"
    "YAML"
  ];

  biomeDisabled = [
    "Astro"
  ];

  biomeLanguages =
    lib.genAttrs biomeFormats (_: {
      formatter = [ { language_server.name = "oxfmt"; } ];

      wrap_guides = [
        72
        100
      ];
    })
    // lib.genAttrs biomeDisabled (_: {
      language_servers = [
        "!biome"
        "..."
      ];
    });

  settings = lib.recursiveUpdate baseSettings {
    languages = lib.recursiveUpdate biomeLanguages tsLanguages;

    lsp.typescript-ls.binary = {
      path = "${tsgo}/bin/tsgo";
      arguments = [
        "--lsp"
        "--stdio"
      ];
    };
  };

  # The base, before the renderer splices in the token.
  zedSettingsBase = (pkgs.formats.json { }).generate "zed-settings.json" (
    lib.recursiveUpdate settings config.my.zed.extraSettings
  );

  # settings.json is rendered at activation rather than symlinked,
  # because it carries a token that must not reach the store -- and
  # because Zed ignores XDG_CONFIG_HOME on macOS, so the file has to be
  # a real one at ~/.config/zed.
  renderZedSettings = pkgs.writeShellScript "zed-render-settings" (
    substituteFile ./zed/render-settings.sh {
      onePassword = "${pkgs._1password-cli}";
      jq = "${pkgs.jq}";
      spliceToken = "${./zed/splice-token.jq}";
    }
  );
  dataFile = {
    remove_trailing_whitespace_on_save = false;
    ensure_final_newline_on_save = false;
    wrap_guides = [ ];
  };
  pathServer = pkgs.callPackage ../../../pkgs/path-server.nix { };

  agnixLsp = pkgs.callPackage ../../../pkgs/agnix-lsp.nix { };

  tsgo = pkgs.callPackage ../../../pkgs/tsgo.nix { };

  # tsgo's server id is `typescript-ls`, which is also why the
  # css-modules-kit extension cannot reach it: that extension matches
  # `typescript-language-server` and `vtsls` by exact id.
  tsLanguages = lib.genAttrs [ "TypeScript" "TSX" "JavaScript" ] (_: {
    language_servers = [
      "typescript-ls"
      "import-cost-lsp"
      "!vtsls"
      "!css-variables"
      "!eslint"
      "!typescript-language-server"
      "..."
    ];
    inlay_hints.enabled = true;
  });

  jdtlsSettings = pkgs.callPackage ../../../pkgs/jdtls-settings.nix { };
in
{
  config = {
    home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin [
      (pkgs.runCommand "zed-cli" { } (
        substituteFile ./zed/link-zed-cli.sh { zeditor = "${pkgs.zed-editor}/bin/zeditor"; }
      ))
    ];

    home.activation.zedSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      substituteFile ./zed/apply-settings.sh {
        render = "${renderZedSettings}";
        base = "${zedSettingsBase}";
        target = lib.escapeShellArg "${config.home.homeDirectory}/.config/zed/settings.json";
      }
    );
    home.file.".config/zed/keymap.json" = lib.mkIf (keymap != [ ]) {
      source = (pkgs.formats.json { }).generate "zed-keymap.json" keymap;
    };

    # Out of store, so editing the theme in the checkout applies at
    # Zed's next launch.
    home.file.".config/zed/themes/dracula-pro.json".source =
      config.lib.file.mkOutOfStoreSymlink "${draculaProZed}/dracula-pro.json";
  };
}
