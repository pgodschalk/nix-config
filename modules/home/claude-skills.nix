{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # The cross-agent skills directory, read by pi, vibe and Zed. A new
  # dotdir in $HOME, which principle 1 otherwise forbids: the name is
  # fixed by the tools that read it, the same standing as ~/.mcp.json.
  #
  # Claude Code is not one of them -- its own user scope is
  # <CLAUDE_CONFIG_DIR>/skills.
  agentSkills = ".agents/skills";
  agentSkillsHome = "${config.home.homeDirectory}/${agentSkills}";

  # These are subagents rather than skills: the files carry `tools:` and
  # `model:`, and the body is a system prompt for a dispatched agent.
  # Dropped into a skills directory they would be discovered and then
  # injected into the running agent instead of spawning one. No
  # cross-agent convention exists for them, so they go to Claude Code's
  # own agents directory.
  voltagent = pkgs.fetchFromGitHub {
    owner = "VoltAgent";
    repo = "awesome-claude-code-subagents";
    # @VERSION
    # https://github.com/VoltAgent/awesome-claude-code-subagents/commits/main
    rev = "82b73821baa7a911d5b14cfb6da238b7f0db6b42";
    hash = "sha256-OPy2toCmhPbDnqUcM7B+Ufm6BA8xIpNc6U8Gemc/1jk=";
  };

  agentsDir = "${config.xdg.configHome}/claude-code/agents";

  # Claude Code's skill scope is flat -- one directory per skill holding
  # its SKILL.md -- while every collection here is shaped
  # `group/skill/SKILL.md`, so linking the groups would put each
  # SKILL.md a level too deep and none would load. The leaves are
  # therefore enumerated at evaluation time.
  skillsDir = "${config.xdg.configHome}/claude-code/skills";

  # A command group from the same repository as the subagents, giving
  # /subagent-catalog:search and friends. A subdirectory of commands/
  # becomes the namespace before the colon.
  #
  # A derivation rather than a plain link because two hardcoded
  # ~/.claude paths have to be patched out: config.sh caches under
  # $HOME/.claude in a `readonly` assignment with no override, and each
  # command sources config.sh by absolute path.
  commandsDir = "${config.xdg.configHome}/claude-code/commands";
  subagentCatalogDir = "${commandsDir}/subagent-catalog";
  subagentCatalog = pkgs.runCommand "subagent-catalog" { } (
    substituteFile ./claude-skills/subagent-catalog.sh {
      voltagent = "${voltagent}";
      cacheFile = "${config.xdg.cacheHome}/subagent-catalog/catalog.md";
      configFile = "${subagentCatalogDir}/config.sh";
    }
  );

  # `readDir` follows into the store path, so this is the real listing.
  skillsInGroup =
    dir:
    lib.filter (n: builtins.pathExists "${dir}/${n}/SKILL.md") (
      builtins.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir dir))
    );

  # `groups` hold `<skill>/SKILL.md`; `singles` are one skill each,
  # named by the attribute.
  skillGroups = [
    "${superpowers}/skills"
    "${mattpocockSkills}/skills/engineering"
    "${mattpocockSkills}/skills/productivity"
    "${mattpocockSkills}/skills/misc"
    "${jeffallanSkills}/skills"
  ];

  skillSingles = {
    impeccable = "${impeccableSrc}/.agents/skills/impeccable";
  };

  # A name repeated across collections would be a duplicate-key
  # evaluation error rather than a silent overwrite.
  flatSkillSources =
    lib.listToAttrs (
      lib.concatMap (g: map (n: lib.nameValuePair n "${g}/${n}") (skillsInGroup g)) skillGroups
    )
    // skillSingles;

  # Both directories get the same flat set: of the consumers only pi
  # discovers skills nested inside grouping folders, and Zed and Claude
  # Code ignore them in silence.
  skillFilesIn =
    dir: lib.mapAttrs' (n: src: lib.nameValuePair "${dir}/${n}" { source = src; }) flatSkillSources;

  # The same set as real directories of symlinked files, because Xcode's
  # plug-in importer does not descend into a symlinked directory.
  # `recursive = true` walks the source and links each file, creating
  # real directories on the way.
  skillFilesRecursiveIn =
    dir:
    lib.mapAttrs' (
      n: src:
      lib.nameValuePair "${dir}/${n}" {
        source = src;
        recursive = true;
      }
    ) flatSkillSources;

  extraSkillDirs = config.my.agentSkills.extraDirs;

  # Xcode takes one plug-in rather than loose files: subagents, hooks
  # and MCP servers are plug-in relative, and it refuses anything that
  # "resolves outside the plugin directory". So everything goes into
  # `nix-agents` in the local marketplace
  # modules/home/claude-code.nix materialises, and one "Add from file"
  # carries all three.
  xcodePluginDir = "${config.xdg.configHome}/claude-marketplace/plugins/nix-agents";
  xcodeSkillsDir = "${xcodePluginDir}/skills";

  claudeSkillFiles =
    skillFilesIn skillsDir
    // skillFilesIn agentSkills
    // lib.foldl' (acc: dir: acc // skillFilesIn dir) { } extraSkillDirs
    // skillFilesRecursiveIn xcodeSkillsDir
    # commitlint arrives as a bare SKILL.md rather than a directory, so
    # it is named a level deeper instead of linked as one.
    // {
      "${skillsDir}/committing-with-commitlint/SKILL.md".source = commitlintSkill;
      "${agentSkills}/committing-with-commitlint/SKILL.md".source = commitlintSkill;
      "${xcodeSkillsDir}/committing-with-commitlint/SKILL.md".source = commitlintSkill;
      "${subagentCatalogDir}".source = subagentCatalog;
    }
    // lib.genAttrs (map (dir: "${dir}/committing-with-commitlint/SKILL.md") extraSkillDirs) (_: {
      source = commitlintSkill;
    });

  # Flattened, as upstream's own install-agents.sh does. Enumerated
  # rather than linked as one directory, so the agents directory stays
  # writable for anything added by hand.
  #
  # A subagent's description has to be in context for the model to know
  # it can be dispatched, so this whole set is always loaded.
  voltagentFiles =
    let
      categories = builtins.attrNames (
        lib.filterAttrs (_: t: t == "directory") (builtins.readDir "${voltagent}/categories")
      );
      agentsIn =
        c:
        lib.filter (f: lib.hasSuffix ".md" f && f != "README.md") (
          builtins.attrNames (builtins.readDir "${voltagent}/categories/${c}")
        );
      # Claude Code's own user scope, and the `agents/` directory of the
      # nix-agents plug-in, where Xcode's importer looks. These are
      # individual .md files, so no `recursive` is needed -- the
      # importer reads a symlinked file happily.
      destinations = [
        agentsDir
        "${xcodePluginDir}/agents"
      ];
    in
    lib.listToAttrs (
      lib.concatMap (
        c:
        lib.concatMap (
          f:
          map (dir: {
            name = "${dir}/${f}";
            value.source = "${voltagent}/categories/${c}/${f}";
          }) destinations
        ) (agentsIn c)
      ) categories
    );

  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    # @VERSION https://github.com/obra/superpowers/commits/main
    rev = "5bf4e78011075bcfc0dc295f0724994cd123ee71";
    hash = "sha256-rgeJhjQyABYlhlyFRmgyhbZmmmIPPNkch4CXyTkGEyM=";
  };

  # Three of five categories: in-progress and deprecated are excluded,
  # which is also why the plugin is not installed -- its marketplace
  # offers one plugin covering all five with no way to deselect.
  mattpocockSkills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    # @VERSION https://github.com/mattpocock/skills/commits/main
    rev = "c55ee46073ed923f86ce59a5eb3b6d895095d1b7";
    hash = "sha256-L3CpIT2DeI+fUFl9fcygojtQo2DzEen69rMD1XqR1vM=";
  };

  # By far the largest collection here, and a skill's frontmatter is
  # always in context, so this is the entry to trim first.
  jeffallanSkills = pkgs.fetchFromGitHub {
    owner = "Jeffallan";
    repo = "claude-skills";
    # @VERSION https://github.com/Jeffallan/claude-skills/commits/main
    rev = "882ef55e377dbf9a4dbe496bb41ac6ccd0e555cf";
    hash = "sha256-XOy2b60XpqRB/hkpR0ddtDMAhbO1tW5C4TfXgCozg5o=";
  };

  # Teaches an agent to read the enforced commit convention and to
  # self-correct from a rejection rather than reach for --no-verify.
  commitlintSkill = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/conventional-changelog/commitlint/"
      + "36dc150fc3c0ef5f0860e9f2ef7729a6d9c7db72/skills/committing-with-commitlint/SKILL.md";
    hash = "sha256-5/BHwXggGmGDMgY0umU3Ea+ivIZxcZIxvzl6IGdqEYo=";
  };

  # The repository already carries `.agents/skills/impeccable/`, so it
  # is linked like the others rather than installed as a plugin, which
  # also gives it to pi and vibe.
  impeccableSrc = pkgs.fetchFromGitHub {
    owner = "pbakaus";
    repo = "impeccable";
    # @VERSION https://github.com/pbakaus/impeccable/releases
    rev = "83c2c735777c68e30ea536ab9cc97f7843456945";
    hash = "sha256-YrDGHSH0fvMyjU754s444KIJWXUcFgCTUFSfWgYHYjc=";
  };

  # The engine binary, pinned so the launcher never reaches its download
  # branch and never creates ~/.impeccable.
  #
  # $IMPECCABLE_BIN is tested with a bare `[ -x ]` and exec'd with no
  # chmod, which is what makes a store path usable. Placing the binary
  # inside the skill folder instead would not work: that branch is
  # guarded by `chmod +x "$bin" && exec "$bin"`, and on a store path
  # the chmod fails and the `&&` short-circuits.
  #
  # The version is the one the launcher compares against, from the
  # skill's own scripts/VERSION, so bumping impeccableSrc without
  # bumping this sends it back to downloading.
  # @VERSION https://github.com/pbakaus/impeccable/releases
  impeccableEngineVersion = "0.1.5";
  impeccableEngineAssets = {
    aarch64-darwin = {
      asset = "impeccable-darwin-arm64";
      hash = "sha256-DUi24WqpdmT9vmB9XamuMg44mhhD4P8TKPjCUwUwMg0=";
    };
    aarch64-linux = {
      asset = "impeccable-linux-arm64";
      hash = "sha256-vE+ii8jMuwGHlamaTs6VraiYpvGIXxQoE4nQ5u8qL5g=";
    };
    x86_64-linux = {
      asset = "impeccable-linux-x64";
      hash = "sha256-z1IxpLGuZplshbAzgAsdrQeX5ZDq4vIe8leUMK8Yfxk=";
    };
  };
  impeccableEngineAsset = impeccableEngineAssets.${pkgs.stdenv.hostPlatform.system} or null;

  impeccableEngine =
    if impeccableEngineAsset == null then
      null
    else
      pkgs.runCommand "impeccable-engine-${impeccableEngineVersion}" {
        src = pkgs.fetchurl {
          url =
            "https://github.com/pbakaus/impeccable/releases/download/"
            + "engine-v${impeccableEngineVersion}/${impeccableEngineAsset.asset}";
          inherit (impeccableEngineAsset) hash;
        };
        meta.mainProgram = "impeccable";
      } (builtins.readFile ./claude-skills/impeccable-engine.sh);
in
{
  options.my.agentSkills.extraDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Extra absolute directories to link every skill into.";
  };

  config = {
    # One attrset, because `home.file` cannot be defined twice in a
    # module.
    home.file = voltagentFiles // claudeSkillFiles;

    home.activation.snippetslabSkill = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        substituteFile ./claude-skills/snippetslab-skill.sh {
          agentSkill = lib.escapeShellArg "${agentSkillsHome}/snippetslab/SKILL.md";
          claudeSkill = lib.escapeShellArg "${skillsDir}/snippetslab/SKILL.md";
        }
      )
    );

    # IMPECCABLE_HOME as well, so that a version ignoring
    # IMPECCABLE_BIN, or a system with no hash here, puts its cache
    # under Library rather than in a dotdir.
    home.sessionVariables = lib.mkMerge [
      { IMPECCABLE_HOME = "${config.xdg.cacheHome}/impeccable"; }
      (lib.mkIf (impeccableEngine != null) {
        IMPECCABLE_BIN = "${impeccableEngine}/bin/impeccable";
      })
    ];
  };
}
