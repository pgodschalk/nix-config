# Hooks and commands for coding agents: check timings, rules drafted
# from repeated failures, and edit, search and CI-wait commands. Two
# binaries from one release: `jouet`, and `joue`, which runs a routine.
#
# Linux takes the static musl builds, which need no patching.
# x86_64-darwin is absent because upstream publishes no such asset.
{
  lib,
  stdenvNoCC,
  fetchurl,
  darwin,
}:

let
  # @VERSION https://github.com/jdx/jouet/releases
  version = "0.0.4";

  # Hashes from the release's SHA256SUMS.
  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-nWra+64YDv7Q3yfgG4BNnZ4oC3CYmWEvYjMfyS+uN4s=";
    };
    aarch64-linux = {
      triple = "aarch64-unknown-linux-musl";
      hash = "sha256-//YTziHzTUELkPT9nFrKfZ2wZ5eRQwx2/hZSwm0O7Ik=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-musl";
      hash = "sha256-il72b3Gg+kcsSPjdEhNB8FN3/F2MMS3DChyGSSmbrF8=";
    };
  };

  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "jouet: no upstream release asset for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "jouet";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jdx/jouet/releases/download/v${version}/jouet-${target.triple}.tar.gz";
    inherit (target) hash;
  };

  nativeBuildInputs = lib.optional stdenvNoCC.hostPlatform.isDarwin darwin.autoSignDarwinBinariesHook;

  sourceRoot = ".";

  dontBuild = true;

  installPhase = builtins.readFile ./jouet/install.sh;

  meta = {
    description = "Wind-up tools for coding agents";
    homepage = "https://jouet.jdx.dev";
    license = lib.licenses.mit;
    mainProgram = "jouet";
    platforms = lib.attrNames targets;
  };
}
