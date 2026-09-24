# Docker's own Docker Hub MCP server, built from source because the
# official distribution is an OCI image and running it would put the
# Docker daemon on the critical path of every agent start-up. There is
# no npm publish: `docker-hub-mcp` and `hub-mcp` are other people's
# packages.
#
# The tag is the only real version -- `package.json` stays at a static
# 1.0.0 -- so `version` below follows it rather than the manifest.
#
# A package rather than a `let` binding, because modules/home/mcp.nix
# and modules/home/darwin/zed.nix must run the same wrapper or only one
# of the two authenticates.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nodejs_22,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about it -- the work layer has two -- still works. The helper
  # is pure Nix, so it costs nothing to import here.
  substituteFile ? (import ../lib lib).substituteFile,
  writeShellScriptBin,
}:
let
  # @VERSION https://github.com/docker/hub-mcp/tags
  version = "0.18.0";
  service = "dockerhub-mcp-server";

  server = buildNpmPackage (finalAttrs: {
    pname = "dockerhub-mcp-server";
    inherit version;

    src = fetchFromGitHub {
      owner = "docker";
      repo = "hub-mcp";
      tag = "dockerhub-mcp/v${finalAttrs.version}";
      hash = "sha256-n4JQKOUOu2OK9RvsOrddTu8bLCUlhDCRW8jkc4a4Ayk=";
    };

    nativeBuildInputs = [ makeWrapper ];

    # Not the default nodejs, which is 24: its npm 11 rejects upstream's
    # lockfile outright, `npm ci` reporting it out of sync with a list
    # of `Missing: @esbuild/<platform>` entries. The lockfile was
    # generated on a machine where only darwin-arm64 resolved, and npm
    # 11 wants every optional platform recorded where npm 10 does not.
    # Upstream's own floor is `engines.node >= 22`, so this is npm's
    # constraint rather than the server's.
    nodejs = nodejs_22;

    npmDepsHash = "sha256-di/EDkHKQrUySc5wtyK2z/nqwAT1UEymx69bVPf+oaM=";

    # The lockfile carries a git dependency, and npm insists on writing
    # to its cache to install one: it fails with EACCES on
    # `_cacache/tmp` against the read-only store copy, and the message
    # blames root-owned files, which is not what is wrong.
    makeCacheWritable = true;

    # `npm run build` is `tsc`, so devDependencies are needed to build
    # and none to run.
    npmBuildScript = "build";

    installPhase = substituteFile ./dockerhub-mcp-server/install.sh {
      node = lib.getExe nodejs_22;
    };

    meta = {
      description = "Docker's MCP server for Docker Hub search, repositories and tags";
      homepage = "https://github.com/docker/hub-mcp";
      license = lib.licenses.asl20;
      mainProgram = "dockerhub-mcp-server";
    };
  });
in
# The credential comes from the macOS login keychain rather than `op`,
# so an agent starting a session raises no Touch ID prompt and nothing
# lands in the generated JSON.
#
# One item carries both values: the account is the Docker Hub username
# that `--username` needs, and the password is the PAT. Matched on the
# service alone: the GitHub item's account is the literal `$USER`, so
# an `-a "$USER"` lookup misses it.
#
# Unlike the GitHub server this does not exit when the lookup fails:
# `HUB_PAT_TOKEN` is optional upstream, so a missing or locked keychain
# degrades to public read-only content.
#
# This is a second copy of the credential; the registry helper in
# modules/home/containers.nix resolves the same PAT from 1Password, so
# rotating it means updating both.
#
# `substituteFile` rather than `builtins.readFile (replaceVars …)`,
# which would be import-from-derivation and take out the Linux eval
# check.
(writeShellScriptBin "dockerhub-mcp-server-keychain" (
  substituteFile ./dockerhub-mcp-server/wrapper.sh {
    serviceArg = lib.escapeShellArg service;
    server = lib.getExe server;
    inherit service;
  }
)).overrideAttrs
  (old: {
    meta = old.meta // {
      platforms = lib.platforms.darwin;
    };
  })
