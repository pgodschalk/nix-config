{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # Manual install, so the path is fixed rather than a store path.
  app = "/Applications/Agentastic.dev.app";
  cli = "${app}/Contents/Resources/dev-system.bash";

  # The system-wide `dev` CLI, without letting the app write to
  # /usr/local/bin. It execs the script inside the bundle rather than
  # copying it out, because the CLI speaks JSON-RPC to the running app
  # and a store copy would drift from it.
  #
  # Handed to an interpreter because the script ships non-executable;
  # the app's own installer chmods its copy. pkgs.bash rather than
  # /bin/bash, because bash 4.4 fixed `"$@"` under `set -u`, which this
  # script sets.
  dev = pkgs.writeShellScriptBin "dev" (
    substituteFile ./agentastic/dev.sh {
      inherit app;
      cli = lib.escapeShellArg cli;
      bash = "${pkgs.bash}";
    }
  );

  # Everything under Settings lands in one JSON file that the app
  # rewrites on every change, so a store symlink would be clobbered and
  # these keys are deep-merged at activation instead.
  #
  # `cloud.providers` is deliberately absent: the Fly.io organisation
  # and region live inside a provider record carrying a UUID and
  # credential state, which is account state.
  agentasticSettings = {
    codeReview = {
      # An agent is a reviewer exactly when it is in this list, so
      # one list expresses both halves. Other modules append to it
      # through `my.agentastic.settings`.
      enabledAgentIds = [ "claude-code" ];
    };

    connections = {
      usageDisplayEnabledAgentIds = [ "claude-code" ];
    };

    developerSettings.lspBinaries = lib.mapAttrs (_: toString) lspBinaries;
    general = {
      showEditorJumpBar = true;
      defaultBrowser = "com.apple.Safari";
    };

    terminal = {
      optionAsMeta = true;
      font = {
        name = "SFMonoTerminal Nerd Font";
        size = 13;
        weight = 0;
      };
      # The same wrapper Ghostty and Terminal.app use.
      startupCommand = "custom";
      customStartupCommand = "/etc/profiles/per-user/patrick/bin/nu-login";
    };

    textEditing = {
      font = {
        name = "Liga SFMono Nerd Font";
        size = 12;
        weight = 0.23000000417232513;
      };
      markdownCodeFont = {
        name = "Liga SFMono Nerd Font";
        size = 15;
        weight = 0;
      };
      showReformattingGuide = true;
      indentOption = {
        indentType = "spaces";
        spaceCount = 2;
      };
      defaultTabWidth = 2;
    };

    # The values are each theme file's `name`. Sharing the
    # `dracula-pro.` prefix is what makes Agentastic treat the two as
    # one family with a Light / Dark / Auto switch.
    theme = {
      matchAppearance = true;
      selectedTheme = "dracula-pro.dark";
      selectedDarkTheme = "dracula-pro.dark";
      selectedLightTheme = "dracula-pro.light";
    };

    worktrees = {
      locationMode = "insideRepo";
      startFromOrigin = true;
    };
  };

  # Linked out of store, so a regenerated theme needs no rebuild.
  extras = config.my.theme.dracula.extras;
  themesDir = "${config.xdg.configHome}/Agentastic.dev/Themes";

  # These reach Agentastic's own editor only: it never passes language
  # servers to the agents it launches, unlike MCP servers, which it
  # does inject and which are therefore not declared here.
  #
  # `developerSettings.lspBinaries` maps an LSP language id to one
  # absolute path. The keys are the specification's ids
  # (`typescriptreact`, `shellscript`, `objective-c`) rather than file
  # extensions, and an id it does not use is ignored, so the full spec
  # spelling is the safe choice; a language the spec does not name --
  # Nix, TOML, Astro, fish, Nushell -- cannot be wired at all. There is
  # no room for arguments, so every server sits behind a wrapper
  # supplying its own.
  #
  # Absolute, because a GUI app has no Nix PATH after a logout.
  profileBin = "${config.home.profileDirectory}/bin";
  lspWrapper =
    name: exe: args:
    pkgs.writeShellScript "agentastic-lsp-${name}" (
      substituteFile ./agentastic/lsp-wrapper.sh {
        exe = lib.escapeShellArg exe;
        args = lib.escapeShellArgs args;
      }
    );
  lsp = {
    clangd = lspWrapper "clangd" "/usr/bin/clangd" [ ];
    css = lspWrapper "css" "${profileBin}/vscode-css-language-server" [ "--stdio" ];
    docker = lspWrapper "docker" "${profileBin}/docker-langserver" [ "--stdio" ];
    gopls = lspWrapper "gopls" "${profileBin}/gopls" [ ];
    graphql = lspWrapper "graphql" "${profileBin}/graphql-lsp" [
      "server"
      "-m"
      "stream"
    ];
    html = lspWrapper "html" "${profileBin}/vscode-html-language-server" [ "--stdio" ];
    jdtls = lspWrapper "jdtls" "${profileBin}/jdtls" [ ];
    json = lspWrapper "json" "${profileBin}/vscode-json-language-server" [ "--stdio" ];
    marksman = lspWrapper "marksman" "${profileBin}/marksman" [ "server" ];
    perl = lspWrapper "perl" "${profileBin}/perlnavigator" [ "--stdio" ];
    pwsh = lspWrapper "pwsh" "${profileBin}/pwsh-lsp" [ ];
    ruby = lspWrapper "ruby" "${profileBin}/ruby-lsp" [ ];
    bash = lspWrapper "bash" "${profileBin}/bash-language-server" [ "start" ];
    sql = lspWrapper "sql" "${profileBin}/postgres-language-server" [ "lsp-proxy" ];
    sourcekit = lspWrapper "sourcekit" "/usr/bin/sourcekit-lsp" [ ];
    ts = lspWrapper "ts" "${profileBin}/tsgo" [
      "--lsp"
      "--stdio"
    ];
    ty = lspWrapper "ty" "${profileBin}/ty" [ "server" ];
    yaml = lspWrapper "yaml" "${profileBin}/yaml-language-server" [ "--stdio" ];
  };
  lspBinaries = {
    c = lsp.clangd;
    cpp = lsp.clangd;
    objective-c = lsp.clangd;
    objective-cpp = lsp.clangd;
    css = lsp.css;
    scss = lsp.css;
    less = lsp.css;
    dockerfile = lsp.docker;
    go = lsp.gopls;
    graphql = lsp.graphql;
    html = lsp.html;
    java = lsp.jdtls;
    json = lsp.json;
    markdown = lsp.marksman;
    perl = lsp.perl;
    powershell = lsp.pwsh;
    python = lsp.ty;
    ruby = lsp.ruby;
    shellscript = lsp.bash;
    sql = lsp.sql;
    swift = lsp.sourcekit;
    javascript = lsp.ts;
    javascriptreact = lsp.ts;
    typescript = lsp.ts;
    typescriptreact = lsp.ts;
    yaml = lsp.yaml;
  };

  # From the option rather than the binding above, so settings other
  # modules add are included and their lists concatenated.
  agentasticSettingsJson =
    (pkgs.formats.json { }).generate "agentastic-settings.json"
      config.my.agentastic.settings;
in
{
  config = {
    my.agentastic.settings = agentasticSettings;

    home.packages = [ dev ];

    # The one setting that is a Sparkle plist key rather than JSON.
    # Worth pinning rather than leaving at its default: Agentastic is a
    # manual install because it has to update itself.
    targets.darwin.defaults."dev.agentastic.Agentastic".SUEnableAutomaticChecks = true;

    home.file = lib.mkIf (extras != null) {
      "${themesDir}/Dracula Pro (Dark).theme".source =
        config.lib.file.mkOutOfStoreSymlink "${extras}/src/agentastic/Dracula Pro (Dark).theme";
      "${themesDir}/Dracula Pro (Light).theme".source =
        config.lib.file.mkOutOfStoreSymlink "${extras}/src/agentastic/Dracula Pro (Light).theme";
    };

    home.activation.agentasticSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./agentastic/merge-settings.sh {
        settings = lib.escapeShellArg "${config.xdg.configHome}/Agentastic.dev/settings.json";
        mergeJson = lib.getExe (pkgs.callPackage ../../../pkgs/merge-json.nix { });
        declared = "${agentasticSettingsJson}";
        state = lib.escapeShellArg "${config.xdg.stateHome}/nix-config/agentastic.json";
      }
    );
  };
}
