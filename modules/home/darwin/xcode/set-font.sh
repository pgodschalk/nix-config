# shellcheck shell=bash

# The preference is `data` holding JSON, which
# CustomUserPreferences cannot express -- Nix has no bytes literal --
# so it goes in as a hex string through `defaults write -data`, and is
# compared as base64, the form `plutil -extract raw` prints.
#
# `od -An` drops the offset column, `-v` stops it collapsing repeated
# bytes into a `*` line.
plist="$HOME/Library/Preferences/com.apple.dt.Xcode.plist"
recipe=@recipe@
want=$(@coreutils@/bin/base64 -w0 <"$recipe")
have=$(/usr/bin/plutil -extract DVTWorkspaceGlobalFontRecipe raw -o - \
  "$plist" 2>/dev/null || true)

if [ "$have" != "$want" ]; then
  recipeHex=$(@coreutils@/bin/od -An -tx1 -v <"$recipe" \
    | @coreutils@/bin/tr -d ' \n')
  run /usr/bin/defaults write com.apple.dt.Xcode \
    DVTWorkspaceGlobalFontRecipe -data "$recipeHex"
fi
