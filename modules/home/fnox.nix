{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  cfg = config.my.fnox;

  # getExe' rather than getExe: the derivation sets no meta.mainProgram
  # and getExe then guesses the binary name and warns for it.
  fnox = lib.getExe' pkgs.fnox "fnox";

  activate = pkgs.writeText "fnox-activate.nu" (
    substituteFile ./fnox/activate.nu {
      inherit fnox;
      trusted = "${pkgs.writeText "fnox-trusted.json" (builtins.toJSON cfg.trustedDirectories)}";
    }
  );
  completion = pkgs.runCommand "fnox-completion.nu" { } (
    substituteFile ./fnox/completion.sh { inherit fnox; }
  );
in
{
  options.my.fnox.trustedDirectories = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "${config.home.homeDirectory}/Developer/github.com/pgodschalk" ];
    description = "Absolute directories whose fnox.toml files the shell loads secrets from.";
  };

  config = {
    home.packages = [ pkgs.fnox ];

    # `source`, not `use`: both are plain scripts with top-level
    # `def --env` rather than modules.
    #
    # mkAfter matters for the completion half, which wraps whatever
    # external completer it finds: running before
    # modules/home/completions.nix would drop carapace and the fish
    # fallback for every other command.
    programs.nushell.extraConfig = lib.mkAfter ''
      source ${activate}
      source ${completion}
    '';
  };
}
