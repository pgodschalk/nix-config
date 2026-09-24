{ ... }:
{
  targets.darwin.defaults."com.roeybiran.Finbar" = {
    # Apps whose own command palette Finbar must not shadow.
    globalShortcutExcludedApps = [
      "com.mitchellh.ghostty"
      "dev.agentastic.Agentastic"
      "dev.zed.Zed"
    ];

    # Cmd+Shift+P. keyCode 35 is P; 2560 is Command plus Shift in
    # Carbon's encoding.
    RBShortcutKit_Shortcuts."1" = {
      keyCode = 35;
      modifiers = 2560;
    };

    analyticsDisabled = 1;

    # "Show menu bar extra": off. Finbar records the choice only as the
    # Cocoa status-item visibility key.
    "NSStatusItem VisibleCC Item-0" = 0;

    # A brew-nix cask, so the bundle is read-only and a Sparkle update
    # can only fail; versions arrive with `nix flake update brew-api`.
    SUEnableAutomaticChecks = false;
  };
}
