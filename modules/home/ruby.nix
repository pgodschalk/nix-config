{
  config,
  pkgs,
  substituteFile,
  ...
}:
let
  # rubocop reads $XDG_CONFIG_HOME/rubocop/config.yml, and an editor
  # launched from the Dock has no XDG_CONFIG_HOME between a login and
  # the next switch -- it would then silently use its 120-column
  # default. `--set-default` still lets a shell that sets the variable
  # win.
  rubocop = pkgs.symlinkJoin {
    name = "rubocop-xdg-${pkgs.rubocop.version}";
    paths = [ pkgs.rubocop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = substituteFile ./ruby/wrap-rubocop.sh {
      configHome = config.xdg.configHome;
    };
  };
in
{
  # Moves Bundler's config, cache and plugins together, where the
  # narrower BUNDLE_USER_CACHE/_CONFIG/_PLUGIN would need three
  # variables. dataHome rather than cacheHome because the persistent
  # global config lives here too.
  home.sessionVariables.BUNDLE_USER_HOME = "${config.xdg.dataHome}/bundle";

  home.packages = [
    # A bootstrapper as much as a server: with no BUNDLE_GEMFILE it
    # composes a bundle of its own in `.ruby-lsp/` inside the project
    # and re-execs under it, so Nix pins the bootstrapper and the server
    # that ends up running is the latest from rubygems.org.
    pkgs.ruby-lsp

    # Attached as a second server because ruby-lsp cannot format:
    # `detect_formatter` returns "none" unless rubocop is a dependency
    # of the project, and forcing the setting needs the gem loadable
    # inside ruby-lsp's own process. `rubocop --lsp` formats and lints
    # on its defaults with no .rubocop.yml.
    rubocop

    # A floor -- with nothing installed, `ruby` and `bundle` resolve to
    # Apple's 2.6 -- and where `rdbg` comes from. debug is a bundled gem
    # in Ruby 3.4, so adding pkgs.rubyPackages.debug as well fails the
    # build on a buildEnv collision.
    pkgs.ruby

    # The only type checking Ruby has here, and gradual: it reports
    # nothing until a project has `sig/*.rbs` and a Steepfile.
    (pkgs.callPackage ../../pkgs/steep { })
  ];

  xdg.configFile."rubocop/config.yml".source = ./ruby/rubocop.yml;
}
