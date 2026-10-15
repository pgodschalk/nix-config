{
  config,
  pkgs,
  substituteFile,
  ...
}:
let
  # With GEM_HOME unset, Nix's Ruby falls back to the user gem directory
  # under $XDG_DATA_HOME/gem, which is keyed by Ruby's ABI version
  # alone. A native extension built there links the exact Ruby store
  # path that compiled it, so after a rebuild of the same Ruby version
  # it fails to load with "linked to incompatible libruby" -- and
  # RubyGems still activates it whenever it is the newest copy of a
  # gem, as prism is next to the one rubocop ships with.
  rubyGemDir = ruby: "${ruby}/${ruby.gemPath}";

  # rubocop reads $XDG_CONFIG_HOME/rubocop/config.yml, and an editor
  # launched from the Dock has no XDG_CONFIG_HOME between a login and
  # the next switch -- it would then silently use its 120-column
  # default. `--set-default` still lets a shell that sets the variable
  # win. GEM_HOME names Ruby's own read-only gem tree, which keeps the
  # user gem directory off rubocop's load path.
  rubocop = pkgs.symlinkJoin {
    name = "rubocop-xdg-${pkgs.rubocop.version}";
    paths = [ pkgs.rubocop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = substituteFile ./ruby/wrap-rubocop.sh {
      configHome = config.xdg.configHome;
      gemHome = rubyGemDir pkgs.rubocop.ruby;
    };
  };

  # ruby-lsp's composed bundle installs into GEM_HOME, so it gets a
  # directory named after the Ruby store path: a rebuilt Ruby starts
  # from an empty one instead of loading extensions built for the old.
  # GEM_PATH has to be set as well, since leaving it unset puts the
  # user gem directory back on the path and `bundle check` then passes
  # on the stale gems there.
  ruby-lsp = pkgs.symlinkJoin {
    name = "ruby-lsp-gem-home-${pkgs.ruby-lsp.version}";
    paths = [ pkgs.ruby-lsp ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = substituteFile ./ruby/wrap-ruby-lsp.sh {
      gemHome = "${config.xdg.cacheHome}/ruby-lsp/gems/${baseNameOf pkgs.ruby-lsp.ruby}";
      gemPath = rubyGemDir pkgs.ruby-lsp.ruby;
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
    ruby-lsp

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
