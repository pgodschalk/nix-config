# A PostgreSQL formatter that parses with libpg_query, the actual
# PostgreSQL parser, rather than a hand-written SQL grammar. Not in
# nixpkgs.
#
# `TestWASIEquivalence` is skipped, and only that one: it shells out to
# `go build` for a wasm target, which needs cgo cross-compilation the
# sandbox cannot do.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "pgfmt";
  # @VERSION https://github.com/middle-management/pgfmt/releases
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "middle-management";
    repo = "pgfmt";
    rev = "v${finalAttrs.version}";
    hash = "sha256-fbY5C8aohv2uaf5v2qvQ7rn3IFYohN7aHZH/MioeaYA=";
  };

  vendorHash = "sha256-kCGgV5nysDEUKryelygMmGyQsBta7IsNuGsO56qqiXk=";

  checkFlags = [
    "-skip"
    "TestWASIEquivalence"
  ];

  meta = {
    description = "PostgreSQL SQL formatter built on libpg_query";
    homepage = "https://github.com/middle-management/pgfmt";
    license = lib.licenses.mit;
    mainProgram = "pgfmt";
    platforms = lib.platforms.all;
  };
})
