{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  # The same file holds account-scoped state, Cowork session lists and
  # any MCP servers added in the app, and Claude Desktop rewrites it on
  # every change, so a declared subset is merged in at activation rather
  # than the file being owned.
  cronometerMcpServer = pkgs.callPackage ../../../pkgs/cronometer-mcp-server.nix { };

  claudeDesktopSettings = {
    preferences = {
      menuBarEnabled = false;
    };

    # Local servers only. A remote one is added under Settings ->
    # Connectors and lives in the claude.ai account.
    mcpServers = {
      cronometer = {
        command = lib.getExe cronometerMcpServer;
        env.CRONOMETER_DATA_DIR = "${config.xdg.dataHome}/cronometer-mcp";
      };
    };
  };

  settingsJson =
    (pkgs.formats.json { }).generate "claude-desktop-settings.json"
      claudeDesktopSettings;

  # Not under xdg.configHome: Electron puts app data in the platform's
  # Application Support directory whatever XDG_CONFIG_HOME says.
  configFile = "${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";
in
{
  home.activation.claudeDesktopSettings = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] (
      substituteFile ./claude-desktop/merge-settings.sh {
        file = lib.escapeShellArg configFile;
        mergeJson = lib.getExe (pkgs.callPackage ../../../pkgs/merge-json.nix { });
        declared = "${settingsJson}";
        state = lib.escapeShellArg "${config.xdg.stateHome}/nix-config/claude-desktop.json";
      }
    )
  );
}
