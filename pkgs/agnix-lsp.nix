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
{
  lib,
  stdenvNoCC,
  fetchurl,
  darwin,
  autoPatchelfHook,
  stdenv,
}:

let
  # @VERSION https://github.com/agent-sh/agnix/releases
  version = "0.55.0";

  # Hashes from each asset's published .sha256 sidecar.
  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      lspHash = "sha256-oR53WA7QAyTWGIjUa0wvryPmy/LxZEjCxFXaTTbzncY=";
      cliHash = "sha256-jrP4RP+NdMperEKC3SAVxmeMgF+JgNSQDtfh415balw=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      lspHash = "sha256-jShAhM0FJde0DNnjOKGi+rDHrNPiseeG+p6rZqTgu4Q=";
      cliHash = "sha256-b90BoTqH3HXmdoqKAceLEZD16YXvRqIc9zatqE9JMQc=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      lspHash = "sha256-A48t9Be7p6tnNGEjZ/ZbRhZ18afA75WQMMWS1q28HmA=";
      cliHash = "sha256-l76iRxdTs4YIVHYG4sEoWndI6V5pMUO+MCw8+7PZw68=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "agnix-lsp: no upstream release asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "agnix-lsp";
  inherit version;

  # Each is a single bare binary with no leading directory, so both
  # unpack side by side into one source root.
  srcs = [
    (fetchurl {
      url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-lsp-${target.triple}.tar.gz";
      hash = target.lspHash;
    })
    (fetchurl {
      url = "https://github.com/agent-sh/agnix/releases/download/v${version}/agnix-${target.triple}.tar.gz";
      hash = target.cliHash;
    })
  ];

  nativeBuildInputs =
    lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook
    ++ lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;

  # Upstream's Linux builds are glibc binaries with the FHS loader, so
  # on Linux they are patched to find it and their libraries in the
  # store.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  sourceRoot = ".";

  dontBuild = true;

  installPhase = builtins.readFile ./agnix-lsp/install.sh;

  meta = {
    description = "Linter for agent configuration (skills, hooks, memory, MCP), as a CLI and a language server";
    homepage = "https://github.com/agent-sh/agnix";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "agnix-lsp";
    platforms = lib.attrNames targets;
  };
}
