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
  version = "0.59.0";
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
        hash = "sha256-ZCz9XspINpz7kz3WBaonWs6LMkjqtc2p2wF91voUkmw=";
      }
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-aarch64-apple-darwin.tar.gz";
        hash = "sha256-OW/3LfIKO5joud2u+r7vE2TWPkbpu1KnwPsLnV9B0uk=";
      }
    ];
    aarch64-linux = [
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-lsp-aarch64-unknown-linux-gnu.tar.gz";
        hash = "sha256-LBHuuOOdnFO/ONlqFTSiXGfumZGLxv46uScOcI8RJgA=";
      }
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-aarch64-unknown-linux-gnu.tar.gz";
        hash = "sha256-wpOrv80Amxv1WUrgbzsElct7DCGnLGG8H+m668MhaHM=";
      }
    ];
    x86_64-linux = [
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-lsp-x86_64-unknown-linux-gnu.tar.gz";
        hash = "sha256-OkMd1bthHGnueEc0kvdDJWm3k1Ol8GpPw54yEx3nxxE=";
      }
      {
        url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-x86_64-unknown-linux-gnu.tar.gz";
        hash = "sha256-/XqKxbQCF3ZKJke/vkZbQ9xc18rrfOSLapYmu6LBmN4=";
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
