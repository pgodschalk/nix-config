{
  config,
  lib,
  pkgs,
  ...
}:
let
  cronometerMcpServer = pkgs.callPackage ../../../pkgs/cronometer-mcp-server.nix { };
in
{
  # The same file holds account-scoped state, Cowork session lists and
  # any MCP servers added in the app, and Claude Desktop rewrites it on
  # every change, so a declared subset is merged in at activation rather
  # than the file being owned.
  my.mergedSettings.claude-desktop = {
    # Not under xdg.configHome: Electron puts app data in the platform's
    # Application Support directory whatever XDG_CONFIG_HOME says.
    file = "${config.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";

    # Claude Desktop publishes no settings reference, so keys are
    # alphabetical; pkgs.formats.json sorts the output either way.
    value = {
      # Local servers only. A remote one is added under Settings ->
      # Connectors and lives in the claude.ai account.
      mcpServers = {
        cronometer = {
          command = lib.getExe cronometerMcpServer;
          env.CRONOMETER_DATA_DIR = "${config.xdg.dataHome}/cronometer-mcp";
        };
      };

      preferences = {
        menuBarEnabled = false;
      };
    };
  };

  home.activation.claudeDesktopRunning =
    lib.hm.dag.entryBetween [ "mergedSettings" ] [ "writeBoundary" ]
      (builtins.readFile ./claude-desktop/warn-running.sh);
}
