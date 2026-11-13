{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # The cross-agent skills directory, read by pi, vibe and Zed. A new
  # dotdir in $HOME: the name is fixed by the tools that read it, the
  # same standing as ~/.mcp.json.
  #
  # Claude Code is not one of them -- its own user scope is
  # <CLAUDE_CONFIG_DIR>/skills.
  agentSkillsHome = "${config.home.homeDirectory}/.agents/skills";

  # These are subagents rather than skills: the files carry `tools:` and
  # `model:`, and the body is a system prompt for a dispatched agent.
  # Dropped into a skills directory they would be discovered and then
  # injected into the running agent instead of spawning one. No
  # cross-agent convention exists for them, so they go to Claude Code's
  # own agents directory.
  voltagent = pkgs.fetchFromGitHub {
    owner = "VoltAgent";
    repo = "awesome-claude-code-subagents";
    # @VERSION https://github.com/VoltAgent/awesome-claude-code-subagents/commits/main
    rev = "ed74d115b7fb7026a22a4f816a8e3250f425e3b4";
    hash = "sha256-JMtJ2jtUxkEjEGfFADXgp6F2ZPjmVHdulr55dukBnKs=";
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
      inherit agentsDir;
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
    logging-best-practices = "${boristaneSkills}/skills/logging-best-practices";
  };

  # An upstream rename would let a left-out skill back in under its new
  # name in silence, so every name listed has to exist upstream.
  eccOverlaps = lib.attrNames (import ./claude-skills/ecc-overlaps.nix);
  eccAll = skillsInGroup "${eccSkills}/skills";
  eccMissing = lib.subtractLists eccAll eccOverlaps;
  eccKept =
    assert lib.assertMsg (eccMissing == [ ]) (
      "claude-skills: ecc-overlaps.nix names skills ECC no longer has: "
      + lib.concatStringsSep ", " eccMissing
    );
    lib.subtractLists eccOverlaps eccAll;

  groupedSkills =
    lib.concatMap (g: map (n: lib.nameValuePair n "${g}/${n}") (skillsInGroup g)) skillGroups
    ++ map (n: lib.nameValuePair n "${eccSkills}/skills/${n}") eccKept;

  localSkills = config.my.agentSkills.localSkills;
  storeSkills = config.my.agentSkills.storeSkills;

  # A checkout outside the store, linked as it stands, so an edit there
  # shows without a switch.
  localSkillLinks = lib.mapAttrs (_: config.lib.file.mkOutOfStoreSymlink) localSkills;

  # Skills that reach the skill directories outside the sets above:
  # commitlint as a bare file, snippetslab by activation on macOS.
  generatedSkills = [
    "committing-with-commitlint"
  ]
  ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "snippetslab";

  # listToAttrs keeps the first of a repeated name and `//` the last, so
  # a collision would drop a skill without a word.
  duplicateSkills = lib.attrNames (
    lib.filterAttrs (_: v: builtins.length v > 1) (
      lib.groupBy (x: x.name) (
        groupedSkills
        ++ lib.mapAttrsToList lib.nameValuePair skillSingles
        ++ lib.mapAttrsToList lib.nameValuePair localSkills
        ++ lib.mapAttrsToList lib.nameValuePair storeSkills
        ++ map (n: lib.nameValuePair n null) generatedSkills
      )
    )
  );

  flatSkillSources =
    assert lib.assertMsg (duplicateSkills == [ ]) (
      "claude-skills: more than one collection provides " + lib.concatStringsSep ", " duplicateSkills
    );
    lib.listToAttrs groupedSkills // skillSingles // storeSkills;

  # Both directories get the same flat set: of the consumers only pi
  # discovers skills nested inside grouping folders, and Zed and Claude
  # Code ignore them in silence.
  skillFilesIn =
    dir:
    lib.mapAttrs' (n: src: lib.nameValuePair "${dir}/${n}" { source = src; }) (
      flatSkillSources // localSkillLinks
    );

  # The same set as real directories of symlinked files, for a reader
  # that does not descend into a symlinked directory.
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

  flatDirs = [
    skillsDir
    agentSkillsHome
  ]
  ++ config.my.agentSkills.extraDirs;
  recursiveDirs = config.my.agentSkills.recursiveDirs;
  destinations = flatDirs ++ recursiveDirs;

  claudeSkillFiles =
    lib.foldl' (acc: dir: acc // skillFilesIn dir) { } flatDirs
    // lib.foldl' (acc: dir: acc // skillFilesRecursiveIn dir) { } recursiveDirs
    # commitlint arrives as a bare SKILL.md rather than a directory, so
    # it is named a level deeper instead of linked as one.
    // lib.genAttrs (map (dir: "${dir}/committing-with-commitlint/SKILL.md") destinations) (_: {
      source = commitlintSkill;
    })
    // {
      "${subagentCatalogDir}".source = subagentCatalog;
    };

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
      # Individual .md files, so no `recursive` is needed.
      destinations = [ agentsDir ] ++ config.my.agentSkills.subagentDirs;
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
    # @VERSION https://github.com/obra/superpowers/releases
    rev = "22f0b463e7a5e579904dd6211a520321035526f7";
    hash = "sha256-rP5YsyGuPd9YSW/Fj3aukrq1bLuV+nwwQMK4JaZQgkI=";
  };

  # Three of five categories: in-progress and deprecated are excluded,
  # which is also why the plugin is not installed -- its marketplace
  # offers one plugin covering all five with no way to deselect.
  mattpocockSkills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    # @VERSION https://github.com/mattpocock/skills/releases
    rev = "d1478fcb140db0b93c0c8df17bcfd311844749d0";
    hash = "sha256-ej0ATi0BWaAx+83dBwgCQxr9J2L2qEwKhUIeIRJ03Go=";
  };

  # A skill's frontmatter is always in context, so this and ECC, the two
  # largest collections here, are the entries to trim first.
  jeffallanSkills = pkgs.fetchFromGitHub {
    owner = "Jeffallan";
    repo = "claude-skills";
    # @VERSION https://github.com/Jeffallan/claude-skills/releases
    rev = "36f3fe8052da7c57083783268c6ea3265d075265";
    hash = "sha256-boV0kGmAVlFvZhfIxd8fNhJqkHBfwGrMGhXDInnWLUM=";
  };

  # Everything Claude Code: linked as a group, less the skills in
  # ecc-overlaps.nix.
  eccSkills = pkgs.fetchFromGitHub {
    owner = "affaan-m";
    repo = "ECC";
    # @VERSION https://github.com/affaan-m/ECC/releases
    rev = "c05b2d6614f62f6db0047669aa4eefb223d478f9";
    hash = "sha256-YYQKYFyY17Z6UykhnX+r/t5Y8Ld4EHNrFvzo+Upnl0w=";
  };

  # Teaches an agent to read the enforced commit convention and to
  # self-correct from a rejection rather than reach for --no-verify.
  commitlintSkill = pkgs.fetchurl {
    # @VERSION https://github.com/conventional-changelog/commitlint/commits/master/skills/committing-with-commitlint
    url =
      "https://raw.githubusercontent.com/conventional-changelog/commitlint/"
      + "d8e36560a485c5e5a0a74ebbb48591b3e2e08ca7/skills/committing-with-commitlint/SKILL.md";
    hash = "sha256-5/BHwXggGmGDMgY0umU3Ea+ivIZxcZIxvzl6IGdqEYo=";
  };

  # The skill behind loggingsucks.com: wide events and high-cardinality
  # structured logging.
  boristaneSkills = pkgs.fetchFromGitHub {
    owner = "boristane";
    repo = "agent-skills";
    # @VERSION https://github.com/boristane/agent-skills/commits/main
    rev = "8aa14dd16a1340a6049e6d7cd58e2ed52333a550";
    hash = "sha256-i3pwbHmYm1ezgvSUn5QnnUOZG/T12O8v6GJQ3P448ns=";
  };

  # The repository already carries `.agents/skills/impeccable/`, so it
  # is linked like the others rather than installed as a plugin, which
  # also gives it to pi and vibe.
  impeccableSrc = pkgs.fetchFromGitHub {
    owner = "pbakaus";
    repo = "impeccable";
    # @VERSION https://github.com/pbakaus/impeccable/releases
    rev = "414603bf14c7a344edb466bb1f85690c77ce8b7d";
    hash = "sha256-gwI+IhgwmELfQnfXjUuel6u+zdFD0LZZCLhGH5MSIWk=";
  };

  # The engine comes from pkgs/impeccable-engine.nix, so the launcher
  # never reaches its download branch and never creates ~/.impeccable.
  #
  # $IMPECCABLE_BIN is tested with a bare `[ -x ]` and exec'd with no
  # chmod, which is what makes a store path usable. Placing the binary
  # inside the skill folder instead would not work: that branch is
  # guarded by `chmod +x "$bin" && exec "$bin"`, and on a store path
  # the chmod fails and the `&&` short-circuits.
  #
  # Must equal the skill's own scripts/VERSION: the launcher execs
  # IMPECCABLE_BIN without comparing versions, so a mismatch would run
  # an old engine against new skill files.
  impeccableSkillVersion = lib.trim (
    builtins.readFile "${impeccableSrc}/.agents/skills/impeccable/scripts/VERSION"
  );

  impeccableEngine =
    let
      engine = pkgs.callPackage ../../pkgs/impeccable-engine.nix { };
    in
    assert lib.assertMsg (impeccableSkillVersion == engine.version) (
      "claude-skills: impeccable's skill wants engine ${impeccableSkillVersion},"
      + " but pkgs/impeccable-engine.nix is ${engine.version}"
    );
    if lib.meta.availableOn pkgs.stdenv.hostPlatform engine then engine else null;
in
{
  options.my.agentSkills.extraDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Extra absolute directories to link every skill into.";
  };

  options.my.agentSkills.recursiveDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Extra absolute directories to link every skill into as real directories of file links, for a reader that does not descend into a linked directory.";
  };

  options.my.agentSkills.subagentDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Extra absolute directories to link every subagent into.";
  };

  options.my.agentSkills.destinations = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    default = destinations;
    description = "Every absolute directory each skill reaches: Claude Code's, the cross-agent one, `extraDirs`, then `recursiveDirs`.";
  };

  options.my.agentSkills.storeSkills = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = { };
    example = lib.literalExpression ''{ my-skill = "''${pkgs.my-skills}/my-skill"; }'';
    description = ''
      Skills from the store, by name: a directory holding a SKILL.md,
      such as one a derivation produces. Linked wherever the other
      skills are.
    '';
  };

  options.my.agentSkills.localSkills = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = {
      my-skill = "/Users/me/src/my-skill";
    };
    description = ''
      Skills from checkouts outside the store, by name: the absolute path
      of a directory holding a SKILL.md. Linked wherever the other skills
      are, and followed live rather than copied.
    '';
  };

  config = {
    # One attrset, because `home.file` cannot be defined twice in a
    # module.
    home.file = voltagentFiles // claudeSkillFiles;

    home.activation.snippetslabSkill = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        substituteFile ./claude-skills/snippetslab-skill.sh {
          skillFiles = lib.escapeShellArgs (map (dir: "${dir}/snippetslab/SKILL.md") destinations);
        }
      )
    );

    home.activation.localSkillsRecursive = lib.mkIf (localSkills != { } && recursiveDirs != [ ]) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        substituteFile ./claude-skills/local-skills-recursive.sh {
          recursiveDirs = lib.escapeShellArgs recursiveDirs;
          localSkills = lib.escapeShellArgs (lib.mapAttrsToList (n: path: "${n}=${path}") localSkills);
        }
      )
    );

    # IMPECCABLE_HOME as well, so that a version ignoring
    # IMPECCABLE_BIN, or a system with no asset in
    # pkgs/impeccable-engine.nix, puts its cache under Library rather
    # than in a dotdir.
    home.sessionVariables = lib.mkMerge [
      { IMPECCABLE_HOME = "${config.xdg.cacheHome}/impeccable"; }
      (lib.mkIf (impeccableEngine != null) {
        IMPECCABLE_BIN = "${impeccableEngine}/bin/impeccable";
      })
    ];

    my.launchd.extraVariables = [
      "IMPECCABLE_BIN"
      "IMPECCABLE_HOME"
    ];
  };
}
