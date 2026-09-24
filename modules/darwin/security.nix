{ lib, ... }:
{
  security.pam.services.sudo_local.touchIdAuth = true;

  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

  system.activationScripts.extraActivation.text = lib.mkAfter (
    builtins.readFile ./security/activation.sh
  );
}
