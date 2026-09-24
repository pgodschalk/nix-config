{
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # Declared under the client below because aichat's bundled models.yaml
  # stops at claude-opus-4, and an undeclared name fails with
  # "Unsupported model".
  # @VERSION https://platform.claude.com/docs/en/models/overview
  model = "claude-haiku-4-5-20251001";

  # aichat falls back to $SHELL, which here is the login shell /bin/zsh
  # while the shell being typed into is Nushell.
  targetShell = "nu";

  # These override aichat's builtins: retrieve_role() checks the roles
  # directory before falling back to Role::builtin. The builtin %shell%
  # is three lines and far too weak for a non-POSIX shell, and the
  # builtin explain role knows nothing about which shell it reads.
  shellRole = ./aichat/shell-role.md;
  explainRole = ./aichat/explain-shell-role.md;

  configYaml = pkgs.replaceVars ./aichat/config.yaml { inherit model; };

  fnoxFragment = "\n" + builtins.readFile ./aichat/fnox.toml;
in
{
  home.packages = [ pkgs.aichat ];

  xdg.configFile = {
    "aichat/config.yaml".source = configYaml;
    "aichat/roles/%shell%.md".source = shellRole;
    "aichat/roles/%explain-shell%.md".source = explainRole;
  };

  xdg.configFile."fnox/config.toml".text = lib.mkAfter fnoxFragment;

  programs.nushell.extraConfig = lib.mkAfter (
    substituteFile ./aichat/aichat.nu { inherit targetShell; }
  );
}
