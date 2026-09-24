{ config, lib, ... }:
let
  gitSettings = config.programs.git.settings;
  extras = config.my.theme.dracula.extras;
in
{
  # ui.editor is set in modules/home/commit-messages.nix, next to the
  # git hooks it mirrors.
  #
  # jj reads core.excludesFile from git's config, so ~/.gitignore_global
  # applies here too. It reads no .gitattributes at all, local or
  # global, which is why working-copy.eol-conversion stays at "none".
  programs.jujutsu = {
    enable = true;

    settings = {
      # jj has no fallback identity, so this is required rather than a
      # deviation. Taken from git so the two cannot disagree.
      user = {
        inherit (gitSettings.user) name email;
      };

      # `own` signs every commit you author whenever jj writes it, and
      # jj rewrites commits far more often than git does, so expect the
      # Touch ID prompt more often. `behavior = "drop"` plus
      # `git.sign-on-push` would sign once, at push time.
      #
      # Guarded like git.nix guards commit.gpgsign: the key lives in the
      # Secure Enclave, and `own` with no key is an error.
      signing = lib.mkIf (gitSettings.user ? signingkey) {
        behavior = "own";
        backend = "ssh";
        # jj takes the bare public key; `key::` is a git-ism for "a
        # literal, not a path", and jj's ssh backend needs no marker.
        key = lib.removePrefix "key::" gitSettings.user.signingkey;
        backends.ssh.allowed-signers = gitSettings.gpg.ssh.allowedSignersFile;
      };
    };
  };

  # Switched by APPEARANCE inside the file. jj loads conf.d/*.toml after
  # config.toml.
  xdg.configFile."jj/conf.d/dracula-pro.toml" = lib.mkIf (extras != null) {
    source = config.lib.file.mkOutOfStoreSymlink "${extras}/src/jj/dracula-pro.toml";
  };
}
