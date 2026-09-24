{ pkgs, substituteFile, ... }:
let
  bundled = "${pkgs.powershell-editor-services}/lib/powershell-editor-services";

  # A stdio launcher, which Helix needs and nixpkgs does not provide:
  # its own `powershell-editor-services` wrapper forwards `$@` and
  # supplies none of the six mandatory parameters, splicing them inside
  # a double-quoted `-c` string where a path with a space comes apart.
  # A different name, so the two do not collide in the profile.
  psesStdio = pkgs.writeShellScriptBin "pwsh-lsp" (
    substituteFile ./powershell/pwsh-lsp.sh {
      pwsh = "${pkgs.powershell}/bin/pwsh";
      inherit bundled;
    }
  );
in
{
  home.packages = [
    pkgs.powershell

    # Also brings PSScriptAnalyzer, which is what lints PowerShell.
    pkgs.powershell-editor-services

    psesStdio
  ];
}
