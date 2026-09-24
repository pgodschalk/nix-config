# The RBS-based gradual type checker for Ruby, not in nixpkgs in any
# form -- `rubyPackages.rbs` is the signature library rather than the
# checker.
#
# bundlerApp from a locked gemset rather than assembled out of
# `rubyPackages`, which cannot work: Steep wants `rbs ~> 4.2` and
# `terminal-table >= 2` where nixpkgs has 3.9.5 and 1.6.0.
#
# Regenerating after a version bump, from this directory:
#
#     bundle lock --update      # refresh Gemfile.lock
#     bundix --lock             # refresh gemset.nix
#
# Gemfile.lock pins the tree and gemset.nix carries the hashes; the
# three files are committed together.
{
  lib,
  bundlerApp,
  makeWrapper,
  runCommand,
  # Defaulted rather than required, so a `callPackage` that does not
  # know about the helper still works. It is pure Nix, so importing it
  # here costs nothing.
  substituteFile ? (import ../../lib lib).substituteFile,
}:

let
  app = bundlerApp {
    pname = "steep";
    gemdir = ./.;
    exes = [ "steep" ];

  };
in

# The wrapper is load-bearing: bundlerApp's binstub sets only GEM_HOME,
# which leaves `Gem.path` including Ruby's user gem directory -- where
# ruby-lsp installs its composed bundle, built against a different Ruby.
# Steep then loads that prism and dies with "LoadError: linked to
# incompatible libruby", which reads as a broken package.
#
# Unsetting GEM_HOME and GEM_PATH does not help, since they are already
# unset and the user directory is a default rather than an override.
# Setting GEM_PATH at all replaces that default, so the user directory
# drops out; it names the bundle's own gem tree.
runCommand "steep-${app.version}"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "Gradual type checker for Ruby, driven by RBS signatures";
      homepage = "https://github.com/soutaro/steep";
      license = lib.licenses.mit;
      mainProgram = "steep";
    };
  }
  (
    substituteFile ./wrap.sh {
      steep = "${app}/bin/steep";
      gemPath = "${app.basicEnv}/${app.basicEnv.ruby.gemPath}";
    }
  )
