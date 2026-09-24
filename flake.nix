{
  description = "❄️ Declarative configuration with nix and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # FlakeHub is Determinate's documented release channel.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.brew-api.follows = "brew-api";
    };

    # Our own input, so `nix flake update brew-api` refreshes the cask
    # version pins.
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    # The private work layer, never pushed. Building without it means
    # `--override-input work path:./stubs/work`.
    work.url = "git+file:///Users/patrick/Developer/git.dutchanalytics.net/patrick.godschalk/ubiops-nix-config";
  };

  outputs =
    inputs:
    let
      apps = import ./apps.nix;

      # `pkgs.replaceVars` without the derivation, so reading a
      # substituted file stays a pure evaluation.
      inherit (import ./lib inputs.nixpkgs.lib) substituteFile;

      # A Python script under scripts/ with pyobjc, as a `nix run` tool.
      pythonTool =
        name: script:
        let
          pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
          python = pkgs.python3.withPackages (ps: [ ps.pyobjc-framework-Cocoa ]);
        in
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [ python ];
          text = substituteFile ./scripts/run-python.sh { script = "${script}"; };
        };
    in
    {
      # `nix run /etc/nix-darwin#sf-mono-terminal-nerd-font`
      #
      # Not a derivation, because the source is inside the OS and a Nix
      # build cannot read /System.
      packages.aarch64-darwin.sf-mono-terminal-nerd-font =
        let
          pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
          python = pkgs.python3.withPackages (ps: [ ps.fonttools ]);
        in
        pkgs.writeShellApplication {
          name = "sf-mono-terminal-nerd-font";
          runtimeInputs = [
            python
            pkgs.nerd-font-patcher
          ];
          text = substituteFile ./scripts/sf-mono-terminal-nerd-font.sh {
            src = "/System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SFMono-Terminal.ttf";
          };
        };

      # `nix run /etc/nix-darwin#terminal-profile -- --font …
      # --make-default`
      #
      # Terminal's profiles are a nested dictionary holding
      # NSKeyedArchiver font blobs, so they need read-modify-write plus
      # Cocoa archiving rather than `defaults`.
      packages.aarch64-darwin.terminal-profile = pythonTool "terminal-profile" ./scripts/terminal-profile.py;

      # `nix run /etc/nix-darwin#script-editor-theme -- --theme <path>`
      #
      # The theme is passed at run time rather than being a flake input,
      # so schemes can live in their own repository.
      packages.aarch64-darwin.script-editor-theme = pythonTool "script-editor-theme" ./scripts/script-editor-theme.py;

      # `nix run /etc/nix-darwin#script-editor-font`
      #
      # Script Editor's syntax colours are archived NSFont objects in
      # two per-language domains, unreachable with `defaults` and not
      # safely hand-editable, so Cocoa unarchives, swaps the family and
      # re-archives.
      #
      # A command rather than an activation step: it transforms existing
      # settings rather than declaring them, it needs Script Editor
      # closed, and it keeps pyobjc out of the system closure.
      packages.aarch64-darwin.script-editor-font = pythonTool "script-editor-font" ./scripts/script-editor-font.py;

      # Re-exported so the first activation, before
      # /run/current-system/sw/bin exists, runs the nix-darwin revision
      # flake.lock names rather than whatever `master` is.
      packages.aarch64-darwin.darwin-rebuild = inputs.nix-darwin.packages.aarch64-darwin.darwin-rebuild;

      # A throwaway configuration that exists to be evaluated: it is the
      # only way to catch a macOS assumption that has leaked out of
      # modules/home/darwin.
      #
      #   nix eval
      #   .#homeConfigurations."patrick@linux".activationPackage.drvPath
      #
      # `eval` rather than `build` forces the whole module system
      # without building a Linux binary. A real Linux host replaces
      # this, and the username, home directory and platform stop being
      # placeholders.
      homeConfigurations."patrick@linux" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          # A check rather than a machine, so every unfree package is
          # allowed rather than duplicating the host's `my.allowUnfree`
          # list, which is a nix-darwin option and out of reach here.
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit inputs apps substituteFile;
          isDarwin = false;
        };
        modules = [
          ./home/patrick
          inputs.work.homeModules.default
          {
            # Home Manager needs a bit of information about you and the
            # paths it should manage.
            home = {
              username = "patrick";
              homeDirectory = "/home/patrick";
            };
          }
        ];
      };

      # The attribute name must equal `scutil --get LocalHostName`, or
      # `darwin-rebuild switch` needs `--flake .#name`.
      darwinConfigurations.Patricks-MacBook-Pro = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs apps substituteFile; };
        modules = [
          inputs.determinate.darwinModules.default
          inputs.brew-nix.darwinModules.default
          inputs.home-manager.darwinModules.home-manager
          ./hosts/Patricks-MacBook-Pro
        ];
      };

      # Run against the work layer's stub as well, which the check
      # cannot do by itself:
      #   nix flake check --override-input work path:./stubs/work
      checks.aarch64-darwin = {
        darwin-system = inputs.self.darwinConfigurations.Patricks-MacBook-Pro.system;

        # An aarch64-darwin check even though what it checks is
        # x86_64-linux: under `checks.x86_64-linux` a plain
        # `nix flake check` skips it as an incompatible system, and
        # `--all-systems` tries to build it and dies on a platform
        # mismatch.
        #
        # Forcing `drvPath` runs the entire module system, which is the
        # point. The string's context is then dropped, or the path
        # carries its derivation along as a build input and Nix tries
        # to build Linux again.
        home-linux =
          let
            pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
            drvPath = inputs.self.homeConfigurations."patrick@linux".activationPackage.drvPath;
          in
          pkgs.writeText "home-linux-evaluates" (builtins.unsafeDiscardStringContext drvPath);
      };
    };
}
