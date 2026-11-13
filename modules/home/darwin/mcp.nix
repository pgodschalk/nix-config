{
  pkgs,
  substituteFile,
  ...
}:
let
  githubMcpServer = pkgs.callPackage ../../../pkgs/github-mcp-server-keychain.nix {
    inherit substituteFile;
  };

  dockerhubMcpServer = pkgs.callPackage ../../../pkgs/dockerhub-mcp-server.nix {
    inherit substituteFile;
  };

  darwinMcpServers = {
    # Installed by the 1Password app rather than by Nix, and gated
    # behind "Enable local MCP" in the app -- without it the binary
    # panics about a log directory instead of saying so.
    "1password" = {
      command = "/usr/local/bin/1password-mcp";
      args = [ ];
    };

    # Built from source rather than run as the OCI image upstream
    # publishes; see pkgs/dockerhub-mcp-server.nix. A missing credential
    # degrades to public read-only content.
    dockerhub = {
      command = "${dockerhubMcpServer}/bin/dockerhub-mcp-server-keychain";
      args = [ ];
    };

    # This one exits when it finds no credential, reported by the client
    # as `-32000`, so the keychain wrapper is a prerequisite rather than
    # a nicety.
    github = {
      command = "${githubMcpServer}/bin/github-mcp-server-keychain";
      args = [ "stdio" ];
    };

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

in
{
  # Added to `my.mcp.servers`, which modules/home/mcp.nix writes out, so
  # both halves land in one file.
  my.mcp.servers = darwinMcpServers;
}
