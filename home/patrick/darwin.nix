{
  apps,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/home/darwin/agentastic.nix
    ../../modules/home/darwin/amie.nix
    ../../modules/home/darwin/appearance.nix
    ../../modules/home/darwin/betterdisplay.nix
    ../../modules/home/darwin/c-cpp.nix
    ../../modules/home/darwin/claude-desktop.nix
    ../../modules/home/darwin/finbar.nix
    ../../modules/home/darwin/fonts.nix
    ../../modules/home/darwin/ghostty.nix
    ../../modules/home/darwin/mas.nix
    ../../modules/home/darwin/mcp.nix
    ../../modules/home/darwin/metal.nix
    ../../modules/home/darwin/orbstack.nix
    ../../modules/home/darwin/python-lsps.nix
    ../../modules/home/darwin/rectangle-pro.nix
    ../../modules/home/darwin/setapp.nix
    ../../modules/home/darwin/snippetslab.nix
    ../../modules/home/darwin/ssh.nix
    ../../modules/home/darwin/swift.nix
    ../../modules/home/darwin/tableplus.nix
    ../../modules/home/darwin/update.nix
    ../../modules/home/darwin/wallpaper.nix
    ../../modules/home/darwin/xcode.nix
    ../../modules/home/darwin/zed.nix
  ];

  # Portable modules guard their theme symlinks on these, so a host
  # without the checkouts gets untinted tools.
  my.theme.dracula = {
    pro = "${config.home.homeDirectory}/Developer/github.com/dracula-pro/dracula-pro";
    extras = "${config.home.homeDirectory}/Developer/github.com/pgodschalk/dracula-pro-extras";
  };

  # Apple's file-system hierarchy instead of ~/.config, ~/.local and
  # ~/.cache. macOS has no separate state directory, so config, data and
  # state all map to Application Support, and the occasional tool trips
  # over the space in that name.
  xdg = {
    # ~/Library/Scripts is the closest macOS has to a convention for
    # user-supplied executables, where XDG_BIN_HOME would default to
    # ~/.local/bin. Nothing is added to PATH by it: binHome is a
    # location rather than a search path.
    binHome = "${config.home.homeDirectory}/Library/Scripts";
    cacheHome = "${config.home.homeDirectory}/Library/Caches";
    configHome = "${config.home.homeDirectory}/Library/Application Support";
    dataHome = "${config.home.homeDirectory}/Library/Application Support";
    enable = true;
    stateHome = "${config.home.homeDirectory}/Library/Application Support";
  };

  # `xdg.userDirs` is Linux-only -- it writes a user-dirs.dirs file
  # macOS has no reader for -- so these are exported directly, at the
  # real Finder folders rather than a parallel set.
  home.sessionVariables = {
    XDG_DESKTOP_DIR = "${config.home.homeDirectory}/Desktop";
    XDG_DOWNLOAD_DIR = "${config.home.homeDirectory}/Downloads";
    XDG_PUBLICSHARE_DIR = "${config.home.homeDirectory}/Public";
    XDG_MUSIC_DIR = "${config.home.homeDirectory}/Music";
    XDG_PICTURES_DIR = "${config.home.homeDirectory}/Pictures";
    XDG_VIDEOS_DIR = "${config.home.homeDirectory}/Movies";
  };

  # Suppresses login(1)'s "Last login: …" banner. A dotfile in $HOME on
  # the same grounds as ~/.ssh: login(1) hardcodes the name and looks
  # for it in the home directory only.
  home.file.".hushlogin".text = "";

  #  Packages that should be installed to the user profile.
  home.packages =
    apps.darwinPackages pkgs
    # Casks are unpacked into the store and cannot self-update, so new
    # versions arrive with `nix flake update brew-api` and in-app
    # auto-update is turned off for each.
    #
    # `lowPrio` because a cask that also ships a command-line binary
    # must never win a collision against a package installed
    # deliberately: the Claude desktop app ships `bin/claude`, which
    # collides with claude-code's and otherwise fails the profile build.
    ++ map (token: lib.lowPrio pkgs.brewCasks.${token}) apps.casks;
}
