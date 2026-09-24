{
  config,
  lib,
  pkgs,
  substituteFile,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  opener = if isDarwin then "/usr/bin/open" else "xdg-open";

  extras = config.my.theme.dracula.extras;

  # Themes whose variable holds a path rather than the theme itself,
  # generated here because only nix-config knows where the real git
  # config was written and where the store paths land.
  gitconfigTemplate = pkgs.writeText "variant.gitconfig" (
    substituteFile ./nushell/path-themes/variant.gitconfig {
      extras = "${extras}";
      homeGitconfig = "${config.home.homeDirectory}/.gitconfig";
      # Filled per variant by path-themes.sh.
      variant = null;
    }
  );

  envTemplate = pkgs.writeText "variant.env" (
    substituteFile ./nushell/path-themes/variant.env {
      extras = "${extras}";
      # Filled per variant by path-themes.sh.
      variant = null;
      out = null;
    }
  );

  pathThemes = pkgs.runCommand "dracula-path-themes" { } (
    substituteFile ./nushell/path-themes.sh {
      gitconfigTemplate = "${gitconfigTemplate}";
      envTemplate = "${envTemplate}";
      # The placeholders this script fills in the templates.
      variant = null;
      out = null;
    }
  );

  # A data file the setup scripts open, rather than a list spliced into
  # them: a bare `@themeDirs@` parses as an attribute, so every editor
  # reported the template as broken Nushell.
  themeDirs = pkgs.writeText "theme-dirs.nuon" (
    substituteFile ./nushell/theme-dirs.nuon {
      extras = "${extras}";
      pathThemes = "${pathThemes}";
    }
  );

  themeSetupFile = if isDarwin then ./nushell/theme-setup-darwin.nu else ./nushell/theme-setup.nu;

  themeSetup =
    if extras == null then "" else substituteFile themeSetupFile { themeDirs = "${themeDirs}"; };

  # Runs inside the login zsh, immediately before handing over to
  # Nushell, and repairs Ghostty's shell integration twice over.
  #
  # Ghostty prepends $GHOSTTY_SHELL_INTEGRATION_XDG_DIR to
  # XDG_DATA_DIRS, where Nushell looks for
  # nushell/vendor/autoload/ghostty.nu, but /etc/zshenv runs
  # nix-darwin's set-environment, which overwrites that variable rather
  # than appending. And autoloading only defines the module: Ghostty
  # activates it by appending `--execute 'use ghostty *'` to its
  # command, which `zsh -c` takes as positional parameters and drops.
  nuLoginInner = pkgs.writeShellScript "nu-login-inner" (
    builtins.readFile ./nushell/nu-login-inner.sh
  );

in
{
  # Launched from the terminal emulators through a login zsh, so it
  # inherits the environment zsh established and env.nu duplicates no
  # PATH. reedline uses Alt bindings, so the emulator has to send Option
  # as Alt/Meta.
  programs.nushell = {
    enable = true;

    # The theme setup is appended rather than substituted into
    # config.nu: a bare `@themeSetup@` between statements parses as an
    # attribute, so the template read as broken Nushell in every editor.
    extraConfig = lib.mkAfter (
      substituteFile ./nushell/config.nu {
        nuEntry = if isDarwin then "nu-login" else "$nu.current-exe";
        isDarwin = if isDarwin then "true" else "false";
        inherit opener;
      }
      + themeSetup
    );

    # Flattened into individual `$env.config.<path> = …` lines rather
    # than replacing the whole record, so nushell's other defaults are
    # left alone.
    settings = {
      show_banner = false;
    };

    shellAliases = {
      bdiff = "^batdiff";

      # Deliberately not bound over `grep` and `diff`: batgrep takes a
      # subset of ripgrep's flags and none of POSIX grep's, and shadowing
      # `grep` would retire the GREP_COLOR theme.
      bgrep = "^batgrep";
      bwatch = "^batwatch";

      # `^bat` is the external binary; without the caret this is a
      # recursive alias once `cat` is taken.
      cat = "^bat --paging=never";

      # The absolute path on darwin, because uutils' diff comes earlier
      # on PATH and rejects --color -- and DIFFCOLORS, which carries
      # this theme, is honoured only by Apple's diff.
      diff = if isDarwin then "^/usr/bin/diff --color=auto" else "^diff";

      # Through the XDG variables rather than literal paths, so a Linux
      # host needs no change. An alias expands at call time.
      dl = "cd $env.XDG_DOWNLOAD_DIR";
      dt = "cd $env.XDG_DESKTOP_DIR";
      dv = "cd ~/Developer";
      grep = "^grep --color=auto";
      jq = "^jaq";
      lesspipe = "^batpipe";

      # `watch` is deliberately not bound to batwatch: nushell has its
      # own `watch` builtin. `bwatch` above reaches it.
      rg = "^batgrep";
    };
  };

  # An out-of-store symlink, so editing the theme in the working copy
  # takes effect in the next shell. The cost is a parse error at startup
  # if that repo is missing.
  xdg.configFile."nushell/dracula-pro.nu" = lib.mkIf (extras != null) {
    source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/nushell/dracula-pro.nu";
  };

  home.packages = [
    pkgs.nu-lint
  ]
  ++ lib.optional isDarwin (
    pkgs.writeShellScriptBin "nu-login" (
      substituteFile ./nushell/nu-login.sh { inner = "${nuLoginInner}"; }
    )
  );
}
