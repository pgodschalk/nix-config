{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  cfg = config.my.commitMessages;

  # Declared once so a profile defined in another module lints against
  # the same numbers the hook enforces on what lumen returns.
  inherit (cfg) subjectLimit bodyLimit;

  # With no extra profiles each `case` has only its default branch,
  # which is still valid sh.
  profileCases =
    f: lib.concatStrings (lib.mapAttrsToList (name: p: "  ${name}) ${f name p} ;;\n") cfg.profiles);

  commitlintConfigs = lib.mapAttrs (
    name: p: pkgs.writeText "commitlint.${name}.mjs" p.commitlintConfig
  ) cfg.profiles;

  contextCases = profileCases (_: p: "context=${lib.escapeShellArg p.context}");
  configCases = profileCases (name: _: "config=${commitlintConfigs.${name}}");
  directoryCases = lib.concatStrings (
    lib.concatLists (
      lib.mapAttrsToList (
        name: p: map (dir: "  ${dir}/*) profile=${name} ;;\n") p.directories
      ) cfg.profiles
    )
  );

  contextCase = ''
    case "''${2-}" in
    ${contextCases}  *) context=${lib.escapeShellArg globalContext} ;;
    esac
  '';

  # No default branch: an unmatched directory leaves $profile empty,
  # which is the global profile.
  directoryCase = ''
    case "$(${jj} root --ignore-working-copy 2>/dev/null)/" in
    ${directoryCases}esac
  '';

  # lumen's built-in default for the claude provider is retired, and a
  # bare `lumen draft` then fails with a 404 that reads like an auth
  # problem -- a bad key gives 401. Always name the model.
  # @VERSION https://platform.claude.com/docs/en/models/overview
  model = "claude-sonnet-5";

  # The house style lives here because lumen has no length or style
  # settings of its own.
  globalContext = builtins.readFile ./commit-messages/global-context.txt;

  # No api_key: that is the one field that would put a secret on disk,
  # and the hook resolves LUMEN_API_KEY through fnox instead. No
  # `theme` either -- LUMEN_THEME follows the appearance, and a config
  # value would outrank it.
  lumenConfig = pkgs.writeText "lumen.config.json" (
    builtins.toJSON {
      provider = "claude";
      inherit model;
      wrap = true;
      draft.commit_types = {
        feat = "A new feature";
        fix = "A bug fix";
        docs = "Documentation only changes";
        style = "Changes that do not affect the meaning of the code";
        refactor = "A code change that neither fixes a bug nor adds a feature";
        perf = "A code change that improves performance";
        test = "Adding missing tests or correcting existing tests";
        build = "Changes that affect the build system or external dependencies";
        ci = "Changes to CI configuration files and scripts";
        chore = "Other changes that do not modify src or test files";
        revert = "Reverts a previous commit";
      };
    }
  );

  commitlintGlobal = pkgs.replaceVars ./commit-messages/commitlint.global.mjs {
    subjectLimit = toString subjectLimit;
    bodyLimit = toString bodyLimit;
  };

  # Zed generates commit messages with its own model and never reaches
  # prepare-commit-msg, so modules/home/zed.nix restates the global
  # rules as `agent.commit_message_instructions`. A profile's rules
  # cannot be declared there: profiles are selected by `includeIf
  # gitdir:`, which Zed does not read, so a checkout under a profile's
  # directory needs its own .zed/settings.json.

  # NODE_PATH is load-bearing: nixpkgs ships commitlint as a compiled
  # wrapper that execs `node cli.js` with it set, and without it both
  # runtimes die with "Cannot find module
  # 'conventional-changelog-conventionalcommits'". That reads like a
  # Bun incompatibility and is not.
  commitlintRoot = "${pkgs.commitlint}/lib/node_modules/@commitlint/root";
  commitlintBun = pkgs.writeShellScriptBin "commitlint" (
    substituteFile ./commit-messages/commitlint.sh {
      nodePath = "${commitlintRoot}/node_modules";
      bun = lib.getExe pkgs.bun;
      cli = "${commitlintRoot}/@commitlint/cli/cli.js";
    }
  );

  git = lib.getExe pkgs.git;

  # Hands a repo's own hooks control after ours have run, so a global
  # core.hooksPath does not silently disable them.
  #
  # `--git-dir`, not `--git-path hooks`: the latter resolves through
  # core.hooksPath and returns this very directory, so the hook would
  # exec itself forever.
  chainLocal = ''
    local_hook="$(${git} rev-parse --git-dir)/hooks/$(basename "$0")"
    if [ -x "$local_hook" ]; then
      exec "$local_hook" "$@"
    fi
    exit 0
  '';

  # From git config rather than the environment, so it follows the
  # repository: a hook launched by a GUI has no shell context.
  selectProfile = ''
    profile="$(${git} config --get commitmsg.profile 2>/dev/null || true)"
  '';

  # Shared by the git hook and the jj editor, so both VCSs get the same
  # model, house style and retry. $1 is lumen's backend, $2 the profile.
  # Every failure is non-fatal: a commit must never be blocked because
  # an API call did not work.
  draftScript = pkgs.writeShellScript "commit-message-draft" (
    substituteFile ./commit-messages/draft.sh {
      inherit contextCase;
      fnox = lib.getExe' pkgs.fnox "fnox";
      lumen = lib.getExe pkgs.lumen;
      lumenConfig = "${lumenConfig}";
      subjectLimit = toString subjectLimit;
    }
  );

  commitlintConfigFor = ''
    case "$profile" in
    ${configCases}  *) config=${commitlintGlobal} ;;
    esac
  '';

  # jj runs no git hooks at all, so the two halves above never fire for
  # `jj describe` or `jj commit`. Its one extension point on that path
  # is the editor it opens for the description: draft before it opens,
  # validate after it closes.
  #
  # lumen's jj backend drafts from @ only, so `jj describe -r X` on
  # another change opens the editor without a draft. A non-zero exit
  # aborts the command and leaves the text on disk with jj naming the
  # file, which is commit-msg's behaviour.
  #
  # The profile comes from git config first, so an includeIf applies in
  # a colocated repository, and falls back to the profile directories.
  #
  # `jj describe -m` and `jj commit -m` never open an editor, so neither
  # drafting nor validation happens for them.
  jjEditor = pkgs.writeShellScript "jj-commit-editor" (
    substituteFile ./commit-messages/jj-editor.sh {
      inherit
        directoryCase
        commitlintConfigFor
        git
        jj
        ;
      draftScript = "${draftScript}";
      commitlint = lib.getExe commitlintBun;
    }
  );

  jj = lib.getExe pkgs.jujutsu;

  # Each hook is given only the placeholders it uses: `replaceVars`
  # fails on one that matches nothing, which catches a placeholder
  # renamed in the script but not here.
  prepareCommitMsg = pkgs.replaceVars ./commit-messages/prepare-commit-msg.sh {
    inherit chainLocal selectProfile;
    draftScript = "${draftScript}";
  };

  commitMsg = pkgs.replaceVars ./commit-messages/commit-msg.sh {
    inherit chainLocal selectProfile commitlintConfigFor;
    commitlint = lib.getExe commitlintBun;
  };

  hooks = pkgs.runCommand "commit-message-hooks" { } (
    substituteFile ./commit-messages/install-hooks.sh {
      prepareCommitMsg = "${prepareCommitMsg}";
      commitMsg = "${commitMsg}";
    }
  );
in
{
  options.my.commitMessages = {
    subjectLimit = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "Subject line limit in characters, for lumen and every commitlint config.";
    };
    bodyLimit = lib.mkOption {
      type = lib.types.int;
      default = 72;
      description = "Body line limit in characters, for every commitlint config.";
    };

    profiles = lib.mkOption {
      default = { };
      description = "Commit-message profiles, selected per directory.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            context = lib.mkOption {
              type = lib.types.str;
              description = "Instructions handed to lumen when drafting.";
            };
            commitlintConfig = lib.mkOption {
              type = lib.types.lines;
              description = "A commitlint config module (the file's full text).";
            };
            directories = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Absolute directories whose repositories use this profile.";
            };
          };
        }
      );
    };
  };

  config = {
    home.packages = [
      pkgs.lumen
      commitlintBun
    ];

    programs.jujutsu.settings.ui.editor = "${jjEditor}";

    programs.git = {
      settings.core.hooksPath = "${hooks}";

      # An includeIf rather than an environment variable, because a hook
      # has to work from anywhere the repository is touched and git
      # resolves this from the repository's own path. A pattern ending
      # in `/` gets an implicit `**`.
      includes = lib.concatLists (
        lib.mapAttrsToList (
          name: p:
          map (dir: {
            condition = "gitdir:${dir}/";
            contents.commitmsg.profile = name;
          }) p.directories
        ) cfg.profiles
      );
    };

    xdg.configFile."fnox/config.toml".text = lib.mkAfter (
      "\n" + builtins.readFile ./commit-messages/fnox.toml
    );
  };
}
