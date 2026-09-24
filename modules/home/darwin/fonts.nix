{ pkgs, ... }:
let
  # SF Mono has no ligature data at all, so ligatures cannot be enabled
  # -- they have to come from another font, and these builds graft in
  # FiraCode's along with the Nerd Fonts glyphs.
  #
  # Fetched rather than vendored, because this redistributes a modified
  # Apple font, which is also why SF Mono is not in nixpkgs.
  sf-mono-liga-nerd = pkgs.stdenvNoCC.mkDerivation {
    pname = "sf-mono-liga-nerd-font";
    # @VERSION
    # https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized/commits/main
    # Upstream tags no releases, so the pin is the revision below and
    # this string carries that commit's date. Move both together.
    version = "0-unstable-2023-07-01";

    src = pkgs.fetchFromGitHub {
      owner = "shaunsingh";
      repo = "SFMono-Nerd-Font-Ligaturized";
      rev = "dc5a3e6fcc2e16ad476b7be3c3c17c2273b260ea";
      hash = "sha256-AYjKrVLISsJWXN6Cj74wXmbJtREkFDYOCRw1t2nVH2w=";
    };

    installPhase = ''
      runHook preInstall
      install -Dm444 -t "$out/share/fonts/opentype" *.otf
      runHook postInstall
    '';

    meta = {
      description = "SF Mono patched with Nerd Fonts glyphs and FiraCode ligatures";
      homepage = "https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized";
      platforms = pkgs.lib.platforms.all;
    };
  };
in
{
  # home-manager collects fonts from home.packages and links them into
  # ~/Library/Fonts on darwin.
  home.packages = [ sf-mono-liga-nerd ];
}
