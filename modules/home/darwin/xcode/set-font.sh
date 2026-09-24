# shellcheck shell=bash

# The preference is `data` holding JSON, which
# CustomUserPreferences cannot express -- Nix has no bytes literal --
# so it goes in as a hex string through `defaults write -data`.
plist="$HOME/Library/Preferences/com.apple.dt.Xcode.plist"
want=@wantB64@
have=$(/usr/bin/plutil -extract DVTWorkspaceGlobalFontRecipe raw -o - \
  "$plist" 2>/dev/null || true)

if [ "$have" != "$want" ]; then
  run /usr/bin/defaults write com.apple.dt.Xcode \
    DVTWorkspaceGlobalFontRecipe -data @recipeHex@
fi
