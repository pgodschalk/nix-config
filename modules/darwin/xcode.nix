{ lib, ... }:
{
  system.defaults.CustomUserPreferences."com.apple.dt.Xcode" = {
    # Lets an agent Xcode cannot authenticate, such as the ad-hoc signed
    # Nix-built claude, reach it through `xcrun mcpbridge`, and with it
    # tools that build and run code in Xcode's context, outside any
    # agent sandbox.
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
