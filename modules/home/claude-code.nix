{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  extras = config.my.theme.dracula.extras;

  # `errexit` and `pipefail`, which writeShellApplication injects by
  # default, are dropped: `read` returns non-zero on a final field with
  # no trailing newline while having read it perfectly well, and the
  # script would die partway through parsing its own input.
  #
  # jq is deliberately not a runtime input -- pkgs.jq is kept out of
  # this configuration so it does not shadow macOS's identical
  # /usr/bin/jq, and the script resolves it from PATH.
  claudeStatusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.git ];
    bashOptions = [ "nounset" ];
    text = substituteFile ./claude-code/statusline.sh {
      filter = "${./claude-code/statusline.jq}";
    };
  };

  # A PostToolUse hook, so instructions, agent docs and the glossary
  # are checked as they are written.
  # Claude Code reads exit code 2 as "feed stderr back to the model",
  # which is what gets the diagnostics fixed in the same turn.
  #
  # The markdownlint config is passed explicitly rather than discovered,
  # since the file being checked is usually outside any repository.
  claudeMdLint = pkgs.writeShellApplication {
    name = "claude-md-lint";
    runtimeInputs = [
      pkgs.jq
      pkgs.markdownlint-cli2
      (pkgs.callPackage ../../pkgs/agnix-lsp.nix { })
      (pkgs.callPackage ../../pkgs/prettier-with-plugins.nix { })
    ];
    runtimeEnv.MARKDOWNLINT_CONFIG = ./claude-code/markdownlint.jsonc;
    text = substituteFile ./claude-code/md-lint.sh {
      filter = "${./claude-code/md-lint.jq}";
    };
  };

  # `claude-plugins-official` is built in and needs no
  # extraKnownMarketplaces entry: Claude Code sources it from
  # downloads.claude.ai itself.
  #
  # `remember` is third-party -- Digital-Process-Tools/claude-remember,
  # cloned from GitHub -- so it updates when the marketplace refreshes
  # rather than when flake.lock moves.
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
in
{
  home.packages = [ pkgs.claude-code ];

  # modules/darwin/launchd-env.nix re-exports it to GUI-launched
  # processes.
  home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude-code";

  # Claude Code watches this directory, so a regenerated theme applies
  # live; modules/home/appearance.nix switches between the two.
  xdg.configFile."claude-code/themes/dracula-pro.json" = lib.mkIf (extras != null) {
    source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/claude-code/dracula-pro.json";
  };
  xdg.configFile."claude-code/themes/alucard.json" = lib.mkIf (extras != null) {
    source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/claude-code/alucard.json";
  };

  # A marketplace is registered by path in known_marketplaces.json,
  # which is imperative state Claude Code owns, so a /nix/store path
  # would break on the first rebuild. A path under xdg.configHome never
  # changes while its contents stay generation-managed.
  #
  # `recursive = true` is load-bearing: without it the marketplace root
  # is itself a symlink, and Claude Code refuses one with "only plain
  # directories are allowed there". `claude plugin validate` passes
  # either way, so it is not the thing to test with.
  xdg.configFile."claude-marketplace" = {
    source = ../../pkgs/claude-marketplace;
    recursive = true;
  };

  # The same store paths the editors are given, so the LSP plugin cannot
  # fall behind a flake.lock update.
  xdg.configFile."claude-marketplace/plugins/nix-lsp/.lsp.json".source =
    pkgs.replaceVars ./claude-code/nix-lsp.json
      {
        astroTsdk = pkgs.callPackage ../../pkgs/astro-tsdk.nix { };
        jdtlsSettings = pkgs.callPackage ../../pkgs/jdtls-settings.nix { };
        javaHome = pkgs.jdk25;
        inherit (pkgs) terraform;
      };

  # settings.json is Claude Code's own -- it writes `theme` and `tui` --
  # so the keys are merged in with jq rather than the file written.
  # ./claude-code/settings.jq is a real file, passed with `--from-file`,
  # so jq's own tooling can read it and it can be run by hand.
  #
  # Two of the keys only stick at user scope. `permissions.defaultMode
  # = "auto"` is source-restricted, so a project or local scope setting
  # any other value overrides it; `remoteControlAtStartup` is ignored
  # outright from those scopes.
  #
  # `outputStyle` takes one of Concise, Proactive, Explanatory or
  # Learning, with the leading capital -- another name is not an error,
  # it simply does not apply. `voiceEnabled` is read as
  # `voice?.enabled ?? voiceEnabled`, so the nested object Claude Code
  # writes itself wins and only the flag is declared. `.sandbox.enabled`
  # is set as a path, so other sandbox keys survive the merge.
  home.activation.claudePluginSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    substituteFile ./claude-code/merge-settings.sh {
      settings = lib.escapeShellArg "${config.xdg.configHome}/claude-code/settings.json";
      marketplace = lib.escapeShellArg "${config.xdg.configHome}/claude-marketplace";
      jq = "${pkgs.jq}/bin/jq";
      statusline = lib.escapeShellArg "${claudeStatusline}/bin/claude-statusline";
      mdlint = lib.escapeShellArg "${claudeMdLint}/bin/claude-md-lint";
      plugins = lib.escapeShellArg (builtins.toJSON enabledPluginKeys);
      filter = "${./claude-code/settings.jq}";
    }
  );

  home.activation.hideClaudeCodeUrlHandler = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] (builtins.readFile ./claude-code/hide-url-handler.sh)
  );
}
