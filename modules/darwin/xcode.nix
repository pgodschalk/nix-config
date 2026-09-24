{ lib, ... }:
{
  system.defaults.CustomUserPreferences."com.apple.dt.Xcode" = {
    IDEAllowUnauthenticatedAgents = true;
    XCFontAndColorCurrentDarkTheme = "Dracula Pro.xcworkspacecolortheme";
    XCFontAndColorCurrentTheme = "Alucard.xcworkspacecolortheme";
  };

  # mkAfter so this follows home-manager's block, where `mas install`
  # puts Xcode on a fresh machine.
  system.activationScripts.postActivation.text = lib.mkAfter (
    builtins.readFile ./xcode/activation.sh
  );
}
