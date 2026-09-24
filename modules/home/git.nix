{
  config,
  lib,
  pkgs,
  ...
}:
let
  extras = config.my.theme.dracula.extras;

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # No WSL host exists in this flake yet, so the selections gated on
  # this are never included; they stay as a record of intent. WSL cannot
  # be detected from Nix at evaluation time, so a host has to declare
  # it, and this is the line to change.
  isWSL = false;

  # Pinned to a commit rather than a branch: an ignore or attributes
  # rule changing under a rebuild is how a file mysteriously stops being
  # committed, or starts being treated as binary.
  gitignoreUpstream = pkgs.fetchFromGitHub {
    owner = "github";
    repo = "gitignore";
    # @VERSION https://github.com/github/gitignore/commits/main
    rev = "356fd7baab4c05e092194a41f64dbd5afc8817e4";
    hash = "sha256-Nm+gwWE8yZye19qffYwk95Q0A9zMa1hdP7p5J5bBuUI=";
  };

  gitattributesUpstream = pkgs.fetchFromGitHub {
    owner = "gitattributes";
    repo = "gitattributes";
    # @VERSION
    # https://github.com/gitattributes/gitattributes/commits/master
    rev = "2c20a14833a5ab196c7fc3effcc72ef4e895f4d4";
    hash = "sha256-jTuMG6/YF9phJXMN/CbXdNZCER+9IIoXIayiT8YVm58=";
  };

  # `when` defaults to true.
  concatGlobals =
    upstream: ext: entries:
    let
      section =
        f: "# --- ${f.name}.${ext} ---\n" + builtins.readFile "${upstream}/Global/${f.name}.${ext}";
    in
    lib.concatStringsSep "\n" (map section (builtins.filter (f: f.when or true) entries));

  # A literal rather than a path into Secretive's container, which is
  # TCC-protected: the grant follows the responsible app, so every app
  # that runs git needs its own, and a missing one fails every commit
  # from that app with an error about keys rather than permissions.
  # git's `key::` form reads no file at all.
  #
  # Rotating the key means editing this string and nothing else --
  # allowed_signers below is generated from it.
  signingPublicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHcdZdHJb/yrDtBpVxG9z1tqu4JmAb+TRm3s2jQXj96cB2sOUjpMLiFaa15fh0EG8j3CZZxejTkMWyEfD0nRb9Q=";
in
{
  home.packages = with pkgs; [
    delta
    difftastic
  ];

  programs.git = {
    enable = true;

    # `git lfs install` declaratively. Running it by hand would try to
    # write the same keys into a read-only store file and fail.
    lfs.enable = true;

    settings = {

      # git log and git show default to --no-ext-diff with no setting to
      # change it, so reaching difftastic there takes an alias.
      alias = {
        dlog = "log --ext-diff --patch";
        dshow = "show --ext-diff";
        # `diff --no-ext-diff`, not `--no-ext-diff diff`: it is a diff
        # option, and git rejects it before the subcommand with
        # "unknown option".
        udiff = "diff --no-ext-diff";
      };
      branch.sort = "-committerdate";

      column.ui = "auto";

      commit.gpgsign = isDarwin;

      # Puts the staged diff in the editor below the scissors line.
      # modules/home/commit-messages.nix has to cut at that line before
      # deciding whether a message already exists, because the diff is
      # not comment-prefixed.
      commit.verbose = true;

      core = {
        excludesfile = "${config.xdg.configHome}/git/ignore";
        attributesfile = "${config.xdg.configHome}/git/attributes";

        # A per-repository FSMonitor daemon over FSEvents, and the
        # cached untracked-file scan that is the other half of it.
        fsmonitor = true;
        untrackedCache = true;
        # Safe to combine with the external diff below: delta renders
        # anything diff-shaped and passes everything else through, and
        # difftastic's side-by-side output is not diff-shaped.
        pager = "delta";
      };

      delta = {
        navigate = true;
        hyperlinks = true;
      };

      # This changes what plain `git diff` prints, so anything parsing
      # that output needs `git diff --no-ext-diff`, aliased as `udiff`
      # above. Porcelain that renders no diff body is unaffected.
      diff = {
        external = "difft";
        tool = "difftastic";

        # These reach the internal differ, so they apply wherever
        # difftastic does not: `git add -p`, the `udiff` alias, and
        # `git log`/`show` without --ext-diff. mnemonicPrefix replaces
        # a/ and b/ with i/, w/ and c/ for index, working tree and
        # commit.
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      difftool = {
        prompt = false;
        "difftastic".cmd = ''difft "$LOCAL" "$REMOTE"'';
      };

      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };

      # A different Secure Enclave key from the authentication one in
      # modules/home/darwin/ssh.nix.
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      };

      # Guesses at a mistyped subcommand but asks first; the other
      # values are deciseconds, which run the guess after a delay.
      help.autocorrect = "prompt";

      init.defaultBranch = "main";

      # `git add -p` needs a real unified diff to slice into hunks, so
      # it cannot use the external diff.
      interactive.diffFilter = "delta --color-only";

      # Shows the merge base as well as both sides in a conflict.
      merge.conflictstyle = "zdiff3";

      pull.rebase = true;

      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
        # Moves stacked branches along with the rebase instead of
        # leaving them on the pre-rebase commits.
        updateRefs = true;
      };

      rerere = {
        # Remembers how a conflict was resolved and replays it next time
        # the same one appears.
        enabled = true;
        autoupdate = true;
      };
      tag.gpgsign = isDarwin;
      tag.sort = "version:refname";
      user = {
        name = "Patrick Godschalk";
        email = "patrick@kernelpanics.nl";
      }
      # Secretive's Secure Enclave exists only on macOS.
      // lib.optionalAttrs isDarwin { signingkey = "key::${signingPublicKey}"; };
    };
  };

  # Who may sign, for `git log --show-signature`. At the XDG path,
  # unlike git's own config, because this file is only ever found
  # through the explicit setting above.
  #
  # The ML-DSA key is commented out because OpenSSH has no ssh-mldsa-87
  # support: left active it makes ssh-keygen print
  # "allowed_signers:1: invalid key" twice per verification, which would
  # hide a real warning. Verification still succeeds either way.
  xdg.configFile."git/allowed_signers".text = ''
    patrick@kernelpanics.nl ${signingPublicKey}
    #patrick@kernelpanics.nl ssh-mldsa-87 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
  '';

  # github/gitignore's Global set verbatim, with no local section:
  # upstream's Agents.gitignore already carries CLAUDE.local.md.
  #
  # Note Images and Archives ignore whole extensions, so in a repository
  # with image assets `git add .` skips them silently.
  xdg.configFile."git/ignore".text = concatGlobals gitignoreUpstream "gitignore" [
    { name = "Agents"; }
    { name = "Ansible"; }
    { name = "Archives"; }
    { name = "Backup"; }
    { name = "Diff"; }
    { name = "Images"; }
    {
      name = "Linux";
      when = !isDarwin;
    }
    { name = "Patch"; }
    { name = "Redis"; }
    { name = "Tags"; }
    { name = "Vagrant"; }
    { name = "Vim"; }
    { name = "VirtualEnv"; }
    {
      name = "VisualStudioCode";
      when = isWSL;
    }
    {
      name = "Windows";
      when = isWSL;
    }
    {
      name = "Xcode";
      when = isDarwin;
    }
    { name = "Zed"; }
    {
      name = "macOS";
      when = isDarwin;
    }
    { name = "mise"; }
  ];

  # core.attributesfile names this explicitly rather than relying on
  # git's XDG default, so it is found by a process that never sees
  # XDG_CONFIG_HOME, such as a GUI-launched git.
  xdg.configFile."git/attributes".text = concatGlobals gitattributesUpstream "gitattributes" [
    { name = "DevContainer"; }
    {
      name = "VisualStudio";
      when = isWSL;
    }
    {
      name = "VisualStudioCode";
      when = isWSL;
    }
  ];

  # ~/.gitconfig rather than $XDG_CONFIG_HOME/git/config: git reads
  # ~/.gitconfig when it exists and only falls back to the XDG path, so
  # any tool or GUI that writes the former silently takes over and the
  # declared config stops applying with no error.
  xdg.configFile."git/config".enable = false;
  home.file.".gitconfig".text =
    config.xdg.configFile."git/config".text
    + lib.optionalString (extras != null) ''

      # Both themes at once, because delta reads its configuration
      # through libgit2, which ignores GIT_CONFIG_GLOBAL -- silently --
      # so the per-appearance shim never reaches it. DELTA_FEATURES
      # picks one. `features` below is the fallback for a git run
      # without that variable.
      [include]
      	path = ${extras}/src/delta/pro.gitconfig
      [include]
      	path = ${extras}/src/delta/alucard.gitconfig
      [delta]
      	features = pro-dracula
    '';
}
