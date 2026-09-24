{
  inputs,
  apps,
  substituteFile,
  config,
  lib,
  ...
}:
{
  imports = [
    ../../modules/darwin/analytics.nix
    ../../modules/darwin/defaults.nix
    ../../modules/darwin/identity.nix
    ../../modules/darwin/launchd-env.nix
    ../../modules/darwin/security.nix
    ../../modules/darwin/shell.nix
    ../../modules/darwin/xcode.nix
    # One import for both layers: it adds the work repository's
    # home-manager modules through home-manager.sharedModules.
    inputs.work.darwinModules.default
  ];

  # `lib.getName` values rather than attribute names, and a list rather
  # than the predicate itself, because a predicate is a function and
  # cannot be defined twice.
  options.my.allowUnfree = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Names of unfree packages to allow.";
  };

  config = {
    my.allowUnfree = [
      "1password-cli"
      "claude-code"
      "discord"
      "terraform"
      "vagrant"
    ];

    nixpkgs = {
      hostPlatform = "aarch64-darwin";

      # With `useGlobalPkgs` home-manager reuses this `pkgs`, so the
      # predicate belongs here rather than in the HM config.
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.my.allowUnfree;
    };

    # Current nix-darwin default (`system.maxStateVersion`).
    # @VERSION
    # https://github.com/nix-darwin/nix-darwin/blob/master/CHANGELOG
    system.stateVersion = 7;

    # Required by every option that writes per-user state.
    system.primaryUser = "patrick";
    users.users.patrick = {
      name = "patrick";
      home = "/Users/patrick";
    };

    # Determinate owns Nix. This forces `nix.enable = false`, so none
    # of `nix.package`, `nix.settings`, `nix.gc`, `nix.optimise` or
    # `nix.linux-builder` may be set.
    determinateNix = {
      enable = true;
      # In the nix.conf reference's order, which is alphabetical.
      customSettings = {
        # The defaults multiply out: `cores = 0` means every core per
        # derivation, so eight concurrent builds each claim eight cores.
        # The product here is 8, so the machine stays usable, and one
        # large derivation gets two cores rather than eight. Tune the
        # product rather than one factor.
        cores = 2;
        max-jobs = 4;

        # Off by default on macOS, and third-party sources here run
        # their own scripts at build time.
        sandbox = true;

        # Drops ~/.nix-profile, ~/.nix-defexpr and ~/.nix-channels in
        # favour of the XDG paths.
        use-xdg-base-directories = true;
      };
    };

    # Exposes casks from the Homebrew API as `pkgs.brewCasks.<token>`.
    brew-nix.enable = true;

    home-manager = {
      useGlobalPkgs = true;
      # Installs user packages into /etc/profiles/per-user/patrick.
      useUserPackages = true;
      # Moves a file home-manager does not own aside rather than
      # aborting the switch, which a tool that writes its own config on
      # first run otherwise causes. A second collision on the same path
      # fails again, since the backup would be overwritten; clear the
      # .hm-backup once the new file is confirmed good.
      backupFileExtension = "hm-backup";
      # A literal rather than derived from `pkgs`, because
      # home/patrick/default.nix needs it in `imports`, where a module
      # argument taken from `pkgs` cannot be used.
      extraSpecialArgs = {
        inherit inputs apps substituteFile;
        isDarwin = true;
      };
      users.patrick = import ../../home/patrick;
    };
  };
}
