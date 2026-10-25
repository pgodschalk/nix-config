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
  version = "0.59.3";

  # Hashes from each asset's published .sha256 sidecar.
  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      lspHash = "sha256-SQzKkhCvdc6wJG3YrhxO4oELL3Dmq3itmRDDafQGRBw=";
      cliHash = "sha256-8gy/KzN+C/64syjbOyZektkzcg8HdLDJmS8PvNFTtUI=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-gnu";
      lspHash = "sha256-9jh/uckv8pR5Q++dMFJrNyiod8TBOXYzVjG74Rpi8dc=";
      cliHash = "sha256-o1CsSLFgfgK5uo9Qq/9TOkuRFVnd4qH2yoMrFpBDbpM=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-gnu";
      lspHash = "sha256-yVOvWfq/Wa5oOYI8gok/FlmGzhnLGrhpzYv7ogw6Cw0=";
      cliHash = "sha256-8uBUkob7FIsoFFWSIhKb1WHbad3CHNPGwFtS887wnuQ=";
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
