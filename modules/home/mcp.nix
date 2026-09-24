{
  config,
  pkgs,
  substituteFile,
  ...
}:
let
  # From `my.mcp.servers` rather than a local binding, so the darwin
  # module beside this one and the work layer can add servers.
  globalMcpServers = config.my.mcp.servers;

  # In pkgs/ because modules/home/darwin/zed.nix needs the very same
  # wrapper for Zed's native `context_servers`; one definition, so the
  # two registrations cannot drift.
  githubMcpServer = pkgs.callPackage ../../pkgs/github-mcp-server-keychain.nix {
    inherit substituteFile;
  };

  dockerhubMcpServer = pkgs.callPackage ../../pkgs/dockerhub-mcp-server.nix {
    inherit substituteFile;
  };

  portableMcpServers = {

    # Installed by the 1Password app rather than by Nix, and gated
    # behind "Enable local MCP" in the app -- without it the binary
    # panics about a log directory instead of saying so. The path is
    # macOS's; 1Password installs elsewhere on Linux.
    "1password" = {
      command = "/usr/local/bin/1password-mcp";
      args = [ ];
    };

    context7 = {
      type = "http";
      url = "https://mcp.context7.com/mcp";
    };

    # Built from source rather than run as the OCI image upstream
    # publishes; see pkgs/dockerhub-mcp-server.nix. A missing credential
    # degrades to public read-only content.
    dockerhub = {
      command = "${dockerhubMcpServer}/bin/dockerhub-mcp-server-op";
      args = [ ];
    };

    # This one exits when it finds no credential, reported by the client
    # as `-32000`, so the keychain wrapper is a prerequisite rather than
    # a nicety.
    github = {
      command = "${githubMcpServer}/bin/github-mcp-server-keychain";
      args = [ "stdio" ];
    };

    playwright = {
      command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
      args = [ ];
    };
  };

  globalMcpJson = (pkgs.formats.json { }).generate "mcp.json" {
    mcpServers = globalMcpServers;
  };

in
{
  my.mcp.servers = portableMcpServers;

  # Everything here is first-party: only servers published by the vendor
  # of the thing they talk to.
  #
  # No `env` block carries a secret. A stdio server inherits the agent's
  # environment, and a remote one does its own OAuth. The consequence is
  # that a Dock-launched agent has no fnox context, so a stdio server
  # needing a token works from a terminal and not from a GUI launch.
  #
  # Claude Code walks up ancestors for `.mcp.json` and nested files
  # stack rather than override, which is what makes the personal layer
  # below add to this one. Note its separate User scope (`claude mcp add
  # --scope user`) is a different list.
  #
  # A dotfile in $HOME, which principle 1 otherwise forbids: the name is
  # fixed by the tools that read it, the same standing as ~/.ssh.
  home.file.".mcp.json".source = globalMcpJson;

  # The tool-agnostic path, and the one pi's adapter actually reads --
  # it does not read ~/.mcp.json, whose family it treats as
  # compatibility inputs. Both entries are the same store path.
  home.file.".agents/mcp.json".source = globalMcpJson;

  # Adds to the global set for everything under the personal
  # repositories, this one included.
  #
  # The file is a store symlink and therefore read-only, so `claude mcp
  # add` in that directory fails; add servers here instead.
  home.file."Developer/github.com/pgodschalk/.mcp.json" = {
    source = (pkgs.formats.json { }).generate "mcp-personal.json" {
      mcpServers = {
        # OAuth on first connect, so no token. Left unscoped, which
        # covers every org the account can see; the endpoint also
        # accepts `/mcp/{org}/{project}`.
        sentry = {
          type = "http";
          url = "https://mcp.sentry.dev/mcp";
        };
      };
    };
  };
}
