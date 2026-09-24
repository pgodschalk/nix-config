{
  config,
  lib,
  pkgs,
  ...
}:
let
  darwinMcpServers = {
    # `lab mcp` is an undocumented subcommand: `lab --help` lists only
    # search/list/fetch/create.
    snippetslab = {
      command = "/Applications/SnippetsLab.app/Contents/Helpers/lab";
      args = [ "mcp" ];
    };

    # Apple's own, three binaries inside Xcode.app rather than a
    # repository; `mcpbridge` is the stdio bridge an agent talks to.
    # `xcrun` rather than an absolute path, so it follows the selected
    # developer directory.
    #
    # No auth, but there is a permission model: access is granted per
    # agent and per folder by `mcp-server approve` / `allow-folder`,
    # and modules/darwin/xcode.nix declares
    # IDEAllowUnauthenticatedAgents.
    xcode = {
      command = "/usr/bin/xcrun";
      args = [ "mcpbridge" ];
    };
  };

  # `xcode` is dropped from the set Xcode's own agent receives: that
  # entry is the bridge into Xcode, whose tools it already injects, so
  # registering it would point the agent back at the Xcode it runs
  # inside.
  xcodeMcpJson = (pkgs.formats.json { }).generate "xcode-mcp-servers.json" {
    mcpServers = lib.removeAttrs config.my.mcp.servers [ "xcode" ];
  };

in
{
  # Added to `my.mcp.servers`, which modules/home/mcp.nix writes out, so
  # both halves land in one file.
  my.mcp.servers = darwinMcpServers;

  # Xcode's own mcp-servers.json cannot be declared: Xcode unlinks and
  # rewrites it from its UI state, clobbering the store symlink. A
  # loose ~/.claude/.mcp.json does not work either -- Xcode refuses a
  # path that "resolves outside the plugin directory" -- so the servers
  # go into the `nix-agents` plug-in that
  # modules/home/claude-skills.nix fills with the skills and subagents,
  # and one import carries all three.
  #
  # The import is a button, so it is imperative, but the contents stay
  # live: Xcode copies the plug-in and the files inside are store
  # symlinks.
  home.file."Library/Application Support/claude-marketplace/plugins/nix-agents/.mcp.json".source =
    xcodeMcpJson;

}
