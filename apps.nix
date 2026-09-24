# Data only: no `pkgs`, no `lib`, no module arguments at the top level.
{
  # Ids come from `mas search "<name>"` on the machine. The activation
  # entry that installs them can only install what is already in the
  # Purchased list.
  mas = {
    # Apple Creator Studio
    "Compressor: Encode Media" = 6746516157;
    "Final Cut Pro: Create Video" = 1631624924;
    "Keynote: Design Presentations" = 361285480;
    "Logic Pro: Make Music" = 1615087040;
    "Pixelmator Pro: Edit Images" = 6746662575;
    "Motion: Animate Effects" = 6746637149;
    "MainStage: Perform Live" = 6746637089;
    "Numbers: Make Spreadsheets" = 361304891;
    "Pages: Create Documents" = 361309726;

    # Apple Developer
    "Apple Configurator" = 1037126344;
    "Apple Developer" = 640199958;
    "Swift Playground" = 1496833156;
    Transporter = 1450874784;
    Xcode = 497799835;

    # Apple iLife
    GarageBand = 682658836;
    iMovie = 408981434;

    # Third party
    "Amazon Prime Video" = 545519333;
    "Craft: Notes, Documents, AI" = 1487937127;
    "Kagi News" = 6748314243;
    "Kagi for Safari" = 1622835804;
    "Nautik for Kubernetes" = 1672838783;
    Photomator = 1444636541;
    "ReadKit - Reading Hub" = 1615798039;
    "Slack for Desktop" = 803453959;
    SnippetsLab = 1006087419;
    Tailscale = 1475387142;
    Telegram = 747648890;
    "UTM Virtual Machines" = 1538878817;
    "WhatsApp Messenger" = 310633997;
    "Wipr 2" = 1662217862;

  };

  # Homebrew cask tokens, reached through brew-nix as
  # `pkgs.brewCasks.<token>`, for apps the Mac App Store does not carry
  # and nixpkgs lacks or lags behind on. Casks carry no licence metadata,
  # so they are not subject to my.allowUnfree.
  #
  # A `sha256 :no_check` cask cannot work: brew-nix ships the
  # placeholder hash and the build fails. A component pkg does work,
  # since brew-nix unpacks it and rewraps its bare `Contents/` as an
  # .app; a distribution pkg that runs installer scripts does not.
  casks = [
    "betterdisplay"
    "claude" # the Claude desktop app, not claude-code
    "finbar"
    "linear"
    "orbstack"
    "rapidapi"
    "rectangle-pro"
  ];

  # A function of `pkgs`, so attribute names are checked at evaluation
  # time.
  packages =
    pkgs: with pkgs; [
      # CLI
      asciinema # terminal recorder
      doggo # DNS client
      hyperfine # benchmarking
      mkcert # local dev CA
      ouch # archive (de)compressor
      stern # multi-pod Kubernetes log tailing
      vagrant
      xh # HTTP client
    ];

  darwinPackages =
    pkgs: with pkgs; [
      # `pkgs.ghostty` is Linux-only; -bin ships the macOS .app
      ghostty-bin
      mas # needed by the Mac App Store activation entry
      zed-editor # GUI

      # The patched SF Mono is in modules/home/darwin/fonts.nix.
      inter
      open-sans
      raleway
    ];
}
