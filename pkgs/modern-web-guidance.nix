# Chrome's Modern Web Guidance: an agent skill plus the CLI it searches
# its guides with. Not in nixpkgs; built from the published npm tarball,
# a dependency-free bundle that carries both, so the skill directory is
# linked from here rather than fetched from GitHub.
#
# Upstream tells the agent to run the CLI through
# `npx -y modern-web-guidance@latest`: unpinned, out of reach inside a
# network-less sandbox, and with its telemetry on. The patch drops
# SKILL.md's npx advice, and post-install.sh points every command at
# this build on PATH. SKILL.md's `--skill-version` must keep matching
# `skill-version.txt` in the same tarball, or the CLI tells the agent to
# have the skill updated.
{ lib, callPackage }:

let
  # @VERSION https://www.npmjs.com/package/modern-web-guidance
  version = "1.0.1";
in
callPackage ./lib/bun-package.nix { } {
  pname = "modern-web-guidance";
  inherit version;
  hash = "sha256-cT09NE1vrVySZ/se2Nr/Xdct9GNOmtayvTsMoX+EOKM=";
  entry = "skills/modern-web-guidance/modern-web.mjs";
  copy = [
    "skills"
    "package.json"
  ];
  patches = [ ./modern-web-guidance/skill.patch ];
  postInstall = ./modern-web-guidance/post-install.sh;

  meta = {
    description = "Modern web platform guidance for coding agents";
    homepage = "https://developer.chrome.com/docs/modern-web-guidance";
    license = [
      lib.licenses.asl20
      lib.licenses.cc-by-40
    ];
  };
}
