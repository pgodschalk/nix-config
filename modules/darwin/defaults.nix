{ config, ... }:
{
  system.defaults = {

    # Written as root, and the attribute name reaches `defaults write`
    # verbatim: a bare bundle id would resolve to root's own preferences
    # and silently do nothing. Full paths only.
    CustomSystemPreferences = {
      # Full auto-update can install a new major macOS before nix-darwin
      # supports it.
      "/Library/Preferences/com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        AutomaticDownload = true;
        ConfigDataInstall = true;
        CriticalUpdateInstall = true;
      };

      # Keeps Mac App Store apps current; nothing else does.
      "/Library/Preferences/com.apple.commerce".AutoUpdate = true;
    };

    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleLanguages = [
          "en-US"
          "nl-NL"
        ];
        AppleLocale = "en_US@rg=nlzzzz";

        # ISO 8601 short dates. The keys are ICU format widths: 1 short,
        # 2 medium, 3 long, 4 full. The longer widths spell the month
        # out and are left alone.
        AppleICUDateFormatStrings = {
          "1" = "y-MM-dd";
        };
      };

      "com.apple.AppStore" = {
        InAppReviewEnabled = false;
      };

      "com.apple.AppleMultitouchMouse" = {
        MouseTwoFingerHorizSwipeGesture = 1;
      };

      # The Dutch keyboard layout. The login-window layout is the
      # system-level copy of this domain and is left alone.
      "com.apple.HIToolbox" = {
        AppleEnabledInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 26;
            "KeyboardLayout Name" = "Dutch";
          }
          {
            "Bundle ID" = "com.apple.CharacterPaletteIM";
            InputSourceKind = "Non Keyboard Input Method";
          }
          {
            "Bundle ID" = "com.apple.PressAndHold";
            InputSourceKind = "Non Keyboard Input Method";
          }
        ];
        AppleSelectedInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 26;
            "KeyboardLayout Name" = "Dutch";
          }
          {
            "Bundle ID" = "com.apple.PressAndHold";
            InputSourceKind = "Non Keyboard Input Method";
          }
        ];
      };

      # Audio quality 15 is Lossless.
      "com.apple.Music" = {
        downloadDolbyAtmos = true;
        losslessEnabled = true;
        preferredStreamPlaybackAudioQuality = 15;
        preferredDownloadAudioQuality = 15;
        automaticallyDownloadArtwork = true;
      };

      # optimizedDownloadQuality 40 is "High Quality (up to 1080p)".
      "com.apple.TV" = {
        optimizedDownloadQuality = 40;
        downloadDolbyAtmos = true;
      };

      # Terminal.app rewrites its whole preference file when it quits,
      # so a switch made while it runs can be clobbered.
      "com.apple.Terminal" = {
        SecureKeyboardEntry = true;
      };

      # Siri's voice. This domain is iCloud-synced, so a rebuild may
      # restore it before activation runs, and the voice asset itself
      # is a download the preference does not fetch.
      "com.apple.assistant.backedup" = {
        "Output Voice" = {
          Custom = 1;
          Footprint = 2;
          Gender = 2;
          Language = "en-GB";
          Name = "martha";
        };
      };

      # 2 = opted out.
      "com.apple.assistant.support" = {
        # "Improve Siri & Dictation".
        "Siri Data Sharing Opt-In Status" = 2;

        # Spotlight -> "Help Apple Improve Search", which lives here
        # rather than in com.apple.Spotlight.
        "Search Queries Data Sharing Status" = 2;
      };

      # Locks the Dock's size at whatever the macOS default is, since
      # `tilesize` stays undeclared. nix-darwin restarts the Dock only
      # for its typed options, so this needs a `killall Dock`.
      "com.apple.dock" = {
        size-immutable = true;
      };

      "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
        MouseButtonMode = "TwoButton";
        # "Swipe between pages" with two fingers.
        MouseTwoFingerHorizSwipeGesture = 1;
      };

      # Desktop -> Use Stacks, grouped by Kind.
      #
      # IconViewSettings is spelled out in full because a
      # CustomUserPreferences write replaces a top-level key's whole
      # value: declaring arrangeBy alone would drop icon size, grid
      # spacing and the rest. A key macOS adds later is dropped the same
      # way, so re-read the live value after a major upgrade.
      #
      # Activation runs no `killall`, so the desktop redraws at the next
      # login or after `killall Finder`.
      "com.apple.finder" = {
        FXPreferredGroupBy = "Kind";
        DesktopViewSettings = {
          GroupBy = "Kind";
          IconViewSettings = {
            arrangeBy = "dateAdded";
            backgroundColorRed = 1.0;
            backgroundColorGreen = 1.0;
            backgroundColorBlue = 1.0;
            backgroundType = 0;
            gridOffsetX = 0.0;
            gridOffsetY = 0.0;
            gridSpacing = 54.0;
            iconSize = 64.0;
            textSize = 12.0;
            labelOnBottom = true;
            showIconPreview = true;
            showItemInfo = false;
            viewOptionsVersion = 1;
          };
        };
      };

      # Note the spaces in the key name.
      "com.apple.iCal" = {
        "Show Week Numbers" = true;
      };

      "com.apple.screencapture" = {
        captureHDR = true;
      };

      "com.apple.speech.recognition.AppleSpeechRecognition.prefs" = {
        DictationIMMasterDictationEnabled = true;

        # Adding a language here downloads an offline recognition model.
        VisibleNetworkSRLocaleIdentifiers = {
          en_US = 1;
          nl_NL = 1;
        };
      };

      # Points the wallpaper engine at the catalog
      # modules/home/wallpaper.nix generates. ForceLocal stops the
      # engine preferring Apple's remote manifest over it.
      "com.apple.wallpaper.aerial" = {
        AerialManifestLocalPathOverride = "${config.system.primaryUserHome}/Library/Application Support/com.apple.wallpaper/aerials/custom/entries.json";
        AerialManifestForceLocal = true;
      };
    };
    NSGlobalDomain = {
      AppleInterfaceStyleSwitchesAutomatically = true;

      # Both are slider positions on macOS's own scales, and lower is
      # faster, which reads backwards:
      #   KeyRepeat        120, 90, 60, 30, 12, 6, 2
      #   InitialKeyRepeat 120, 94, 68, 35, 25, 15
      KeyRepeat = 2;
      InitialKeyRepeat = 15;

      # Correct spelling automatically
      NSAutomaticSpellingCorrectionEnabled = false;
      # Capitalize words automatically
      NSAutomaticCapitalizationEnabled = false;
      # Add period with double space
      NSAutomaticPeriodSubstitutionEnabled = false;
      # "Use smart quotes and dashes" is one switch over two keys, and
      # writing one alone leaves the checkbox half-on.
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    finder = {
      # Permanently erase items after 30 days in the Trash.
      FXRemoveOldTrashItems = true;

      NewWindowTarget = "Home";

      # Governs only folders Finder has no saved view for; an opened
      # folder keeps what its .DS_Store records.
      FXPreferredViewStyle = "clmv";
    };

    # The typed option writes com.apple.AppleMultitouchMouse and
    # com.apple.driver.AppleMultitouchMouse.mouse, which does not exist
    # here -- the real Bluetooth domain is
    # com.apple.driver.AppleBluetoothMultitouch.mouse and is set
    # explicitly above.
    magicmouse.MouseButtonMode = "TwoButton";
  };
}
