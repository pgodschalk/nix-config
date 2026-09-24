# github-mcp-server, with its credential read from the macOS login
# keychain. A package rather than a `let` binding, because
# modules/home/mcp.nix and modules/home/darwin/zed.nix must run the same
# wrapper or only one of them authenticates.
#
# The server exits immediately without a credential, reported by Claude
# Code as `-32000`. GitHub's remote endpoint is not an option: Claude
# Code's MCP client auto-registers through dynamic client registration,
# and GitHub's auth server requires a pre-registered client.
#
# Matched on the service name alone: the item on this machine has the
# literal string `$USER` as its account, and the service is unique.
{
  lib,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about it -- the work layer has two -- still works. The helper
  # is pure Nix, so it costs nothing to import here.
  substituteFile ? (import ../lib lib).substituteFile,
  writeShellScriptBin,
  github-mcp-server,
}:
let
  service = "github-mcp-server";
in
# `substituteFile` rather than `builtins.readFile (replaceVars …)`,
# which would be import-from-derivation and take out the Linux eval
# check.
writeShellScriptBin "github-mcp-server-keychain" (
  substituteFile ./github-mcp-server-keychain/wrapper.sh {
    serviceArg = lib.escapeShellArg service;
    server = lib.getExe github-mcp-server;
    inherit service;
  }
)
