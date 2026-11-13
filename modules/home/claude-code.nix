{
  config,
  lib,
  pkgs,
  substituteFile,
  substituteValue,
  ...
}:
let
  extras = config.my.theme.dracula.extras;
  lineLengths = config.my.mdLint.lineLengths;
  json = pkgs.formats.json { };

  # `errexit` and `pipefail`, which writeShellApplication injects by
  # default, are dropped: `read` returns non-zero on a final field with
  # no trailing newline while having read it perfectly well, and the
  # script would die partway through parsing its own input.
  #
  # jq is not a runtime input: the script resolves it from PATH, where
  # modules/home/jaq.nix installs it.
  claudeStatusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.git ];
    bashOptions = [ "nounset" ];
    text = substituteFile ./claude-code/statusline.sh {
      filter = "${./claude-code/statusline.jq}";
    };
  };

  # One markdownlint config per line length a directory is held to,
  # extending ./claude-code/markdownlint.jsonc. `extends` merges rule
  # by rule, so MD013's two exemptions are restated beside the length
  # rather than inherited. formats.json sorts the keys; the order here
  # is for the reader.
  markdownlintAt =
    length:
    json.generate "markdownlint-${toString length}.jsonc" {
      config = {
        extends = "${./claude-code/markdownlint.jsonc}";
        MD013 = {
          line_length = length;
          code_blocks = false;
          tables = false;
        };
      };
    };

  # Longest directory first, so a nested directory beats its parent:
  # the hook takes the first line whose directory contains the file.
  directoriesByLength = lib.sort (a: b: builtins.stringLength a > builtins.stringLength b) (
    builtins.attrNames lineLengths
  );
  lineLengthTable = lib.concatMapStrings (
    directory:
    let
      length = lineLengths.${directory};
    in
    "${directory}\t${toString length}\t${markdownlintAt length}\n"
  ) directoriesByLength;

  # A PostToolUse hook, so instructions, agent docs and the glossary
  # are checked as they are written.
  # Claude Code reads exit code 2 as "feed stderr back to the model",
  # which is what gets the diagnostics fixed in the same turn.
  #
  # The markdownlint config is passed explicitly rather than discovered,
  # since the file being checked is usually outside any repository. The
  # directories held to another line length travel the same way.
  claudeMdLint = pkgs.writeShellApplication {
    name = "claude-md-lint";
    runtimeInputs = [
      pkgs.jq
      pkgs.markdownlint-cli2
      (pkgs.callPackage ../../pkgs/agnix-lsp.nix { })
      (pkgs.callPackage ../../pkgs/prettier-with-plugins.nix { })
    ];
    runtimeEnv = {
      MARKDOWNLINT_CONFIG = ./claude-code/markdownlint.jsonc;
      MD_LINT_LINE_LENGTHS = lineLengthTable;
    };
    text = substituteFile ./claude-code/md-lint.sh {
      filter = "${./claude-code/md-lint.jq}";
    };
  };

  # A PreToolUse hook choosing git or jj by the nearest repository
  # root, so a colocated checkout gets jj and an Orca worktree inside
  # one gets git. The build runs its tests.
  claudeVcsGuard = pkgs.runCommand "claude-vcs-guard" { } (
    substituteFile ./claude-code/vcs-guard-build.sh {
      python = lib.getExe (
        pkgs.python3.withPackages (ps: [
          ps.tree-sitter
          ps.tree-sitter-bash
        ])
      );
      module = "${./claude-code/vcs_guard.py}";
      tests = "${./claude-code/test_vcs_guard.py}";
    }
  );

  # `claude-plugins-official` is built in and needs no
  # extraKnownMarketplaces entry: Claude Code sources it from
  # downloads.claude.ai itself.
  #
  # `remember` is third-party -- Digital-Process-Tools/claude-remember,
  # cloned from GitHub -- so it updates when the marketplace refreshes
  # rather than when flake.lock moves.
  #
  # The whole of the official marketplace is managed here: settings.jq
  # disables any of its plugins not listed, so one enabled by hand is
  # gone after the next switch.
  officialPlugins = [
    "frontend-design"
    "code-review"
    "skill-creator"
    "code-simplifier"
    "claude-md-management"
    "feature-dev"
    "security-guidance"
    "claude-code-setup"
    "ralph-loop"
    "commit-commands"
    "pr-review-toolkit"
    "remember"
    "claude-security"
    "session-report"
    "code-modernization"
    "project-artifact"
  ];

  enabledPluginKeys = builtins.listToAttrs (
    map (n: {
      name = "${n}@claude-plugins-official";
      value = true;
    }) officialPlugins
  );

  # Helix's `config` for these servers is what the LSP plugin sends.
  # Claude Code passes initializationOptions to a server as they are
  # and answers workspace/configuration by walking `settings`, so each
  # table goes into both.
  helixPayloadServers = [
    "astro-ls"
    "clangd"
    "gopls"
    "jdtls"
    "nixd"
    "rust-analyzer"
    "terraform-ls"
    "yaml-language-server"
  ];
  helixServers = (fromTOML (builtins.readFile ./helix/languages.toml)).language-server;
  unconfigured = builtins.filter (name: !(helixServers.${name} or { } ? config)) helixPayloadServers;

  nixd = config.my.nixd.settings;
  systemKind = if pkgs.stdenv.hostPlatform.isDarwin then "nix-darwin" else "nixos";

  # Filled as helix.nix fills the template, but without TOML's
  # escaping: these strings go into JSON.
  helixPayloads =
    assert lib.assertMsg (unconfigured == [ ]) (
      "claude-code: helix/languages.toml gives no config to " + lib.concatStringsSep ", " unconfigured
    );
    substituteValue (lib.genAttrs helixPayloadServers (name: helixServers.${name}.config)) {
      astroTsdk = "${pkgs.callPackage ../../pkgs/astro-tsdk.nix { }}";
      jdtlsSettings = "${pkgs.callPackage ../../pkgs/jdtls-settings.nix { }}";
      nixpkgsExpr = nixd.nixpkgs.expr;
      inherit systemKind;
      systemOptions = nixd.options.${systemKind}.expr;
      homeManagerOptions = nixd.options.home-manager.expr;
      mbxCargo = (pkgs.callPackage ../../pkgs/mbx.nix { }).cargoShim;
      terraform = "${pkgs.terraform}";
    };

  lspServers =
    let
      commands = lib.importJSON ./claude-code/nix-lsp.json;
    in
    commands
    // lib.mapAttrs (
      name: payload:
      commands.${name}
      // {
        initializationOptions = payload;
        settings = payload;
      }
    ) helixPayloads;
in
{
  options.my.mdLint.lineLengths = lib.mkOption {
    type = lib.types.attrsOf lib.types.ints.positive;
    default = { };
    example = {
      "/home/patrick/Developer/example.com" = 120;
    };
    description = ''
      Line length the md-lint agent hook holds markdown to under each
      absolute directory, where prettier-md and
      claude-code/markdownlint.jsonc otherwise give 80.
    '';
  };

  options.my.claudeCode.enabledPlugins = lib.mkOption {
    type = lib.types.attrsOf lib.types.bool;
    default = enabledPluginKeys // {
      "nix-lsp@nix-config" = true;
    };
    readOnly = true;
    description = ''
      The plugins Nix enables in Claude Code, keyed as settings.json's
      `enabledPlugins`.
    '';
  };

  config = {
    home.packages = [ (pkgs.callPackage ../../pkgs/claude-code.nix { }) ];

    home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";

    my.launchd.extraVariables = [ "CLAUDE_CONFIG_DIR" ];

    # Claude Code watches this directory, so a regenerated theme applies
    # live; modules/home/darwin/appearance.nix switches between the two.
    xdg.configFile."claude-code/themes/dracula-pro.json" = lib.mkIf (extras != null) {
      source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/claude-code/dracula-pro.json";
    };
    xdg.configFile."claude-code/themes/alucard.json" = lib.mkIf (extras != null) {
      source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/claude-code/alucard.json";
    };

    # A marketplace is registered by path in known_marketplaces.json,
    # which is imperative state Claude Code owns, so a /nix/store
    # path would break on the first rebuild. A path under
    # xdg.configHome never changes while its contents stay
    # generation-managed.
    #
    # `recursive = true` is load-bearing: without it the marketplace
    # root is itself a symlink, and Claude Code refuses one with "only
    # plain directories are allowed there". `claude plugin validate`
    # passes either way, so it is not the thing to test with.
    xdg.configFile."claude-marketplace" = {
      source = ../../pkgs/claude-marketplace;
      recursive = true;
    };

    # The same store paths the editors are given, so the LSP plugin
    # cannot fall behind a flake.lock update.
    xdg.configFile."claude-marketplace/plugins/nix-lsp/.lsp.json".source =
      json.generate "nix-lsp.json" lspServers;

    # settings.json is Claude Code's own -- it writes `theme` and `tui`
    # -- so the keys are merged in with jq rather than the file written.
    # ./claude-code/settings.jq is a real file, passed with
    # `--from-file`, so jq's own tooling can read it and it can be run
    # by hand.
    #
    # Two of the keys only stick at user scope. `permissions.defaultMode
    # = "auto"` is source-restricted, so a project or local scope
    # setting any other value overrides it; `remoteControlAtStartup` is
    # ignored outright from those scopes.
    #
    # `outputStyle` takes one of Concise, Proactive, Explanatory or
    # Learning, with the leading capital -- another name is not an
    # error, it simply does not apply. `voiceEnabled` is read as
    # `voice?.enabled ?? voiceEnabled`, so the nested object Claude Code
    # writes itself wins and only the flag is declared.
    # `.sandbox.enabled` is set as a path, so other sandbox keys survive
    # the merge.
    home.activation.claudePluginSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./claude-code/merge-settings.sh {
        settings = lib.escapeShellArg "${config.xdg.configHome}/claude-code/settings.json";
        marketplace = lib.escapeShellArg "${config.xdg.configHome}/claude-marketplace";
        jq = "${pkgs.jq}/bin/jq";
        statusline = lib.escapeShellArg "${claudeStatusline}/bin/claude-statusline";
        mdlint = lib.escapeShellArg "${claudeMdLint}/bin/claude-md-lint";
        vcsguard = lib.escapeShellArg "${claudeVcsGuard}/bin/claude-vcs-guard";
        plugins = lib.escapeShellArg (builtins.toJSON enabledPluginKeys);
        filter = "${./claude-code/settings.jq}";
      }
    );

    home.activation.hideClaudeCodeUrlHandler = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (builtins.readFile ./claude-code/hide-url-handler.sh)
    );
  };
}
