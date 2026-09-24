{ lib, pkgs, ... }:
let
  resend-cli = pkgs.callPackage ../../pkgs/resend-cli.nix { };

  fnoxFragment = "\n" + builtins.readFile ./resend/fnox.toml;
in
{
  home.packages = [ resend-cli ];

  home.sessionVariables = {
    # A strict `=== "1"` comparison in the binary, not truthiness.
    RESEND_NO_UPDATE_NOTIFIER = "1";

    # Defence in depth: nothing here runs `resend login`, and the
    # variable below outranks a stored profile, but the CLI's default
    # store is a plaintext file.
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    RESEND_CREDENTIAL_STORE = "secure_storage";
  };

  xdg.configFile."fnox/config.toml".text = lib.mkAfter fnoxFragment;

  programs.nushell.extraConfig = lib.mkAfter (builtins.readFile ./resend/resend.nu);
}
