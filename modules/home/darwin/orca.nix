{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # Manual install, so the path is fixed rather than a store path: Orca
  # updates itself through electron-updater, which a read-only bundle
  # would defeat.
  app = "/Applications/Orca.app";
  cli = "${app}/Contents/Resources/bin/orca";

  # What the upstream cask's `binary` stanza links, without letting the
  # in-app installer write to /usr/local/bin. It execs the script inside
  # the bundle, which finds Orca's Electron binary relative to itself.
  orca = pkgs.writeShellScriptBin "orca" (
    substituteFile ./orca/orca.sh {
      inherit app;
      cli = lib.escapeShellArg cli;
    }
  );

  # What `orca skills install` writes: discovery stubs that have the
  # agent run `orca skills get <name>`, so the guide follows the
  # installed Orca. Orca's own updater skips these, since they are not
  # copies it wrote. Refresh them from a scratch home with
  # `orca skills install --all --agent universal`, leaving out
  # jira-tickets and linear-tickets, the old names of orca-jira and
  # orca-linear.
  # @VERSION https://github.com/stablyai/orca/releases
  skills = lib.mapAttrs (name: _: ./orca/skills + "/${name}") (builtins.readDir ./orca/skills);

  forgeCli =
    {
      tool,
      real,
      tokenVar,
      hostVar,
      defaultHost,
      fromRemote,
    }:
    pkgs.writeShellScriptBin tool (
      substituteFile ./orca/forge-cli.sh {
        inherit
          tool
          tokenVar
          hostVar
          defaultHost
          fromRemote
          ;
        real = lib.escapeShellArg real;
        service = "orca-${tool}";
      }
    );

  # Not in home.packages: zprofile.zsh puts them on PATH for Orca only.
  orcaForgeClis = pkgs.symlinkJoin {
    name = "orca-forge-clis";
    paths = [
      (forgeCli {
        tool = "gh";
        real = lib.getExe config.programs.gh.package;
        tokenVar = "GH_TOKEN";
        hostVar = "GH_HOST";
        defaultHost = "github.com";
        fromRemote = "";
      })
      (forgeCli {
        tool = "glab";
        real = lib.getExe pkgs.glab;
        tokenVar = "GITLAB_TOKEN";
        hostVar = "GITLAB_HOST";
        defaultHost = "gitlab.com";
        fromRemote = "1";
      })
    ];
  };
in
{
  home.packages = [ orca ];

  my.agentSkills.storeSkills = skills;

  # Orca writes its Claude agent hooks to ~/.claude/settings.json
  # whatever CLAUDE_CONFIG_DIR says, and resolves a link before it
  # writes, so this puts them in the settings Claude Code reads. Only
  # the one file: a linked ~/.claude would also expose CLAUDE.md there,
  # which Claude Code loads as project memory in every repository
  # under $HOME.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables.CLAUDE_CONFIG_DIR}/settings.json";

  programs.zsh.profileExtra = substituteFile ./orca/zprofile.zsh {
    bin = lib.escapeShellArg "${orcaForgeClis}/bin";
  };
}
