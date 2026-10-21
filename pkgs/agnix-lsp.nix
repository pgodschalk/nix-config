# A linter for agent configuration -- CLAUDE.md, AGENTS.md, SKILL.md,
# hook and MCP JSON -- as a language server and a CLI, two binaries from
# one release so there is one version to bump. Upstream's `agnix-mcp` is
# left out, since an MCP server declared here lands in every agent and
# duplicates what the CLI does on demand.
#
# Pinning is the only way to control the version: the Zed extension
# never calls `which` and goes straight to `latest_github_release`, so
# the pin is applied through `lsp.agnix-lsp.binary.path`, which
# short-circuits the extension.
#
# x86_64-darwin is absent because upstream publishes no such asset.
{ lib, callPackage }:

let
  # @VERSION https://github.com/agent-sh/agnix/releases
  version = "0.61.0";
in
callPackage ./lib/release-binary.nix { } {
  pname = "agnix-lsp";
  inherit version;

  # Each system lists the language server asset, then the CLI asset;
  # hashes come from each asset's published .sha256 sidecar.
  assets = {
    aarch64-darwin = [
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-lsp-aarch64-apple-darwin.tar.gz";
        hash = "sha256-rl7W7jUe6xECAuNwLhUDXvU1FGyJF0MC0+l6m3sFYeI=";
      }
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-aarch64-apple-darwin.tar.gz";
        hash = "sha256-+16jdS/7/ktuGd4iVUAyNx07JA7kBx7DuK9POkBkFR4=";
      }
    ];
    aarch64-linux = [
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-lsp-aarch64-unknown-linux-gnu.tar.gz";
        hash = "sha256-IZu206Fq7Xowh2ksFBXFbJf6LP/yZu5GmkzjEfxy2V8=";
      }
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-aarch64-unknown-linux-gnu.tar.gz";
        hash = "sha256-Ku41lIUFYGfamRmouPOjV8+5ls8bKz+GQ4DEuKQyF6k=";
      }
    ];
    x86_64-linux = [
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-lsp-x86_64-unknown-linux-gnu.tar.gz";
        hash = "sha256-ee5JzLwAme1GNNQ/oQdF25QrprLKjEXLBoJsfe1U0/s=";
      }
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-x86_64-unknown-linux-gnu.tar.gz";
        hash = "sha256-z8j0xaUdAju8h0L7hPQgsS09SbYhyMz7c4LF9zlErQk=";
      }
    ];
  };

  binaries = [
    "agnix-lsp"
    "agnix"
  ];

  meta = {
    description = "Linter for agent configuration (skills, hooks, memory, MCP), as a CLI and a language server";
    homepage = "https://github.com/agent-sh/agnix";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "agnix-lsp";
  };
}
