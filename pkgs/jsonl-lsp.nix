# Language server for JSON Lines: per-record diagnostics, formatting,
# a record outline and hover. Not in nixpkgs.
#
# The server's only dependency is jsonl-core, which has none, so the
# two npm tarballs are fetched directly. The binary name matters: Zed's
# jsonl-lsp extension resolves `worktree.which("jsonl-lsp")` before
# npm.
{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  makeWrapper,
  substituteFile ? (import ../lib lib).substituteFile,
}:

let
  # Bumping this means bumping the version and hash of `core` too;
  # the two are released together.
  # @VERSION https://www.npmjs.com/package/@sarvagnan/jsonl-core
  core = fetchurl {
    url = "https://registry.npmjs.org/@sarvagnan/jsonl-core/-/jsonl-core-0.2.0.tgz";
    hash = "sha512-wzdJgrv+2HZPquMHz680BwYKgZSozbzKMNbeXKvoxU0fiH47pmomBZOKfsgDGlURLHvBIoXLrDVYyWOifvJ+gg==";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jsonl-lsp";
  # @VERSION https://www.npmjs.com/package/@sarvagnan/jsonl-lsp
  version = "0.2.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@sarvagnan/jsonl-lsp/-/jsonl-lsp-${finalAttrs.version}.tgz";
    hash = "sha512-CbrgqxGnXsSQlnkk8PbMVEHjjOBX7BD7j2lAeMFawJqbBmd7ZZVmBKAViKALP9zTlNJ65NHsjmX6hruCcoeJQA==";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = substituteFile ./jsonl-lsp/install.sh {
    node = lib.getExe nodejs;
    core = "${core}";
  };

  meta = {
    description = "Language server for JSON Lines and NDJSON";
    homepage = "https://github.com/sarvagnan/jsonl-tools";
    license = lib.licenses.bsd0;
    mainProgram = "jsonl-lsp";
    platforms = lib.platforms.all;
  };
})
